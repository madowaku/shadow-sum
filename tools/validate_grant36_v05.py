"""Independent validator for the GRANT36 v0.5 board-shape campaign and pool."""
from __future__ import annotations

from collections import Counter, defaultdict
import copy
import itertools
import json
from pathlib import Path
import re
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from validate_grant20_v03 import (  # independent standard-library ray/state reference
    category, code, legal_positions, light_states, object_states, shadow,
    shutter_states, cell,
)

CAMPAIGN = ROOT / "data/grant36_v0_5.json"
V04 = ROOT / "data/grant36_v0_4_draft.json"
POOL = ROOT / "generated/grant36_v0_5_candidates.json"
RANKED = ROOT / "generated/grant36_v0_5_ranked.csv"
REPORT = ROOT / "docs/GRANT36_V0_5_REPORT.md"
FIXTURES = ROOT / "data/grant36_board_shape_fixtures_v0_5.json"
KINDS = ("normal", "tall", "plate_v", "plate_h")
CELLS = tuple(code(i) for i in range(25))
REPLACEMENTS = ("GR24", "GR25", "GR28", "GR29", "GR32", "GR34", "GR35", "GR36")
KEEP = ("GR21", "GR22", "GR23", "GR26", "GR27", "GR30", "GR31", "GR33")

def require(condition, message):
    if not condition:
        raise ValueError(message)

def pack(values):
    return sum(int(value) << (4 * i) for i, value in enumerate(values))

def lane_mask(indices):
    return sum(15 << (4 * i) for i in indices)

def normalized_solution(stage):
    types = stage.get("solution_post_types", {})
    result = []
    for name in stage["solution"]:
        kind = types.get(name)
        if kind is None:
            kind = "tall" if stage.get("solution_tall", []) and name in stage["solution_tall"] else (
                "tall" if stage.get("tall", False) else "normal")
        result.append((cell(name), kind))
    return tuple(sorted(result))

def inventory_of_objects(objects):
    counts = Counter(category(kind) for _, kind in objects)
    return {kind: counts[kind] for kind in ("normal", "tall", "plate")}

def inventory_declared(stage):
    return {
        "normal": int(stage.get("normal_posts", 0)),
        "tall": int(stage.get("tall_posts", 0)),
        "plate": int(stage.get("plate_posts", 0)),
    }

def typed_inventory_exact(stage):
    objects = normalized_solution(stage)
    declared = inventory_declared(stage)
    return (sum(declared.values()) == int(stage["posts"])
            and inventory_of_objects(objects) == declared
            and len({pos for pos, _ in objects}) == len(objects)
            and all(pos in set(legal_positions(stage)) for pos, _ in objects))

def target_projection(stage):
    fog = set(stage.get("fog_cells", []))
    visible = [i for i, name in enumerate(CELLS) if name not in fog]
    result = []
    for observation in stage["observations"]:
        values = [int(observation.get("target", {}).get(name, 0)) for name in CELLS]
        result.append((visible, values))
    return result

def model_key(stage):
    observations = tuple(tuple(obs.get("active_lights", [])) for obs in stage["observations"])
    return (
        int(stage["posts"]), tuple(inventory_declared(stage).items()),
        tuple(legal_positions(stage)), tuple(light_states(stage)), tuple(shutter_states(stage)),
        bool(stage.get("free_light_selection")), bool(stage.get("light_puzzle")),
        bool(stage.get("tall")), bool(stage.get("rotatable_plate")),
        tuple(stage.get("fixed_tall_posts", [])), tuple(stage.get("fixed_shutters", [])),
        observations, tuple(stage.get("fixed_posts", [])),
        tuple(sorted(stage.get("fixed_post_types", {}).items())),
    )

TABLE_CACHE = {}

def atomic_table(lights, shutter):
    key = (tuple(lights), shutter)
    if key not in TABLE_CACHE:
        TABLE_CACHE[key] = {
            (pos, kind): pack(shadow(((pos, kind),), lights, shutter))
            for pos in range(25) for kind in KINDS
        }
    return TABLE_CACHE[key]

def enumerate_group(stages, require_unique=True):
    """Enumerate a shared physical state space once for every target in the group."""
    base = stages[0]
    configs = list(itertools.product(light_states(base), shutter_states(base)))
    tables = [atomic_table(lights, shutter) for lights, shutter in configs]
    projections = [target_projection(stage) for stage in stages]
    lane_masks = [[lane_mask(visible) for visible, _ in observations] for observations in projections]
    targets = [[pack(values) for _, values in observations] for observations in projections]
    counts = [0] * len(stages)
    worlds = 0
    for objects in object_states(base):
        for config_index, (lights, shutter) in enumerate(configs):
            table = tables[config_index]
            encoded = sum(table[obj] for obj in objects)
            worlds += 1
            for stage_index, stage in enumerate(stages):
                matched = True
                for obs_index, observation in enumerate(stage["observations"]):
                    live_lights = lights if stage.get("free_light_selection") or stage.get("light_puzzle") else tuple(observation["active_lights"])
                    obs_table = table if live_lights == tuple(lights) else atomic_table(live_lights, shutter)
                    obs_encoded = encoded if obs_table is table else sum(obs_table[obj] for obj in objects)
                    if (obs_encoded & lane_masks[stage_index][obs_index]) != (targets[stage_index][obs_index] & lane_masks[stage_index][obs_index]):
                        matched = False
                        break
                if matched:
                    counts[stage_index] += 1
    for stage_index, stage in enumerate(stages):
        expected = int(stage.get("expected_states", 0))
        require(not expected or worlds == expected,
                f"{stage['id']}: search space {worlds}, expected {expected}")
        if require_unique:
            require(counts[stage_index] == 1,
                    f"{stage['id']}: expected exactly one survivor, got {counts[stage_index]}")
    return worlds, counts

def enumerate_stages(stages, require_unique=True):
    groups = defaultdict(list)
    for stage in stages:
        groups[model_key(stage)].append(stage)
    counts_by_id, states_by_id = {}, {}
    for group in groups.values():
        worlds, counts = enumerate_group(group, require_unique)
        for stage, count in zip(group, counts):
            counts_by_id[stage["id"]] = count
            states_by_id[stage["id"]] = worlds
    return counts_by_id, states_by_id

def assert_metadata(stage):
    if "normal_posts" in stage or "tall_posts" in stage or "plate_posts" in stage:
        require(typed_inventory_exact(stage), f"{stage['id']}: exact typed inventory metadata mismatch")
    require(not stage.get("free_light_selection"), f"{stage['id']}: replacement must use fixed lights")
    require(not stage.get("movable_shutter"), f"{stage['id']}: replacement cannot use a movable shutter")
    if stage["id"] in REPLACEMENTS:
        require("boardShape" in stage and len(legal_positions(stage)) >= stage["posts"],
                f"{stage['id']}: illegal/empty board shape")
        require(stage.get("shape_required") is True, f"{stage['id']}: missing shape-required tag")
        require(len(stage["observations"]) == 1, f"{stage['id']}: must have one observation")
        require(stage.get("shape_without_mask_survivors", 0) > 1, f"{stage['id']}: shape does not contribute")
        if stage.get("tall_required"):
            require(stage.get("tall_posts", 0) > 0, f"{stage['id']}: Tall flag without Tall inventory")
        if stage.get("plate_required"):
            require(stage.get("plate_posts", 0) > 0, f"{stage['id']}: Plate flag without Plate inventory")
        target = stage["observations"][0]["target"]
        fog = set(stage.get("fog_cells", []))
        require(set(target) == set(CELLS) - fog, f"{stage['id']}: visible zeros must be explicit and FOG omitted")
        require(len(fog) in (0, 3, 4, 5, 6), f"{stage['id']}: invalid fog count")
        require(stage.get("installed_lights") == ["TOP", "LEFT", "RIGHT", "BOTTOM"],
                f"{stage['id']}: physical lamp mounts changed")
        require(stage["observations"][0]["active_lights"], f"{stage['id']}: no fixed lamps")

def make_stage_from_candidate(candidate):
    p = candidate["profile"]
    stage = {
        "id": candidate["id"], "posts": p["normal"] + p["tall"] + p["plate"],
        "normal_posts": p["normal"], "tall_posts": p["tall"], "plate_posts": p["plate"],
        "solution": list(candidate["solution_cells"]),
        "solution_post_types": dict(candidate["solution_post_types"]),
        "observations": [{"id": "A", "active_lights": list(candidate["lights"]), "target": dict(candidate["target"])}],
        "expected_states": p["expected_states"],
        "boardShape": {"mask": list(candidate["boardShape"]["mask"])},
    }
    if p["plate"]:
        stage["rotatable_plate"] = True
    if candidate.get("fog_cells"):
        stage["fog_cells"] = list(candidate["fog_cells"])
    return stage

def validate_fixture_data():
    data = json.loads(FIXTURES.read_text(encoding="utf-8"))
    require(data["lights"] == ["TOP", "LEFT", "RIGHT"], "legacy fixture light set must match its original simple model")
    fixtures = []
    for fixture in data["fixtures"]:
        unknown = []
        visible = {}
        for y, row in enumerate(fixture["target"]):
            for x, token in enumerate(row):
                name = code(y * 5 + x)
                if token == "?":
                    unknown.append(name)
                else:
                    visible[name] = int(token)
        solution = fixture["solution"]
        stage = {
            "id": fixture["id"], "posts": fixture["normal_posts"],
            "normal_posts": fixture["normal_posts"], "tall_posts": 0, "plate_posts": 0,
            "solution": list(solution), "solution_post_types": {name: "normal" for name in solution},
            "observations": [{"id": "A", "active_lights": list(data["lights"]), "target": visible}],
            "fog_cells": unknown,
            "boardShape": {"mask": list(fixture["mask"])},
            "expected_states": 0,
        }
        fixtures.append((fixture, stage))
    counts, states = enumerate_stages([stage for _, stage in fixtures])
    for fixture, stage in fixtures:
        require(counts[stage["id"]] == 1, f"legacy fixture {fixture['name']} is not unique")
        require(set(normalized_solution(stage)) == {(cell(name), "normal") for name in fixture["solution"]},
                f"legacy fixture {fixture['name']} solution metadata mismatch")
    return fixtures, counts, states

def malformed_mask_tests():
    require(len(legal_positions({"posts": 1})) == 25, "missing boardShape must remain full board")
    invalid = [
        {"boardShape": {"mask": ["11111"] * 4}},
        {"boardShape": {"mask": ["11111"] * 4 + ["1111"]}},
        {"boardShape": {"mask": ["11111"] * 4 + ["1111x"]}},
        {"boardShape": {"mask": "11111"}},
        {"boardShape": []},
        {"boardShape": {"mask": [None, "11111", "11111", "11111", "11111"]}},
    ]
    for index, case in enumerate(invalid):
        try:
            legal_positions(case)
        except (TypeError, ValueError):
            continue
        raise ValueError(f"malformed board mask {index} was accepted")
    illegal_fixed = {
        "posts": 1, "fixed_posts": ["A1"], "boardShape": {"mask": ["01111"] + ["11111"] * 4},
        "normal_posts": 1, "tall_posts": 0, "plate_posts": 0,
    }
    require(next(iter(object_states(illegal_fixed)), None) is None, "fixed post outside mask remained a legal world")
    return 8

def reduced_stage(stage, reduce_kind):
    result = copy.deepcopy(stage)
    result["expected_states"] = 0
    if reduce_kind == "tall":
        result["normal_posts"] = int(result.get("normal_posts", 0)) + int(result.get("tall_posts", 0))
        result["tall_posts"] = 0
        result.pop("tall", None)
    elif reduce_kind == "plate":
        result["normal_posts"] = int(result.get("normal_posts", 0)) + int(result.get("plate_posts", 0))
        result["plate_posts"] = 0
        result.pop("rotatable_plate", None)
    result["posts"] = result["normal_posts"] + result["tall_posts"] + result["plate_posts"]
    return result

def report_update(fixtures, fixture_counts, fixture_states, elapsed):
    text = REPORT.read_text(encoding="utf-8")
    for fixture, stage in fixtures:
        old = f"| {fixture['name']} | pending validator | pending validator | 1 |"
        new = f"| {fixture['name']} | {len(legal_positions(stage))} | {fixture_states[stage['id']]} | 1 |"
        text = text.replace(old, new)
    text = re.sub(r"Independent validator: [0-9.]+s", f"Independent validator: {elapsed:.2f}s", text)
    text = text.replace("The validator re-enumerates all 36 campaign stages and the six legacy fixtures, tests malformed masks, exact typing, shape/Tall/Plate counterfactuals, and FOG-as-unknown.",
                        "The independent validator re-enumerates all 36 campaign stages and all pool candidates, checks six exact legacy fixtures, malformed masks, exact typing, shape/Tall/Plate counterfactuals, and FOG-as-unknown.")
    REPORT.write_text(text, encoding="utf-8")

def main():
    started = time.perf_counter()
    campaign = json.loads(CAMPAIGN.read_text(encoding="utf-8"))
    v04 = json.loads(V04.read_text(encoding="utf-8"))
    pool = json.loads(POOL.read_text(encoding="utf-8"))
    require(len(campaign) == 36, "campaign must contain 36 stages")
    by_id = {stage["id"]: stage for stage in campaign}
    old_by_id = {stage["id"]: stage for stage in v04}
    require([stage["id"] for stage in campaign] == [f"GR{i:02d}" for i in range(1, 37)], "campaign ID order changed")
    for stage_id in [f"GR{i:02d}" for i in range(1, 21)] + list(KEEP):
        require(by_id[stage_id] == old_by_id[stage_id], f"{stage_id}: protected stage changed")
    for stage_id in REPLACEMENTS:
        assert_metadata(by_id[stage_id])

    fixtures, fixture_counts, fixture_states = validate_fixture_data()
    malformed_tests = malformed_mask_tests()
    all_campaign_counts, all_campaign_states = enumerate_stages(campaign)
    for stage in campaign:
        if stage["id"] in REPLACEMENTS:
            require(stage.get("expected_solutions") == 1, f"{stage['id']}: metadata unique count missing")
    # Verify replacement mechanic counterfactuals independently.
    counter_stages = []
    counter_ids = []
    no_mask_stages = []
    no_mask_ids = []
    for stage_id in REPLACEMENTS:
        stage = by_id[stage_id]
        if stage.get("tall_required"):
            reduced = reduced_stage(stage, "tall")
            reduced["id"] += "-NO-TALL"
            counter_stages.append(reduced)
            counter_ids.append((reduced["id"], stage_id, "tall"))
        if stage.get("plate_required"):
            reduced = reduced_stage(stage, "plate")
            reduced["id"] += "-NO-PLATE"
            counter_stages.append(reduced)
            counter_ids.append((reduced["id"], stage_id, "plate"))
        without_shape = copy.deepcopy(stage)
        without_shape.pop("boardShape", None)
        without_shape["expected_states"] = 0
        without_shape["id"] += "-NO-SHAPE"
        no_mask_stages.append(without_shape)
        no_mask_ids.append((without_shape["id"], stage_id))
    counter_counts, counter_states = enumerate_stages(counter_stages, require_unique=False) if counter_stages else ({}, {})
    for counter_id, stage_id, mechanic in counter_ids:
        require(counter_counts[counter_id] == 0, f"{stage_id}: {mechanic}-as-Normal substitution still solves")
    no_mask_counts, no_mask_states = enumerate_stages(no_mask_stages, require_unique=False)
    for counter_id, stage_id in no_mask_ids:
        count = no_mask_counts[counter_id]
        require(count == int(by_id[stage_id]["shape_without_mask_survivors"]),
                f"{stage_id}: no-mask counterfactual count {count} disagrees with metadata")
        require(count > 1, f"{stage_id}: shape is not necessary")

    # Every candidate in the generated pool receives independent exact enumeration.
    candidates = pool["candidates"]
    require(len(candidates) >= 120, f"candidate pool only has {len(candidates)} exact candidates")
    counts_by_slot = Counter(candidate["slot"] for candidate in candidates)
    require(all(counts_by_slot[slot] >= 15 for slot in REPLACEMENTS), "each replacement profile needs at least 15 candidates")
    candidate_stages = [make_stage_from_candidate(candidate) for candidate in candidates]
    candidate_counts, candidate_states = enumerate_stages(candidate_stages)
    for candidate, stage in zip(candidates, candidate_stages):
        require(candidate_counts[candidate["id"]] == 1, f"{candidate['id']}: pool target is not exact unique")
        require(candidate["exact_survivors"] == 1 and candidate["typed_inventory_exact"], f"{candidate['id']}: generated hard-gate metadata")
        require(candidate["shape_required"] and candidate["shape_without_mask_survivors"] > 1,
                f"{candidate['id']}: generated shape counterfactual")
        require(not candidate["profile"]["free_light_selection"] and not candidate["profile"]["movable_shutter"],
                f"{candidate['id']}: environment control slipped into pool")
        require(set(candidate["solution_cells"]) <= {code(i) for i in legal_positions(stage)},
                f"{candidate['id']}: solution outside legal mask")
    selected_ids = set(pool["selected"])
    require(len(selected_ids) == 8, "selection must contain exactly eight stages")
    for stage_id in REPLACEMENTS:
        chosen = [c for c in candidates if c["slot"] == stage_id and c["id"] in selected_ids]
        require(len(chosen) == 1, f"{stage_id}: exactly one selected candidate required")

    # P0: reject aliases rather than silently treating unknown Plate labels as Normal.
    try:
        category("plate")
    except ValueError:
        pass
    else:
        raise ValueError("legacy generic plate alias was accepted as a Normal category")
    old_gr34 = old_by_id["GR34"]
    old_no_plate = copy.deepcopy(old_gr34)
    old_no_plate["normal_posts"] = int(old_no_plate.get("normal_posts", 0)) + int(old_no_plate.get("plate_posts", 0))
    old_no_plate["plate_posts"] = 0
    old_no_plate.pop("rotatable_plate", None)
    old_no_plate["expected_states"] = 0
    old_no_plate["id"] = "GR34-v04-NO-PLATE"
    old_gr34_no_plate_count, _ = enumerate_stages([old_no_plate], require_unique=False)
    old_gr34_no_plate = old_gr34_no_plate_count[old_no_plate["id"]]

    ranked_rows = sum(1 for _ in RANKED.open(encoding="utf-8")) - 1
    require(ranked_rows >= len(candidates), "ranked CSV is missing candidate rows")
    fog_stage = by_id["GR29"]
    require(len(fog_stage.get("fog_cells", [])) in range(3, 7), "GR29 needs 3-6 fog cells")
    actual_shadow = shadow(normalized_solution(fog_stage), fog_stage["observations"][0]["active_lights"])
    require(any(actual_shadow[cell(name)] > 0 for name in fog_stage["fog_cells"]), "GR29 hidden cells must include a nonzero value")
    zero_fog_target = dict(fog_stage["observations"][0]["target"])
    zero_fog_target.update({name: 0 for name in fog_stage["fog_cells"]})
    wrong_fog = copy.deepcopy(fog_stage)
    wrong_fog["fog_cells"] = []
    wrong_fog["observations"][0]["target"] = zero_fog_target
    wrong_fog["expected_states"] = 0
    wrong_count, _ = enumerate_stages([wrong_fog], require_unique=False)
    require(wrong_count[wrong_fog["id"]] == 0, "FOG was incorrectly treated as explicit zero")
    require(fog_stage.get("fog_removes_shortcut") is True, "GR29 fog must lengthen the deduction trace")

    elapsed = time.perf_counter() - started
    report_update(fixtures, fixture_counts, fixture_states, elapsed)
    output = {
        "campaign_stages": 36,
        "campaign_survivors": all_campaign_counts,
        "campaign_search_spaces": all_campaign_states,
        "fixture_search_spaces": fixture_states,
        "fixture_survivors": fixture_counts,
        "candidate_pool_size": len(candidates),
        "candidate_count_by_slot": dict(counts_by_slot),
        "candidate_survivors": candidate_counts,
        "candidate_search_spaces": candidate_states,
        "shape_without_mask_survivors": no_mask_counts,
        "reduced_type_survivors": counter_counts,
        "old_v04_gr34_no_plate_survivors": old_gr34_no_plate,
        "malformed_mask_checks": malformed_tests,
        "fog_unknown_rejected_as_zero": True,
        "elapsed_seconds": round(elapsed, 3),
    }
    (ROOT / "generated/grant36_v0_5_validation.json").write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"GRANT36 v0.5: 36 campaign stages, 6 fixtures, {len(candidates)} candidates all exact unique")
    print(f"Replacements: shape/no-mask survivors={[(s, no_mask_counts[s + '-NO-SHAPE']) for s in REPLACEMENTS]}")
    print(f"Old v0.4 GR34 no-Plate matches: {old_gr34_no_plate}")
    print(f"FOG unknown-as-zero rejection: passed; malformed-mask cases: {malformed_tests}")
    print(f"Independent validation: {elapsed:.2f}s")

if __name__ == "__main__":
    main()
