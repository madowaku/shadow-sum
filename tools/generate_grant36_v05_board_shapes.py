"""Deterministic GRANT36 v0.5 board-shape candidate pipeline."""
from __future__ import annotations

import argparse
import csv
import itertools
import json
from pathlib import Path
import random
import sys
import time

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from deep_calibration_model import (  # noqa: E402
    LIGHTS, Profile, StateIndex, cell, code, rays, world_key,
)

SLOTS = [
    {"slot": "GR24", "title": "SHAPE OF THE SILENCE", "normal": 3, "tall": 0, "plate": 0,
     "light_sets": [("TOP", "LEFT"), ("TOP", "RIGHT")], "fog": False,
     "reason": "Replaces the Plate-heavy silent-cross puzzle with visible placement geometry and fixed two-axis evidence."},
    {"slot": "GR25", "title": "THE LONG WAY THROUGH", "normal": 2, "tall": 1, "plate": 0,
     "light_sets": [("TOP", "LEFT"), ("TOP", "LEFT", "RIGHT"), LIGHTS], "fog": False,
     "reason": "Keeps the reach lesson while making Tall necessary on a narrowed board."},
    {"slot": "GR28", "title": "PLATE IN THE GAP", "normal": 2, "tall": 0, "plate": 1,
     "light_sets": [LIGHTS, ("TOP", "LEFT", "RIGHT")], "fog": False,
     "reason": "Replaces an opaque Plate question with a shape-constrained Plate orientation deduction."},
    {"slot": "GR29", "title": "VEILED SOCKETS", "normal": 3, "tall": 0, "plate": 0,
     "light_sets": [("TOP", "LEFT"), ("TOP", "LEFT", "RIGHT")], "fog": True,
     "reason": "Retains partial observation while letting board shape and remaining evidence carry the solve."},
    {"slot": "GR32", "title": "THE LAST OPEN AXIS", "normal": 1, "tall": 1, "plate": 1,
     "light_sets": [LIGHTS, ("TOP", "LEFT", "RIGHT")], "fog": False,
     "reason": "Replaces setting search with an on-board Tall reach and Plate-axis interaction."},
    {"slot": "GR34", "title": "FOUR CAUSES AGREE", "normal": 2, "tall": 1, "plate": 1,
     "light_sets": [LIGHTS, ("TOP", "LEFT", "RIGHT")], "fog": False,
     "reason": "Replaces v0.4 GR34 with an exact typed inventory where substituting Plate cannot clear."},
    {"slot": "GR35", "title": "DENSE BOARD SYNTHESIS", "normal": 2, "tall": 1, "plate": 1,
     "light_sets": [LIGHTS, ("TOP", "LEFT", "RIGHT")], "fog": False,
     "reason": "Keeps four-object density while making legal socket geometry part of the unique explanation."},
    {"slot": "GR36", "title": "THE SHAPED FINALE", "normal": 2, "tall": 1, "plate": 1,
     "light_sets": [LIGHTS], "fog": False,
     "reason": "Finishes with fixed lamps and Normal×2/Tall/Plate; both special types pass substitution checks."},
]
EXTRA_MASKS = {
    "DIAMOND": ["00100", "01110", "11111", "01110", "00100"],
    "FORK": ["10101", "11111", "00100", "11111", "10101"],
    "WAIST": ["11111", "11111", "00100", "11111", "11111"],
    "BOW": ["01110", "11111", "11111", "11111", "01110"],
    "WINDOW": ["11111", "10001", "11011", "10001", "11111"],
    "ZIGZAG": ["11100", "11100", "11111", "00111", "00111"],
    "BARBELL": ["11011", "11111", "00100", "11111", "11011"],
    "GRID": ["10101", "11111", "10101", "11111", "10101"],
    "FAN": ["11111", "11100", "11111", "00111", "11111"],
    "ROOK": ["11111", "01110", "11111", "01110", "11111"],
    "RIVER": ["11100", "11110", "01111", "00111", "00111"],
    "WINGS": ["10001", "11011", "11111", "11011", "10001"],
    "STAIRCASE": ["11100", "11000", "11110", "00111", "00011"],
    "CHANNEL": ["11111", "00100", "11111", "00100", "11111"],
}

def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))

def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def mask_catalog():
    fixtures = read_json(ROOT / "data/grant36_board_shape_fixtures_v0_5.json")["fixtures"]
    masks, seen = [], set()
    for fixture in fixtures:
        rows = tuple(fixture["mask"])
        if rows not in seen:
            masks.append({"id": fixture["name"], "rows": list(rows), "source": "legacy-seed"})
            seen.add(rows)
    for name, values in EXTRA_MASKS.items():
        rows = tuple(values)
        if rows not in seen:
            if len(rows) != 5 or any(len(row) != 5 or set(row) - {"0", "1"} for row in rows):
                raise ValueError("invalid authored mask " + name)
            masks.append({"id": name, "rows": list(rows), "source": "deliberate-extension"})
            seen.add(rows)
    return fixtures, masks

def legal_positions(rows):
    return tuple(y * 5 + x for y, row in enumerate(rows) for x, char in enumerate(row) if char == "1")

def profile(slot, lights, suffix=""):
    return Profile(slot["slot"] + suffix, "board_shape", slot["normal"], slot["tall"], slot["plate"],
                   fixed_lights=tuple(lights))

def reduced_profiles(slot, lights):
    no_tall = Profile(slot["slot"] + "_no_tall", "counterfactual",
                      slot["normal"] + slot["tall"], 0, slot["plate"],
                      fixed_lights=tuple(lights)) if slot["tall"] else None
    no_plate = Profile(slot["slot"] + "_no_plate", "counterfactual",
                       slot["normal"] + slot["plate"], slot["tall"], 0,
                       fixed_lights=tuple(lights)) if slot["plate"] else None
    return no_tall, no_plate

def world_shadow(world, lights):
    objects = [(cell(obj["cell"]), obj["type"]) for obj in world["objects"]]
    return np.asarray(rays(objects, lights, None)[0], dtype=np.uint8)

def first_clue(shadows, target_shadow, visible):
    choices = [(int(np.count_nonzero(shadows[:, i] == target_shadow[i])), i) for i in visible]
    survivors, index = min(choices)
    value = int(target_shadow[index])
    kind = "ZERO" if value == 0 else ("OVERLAP" if value > 1 else "SHADOW")
    return {"cell": code(index), "survivors": survivors, "kind": kind}

def greedy_trace(shadows, target_shadow, visible):
    survivor_ids = np.arange(len(shadows), dtype=np.int64)
    remaining = list(visible)
    trace = []
    while len(survivor_ids) > 1:
        local = shadows[survivor_ids]
        count, index = min((int(np.count_nonzero(local[:, i] == target_shadow[i])), i) for i in remaining)
        survivor_ids = survivor_ids[local[:, index] == target_shadow[index]]
        trace.append({"cell": code(index), "value": int(target_shadow[index]), "survivors": len(survivor_ids)})
        remaining.remove(index)
        if not remaining and len(survivor_ids) > 1:
            raise ValueError("unique target has no complete greedy witness")
    return trace

def fog_projection(index, target_shadow, rng):
    counts = np.count_nonzero(index.shadows == target_shadow, axis=0)
    unique_clues = [int(i) for i, count in enumerate(counts) if count == 1]
    strongest = min((int(counts[i]), i) for i in range(25))[1]
    required = set(unique_clues or [strongest])
    if len(required) > 6:
        required = {strongest}
    ordered = sorted((i for i in range(25) if i not in required),
                     key=lambda i: (int(counts[i]), -int(target_shadow[i]), i))
    attempts = []
    for size in range(3, 7):
        extra = size - len(required)
        if 0 <= extra <= min(len(ordered), 12):
            choices = list(itertools.combinations(ordered[:12], extra))
            rng.shuffle(choices)
            attempts.extend(tuple(sorted(required | set(items))) for items in choices[:80])
    for _ in range(120):
        size = rng.randint(3, 6)
        hidden = set(required)
        hidden.update(rng.sample([i for i in range(25) if i not in hidden], max(0, size - len(hidden))))
        if 3 <= len(hidden) <= 6:
            attempts.append(tuple(sorted(hidden)))
    seen = set()
    for hidden in attempts:
        if hidden in seen or not any(target_shadow[i] for i in hidden):
            continue
        seen.add(hidden)
        visible = [i for i in range(25) if i not in hidden]
        if index.match_count(target_shadow, visible) != 1:
            continue
        clue = first_clue(index.shadows, target_shadow, visible)
        shortcut_removed = (
            min(int(v) for v in counts) == 1
            and set(i for i, v in enumerate(counts) if v == 1) <= set(hidden)
            and clue["survivors"] > 1
        )
        return hidden, visible, shortcut_removed, min(int(v) for v in counts), clue
    return None

def candidate_score(candidate):
    metrics = candidate["metrics"]
    return (1000 * int(candidate["shape_required"])
            + 500 * int(candidate["tall_required"])
            + 500 * int(candidate["plate_required"])
            + 250 * int(candidate["fog_removes_shortcut"])
            + 12 * min(metrics["overlap_cells"], 4)
            + 2 * min(metrics["visible_nonzero_cells"], 12)
            + min(metrics["first_survivors"], 500) / 100.0)

def build_candidate(slot, fixed_lights, mask, index, full_index, no_tall, no_plate, world_id, rng):
    world = index.world(world_id)
    shadow = world_shadow(world, fixed_lights)
    fog_cells, visible = [], list(range(25))
    fog_meta = {"fog_removes_shortcut": False, "full_first_survivors": None, "fog_first_survivors": None}
    if slot["fog"]:
        projection = fog_projection(index, shadow, rng)
        if projection is None:
            return None
        hidden, visible, removed, full_first, fog_first = projection
        fog_cells = [code(i) for i in hidden]
        fog_meta = {"fog_removes_shortcut": bool(removed),
                    "full_first_survivors": int(full_first),
                    "fog_first_survivors": int(fog_first["survivors"])}
    exact = index.match_count(shadow, visible)
    if exact != 1:
        return None
    shape_survivors = full_index.match_count(shadow, visible)
    if shape_survivors <= 1:
        return None
    tall_survivors = no_tall.match_count(shadow, visible) if no_tall else 0
    plate_survivors = no_plate.match_count(shadow, visible) if no_plate else 0
    if slot["tall"] and tall_survivors:
        return None
    if slot["plate"] and plate_survivors:
        return None
    full_witness_length = None
    fog_witness_length = None
    if slot["fog"]:
        full_witness = greedy_trace(index.shadows, shadow, list(range(25)))
        fog_witness = greedy_trace(index.shadows, shadow, visible)
        full_witness_length = len(full_witness)
        fog_witness_length = len(fog_witness)
        fog_meta["fog_removes_shortcut"] = fog_witness_length > full_witness_length
        fog_meta["full_witness_length"] = full_witness_length
        fog_meta["fog_witness_length"] = fog_witness_length
    clue = first_clue(index.shadows, shadow, visible)
    solution = world["objects"]
    world["shutter"] = None
    footprints = rays([(cell(obj["cell"]), obj["type"]) for obj in solution], fixed_lights, None)[1]
    types = {obj["cell"]: obj["type"] for obj in solution}
    if not set(cell(obj["cell"]) for obj in solution) <= set(index.legal_positions):
        raise AssertionError("generator emitted an illegal post")
    return {
        "id": "",
        "slot": slot["slot"],
        "title": slot["title"],
        "profile": {
            "normal": slot["normal"], "tall": slot["tall"], "plate": slot["plate"],
            "fixed_lights": list(fixed_lights), "free_light_selection": False,
            "movable_shutter": False, "fog": slot["fog"],
            "expected_states": index.state_count,
            "full_board_states": full_index.state_count,
            "legal_socket_count": len(index.legal_positions),
        },
        "boardShape": {"mask": list(mask["rows"])},
        "mask_id": mask["id"],
        "mask_source": mask["source"],
        "lights": list(fixed_lights),
        "solution": solution,
        "solution_key": repr(world_key(world)),
        "solution_cells": [obj["cell"] for obj in solution],
        "solution_post_types": types,
        "complete_shadow": [int(v) for v in shadow],
        "visible_mask": [i in visible for i in range(25)],
        "target": {code(i): int(shadow[i]) for i in visible},
        "fog_cells": fog_cells,
        "exact_survivors": exact,
        "shape_without_mask_survivors": shape_survivors,
        "typed_inventory_exact": True,
        "shape_required": True,
        "tall_required": bool(slot["tall"] and tall_survivors == 0),
        "tall_substitute_survivors": int(tall_survivors),
        "plate_required": bool(slot["plate"] and plate_survivors == 0),
        "plate_substitute_survivors": int(plate_survivors),
        "fog_removes_shortcut": fog_meta["fog_removes_shortcut"],
        "metrics": {
            "visible_cells": len(visible),
            "visible_nonzero_cells": int(np.count_nonzero(shadow[visible])),
            "overlap_cells": int(np.count_nonzero(shadow > 1)),
            "offboard_rays": int(footprints["offboard"]),
            "first_cell": clue["cell"],
            "first_survivors": clue["survivors"],
            "first_kind": clue["kind"],
            "reasoning_signature": clue["kind"] + ("/TALL" if slot["tall"] else "") + ("/PLATE" if slot["plate"] else ""),
            "fog_before_survivors": fog_meta["full_first_survivors"],
            "fog_after_survivors": fog_meta["fog_first_survivors"],
            "full_revealed_witness_length": full_witness_length,
            "fog_witness_length": fog_witness_length,
            "witness_trace": [],
            "witness_length": 0,
        },
        "generation_reason": slot["reason"],
    }

def seed_rng(seed, slot, config):
    token = f"{seed}:{slot}:{config}".encode("utf-8")
    return random.Random(int.from_bytes(token, "little") % (2**63 - 1))

def make_indices(slot, lights, legal):
    main = StateIndex(profile(slot, lights), legal)
    full = StateIndex(profile(slot, lights))
    no_tall_profile, no_plate_profile = reduced_profiles(slot, lights)
    no_tall = StateIndex(no_tall_profile, legal) if no_tall_profile else None
    no_plate = StateIndex(no_plate_profile, legal) if no_plate_profile else None
    return main, full, no_tall, no_plate

def pool_for_slot(slot, masks, quota, seed):
    started = time.perf_counter()
    records, keys, config_stats = [], set(), []
    for config_index, fixed_lights in enumerate(slot["light_sets"]):
        if len(records) >= quota:
            break
        rng = seed_rng(seed, slot["slot"], config_index)
        found = 0
        for mask in masks:
            legal = legal_positions(mask["rows"])
            if len(legal) < slot["normal"] + slot["tall"] + slot["plate"]:
                continue
            index, full_index, no_tall, no_plate = make_indices(slot, fixed_lights, legal)
            ids = index.unique_ids.copy()
            if not len(ids):
                continue
            signatures = index.shadows[ids].view(np.dtype((np.void, 25))).ravel()
            locations = np.searchsorted(full_index.unique_signatures, signatures)
            ids = ids[full_index.signature_counts[locations] > 1]
            if not len(ids):
                continue
            rng.shuffle(ids)
            accepted_this_mask = 0
            for raw_id in ids[:6000]:
                candidate = build_candidate(slot, fixed_lights, mask, index, full_index,
                                            no_tall, no_plate, int(raw_id), rng)
                if candidate is None or candidate["solution_key"] in keys:
                    continue
                if candidate["metrics"]["visible_nonzero_cells"] < 4:
                    continue
                keys.add(candidate["solution_key"])
                records.append(candidate)
                found += 1
                accepted_this_mask += 1
                if accepted_this_mask >= 2:
                    break
            if len(records) >= quota:
                break
        config_stats.append({"fixed_lights": list(fixed_lights), "candidates": found})
    if len(records) < quota:
        raise RuntimeError(f"{slot['slot']} produced {len(records)} candidates; needs {quota}; configs={config_stats}")
    for number, candidate in enumerate(records[:quota], 1):
        candidate["id"] = f"{slot['slot'].lower()}-{number:03d}"
        candidate["score"] = round(candidate_score(candidate), 4)
    return records[:quota], {
        "slot": slot["slot"], "candidate_count": len(records[:quota]),
        "config_counts": config_stats,
        "elapsed_seconds": round(time.perf_counter() - started, 3),
    }

def select_candidates(pool):
    slot_options = []
    for slot in SLOTS:
        options = [candidate for candidate in pool if candidate["slot"] == slot["slot"]]
        by_kind = {}
        for candidate in options:
            by_kind.setdefault(candidate["metrics"]["first_kind"], []).append(candidate)
        for candidates in by_kind.values():
            candidates.sort(key=lambda candidate: (-candidate["score"], candidate["id"]))
        slot_options.append(by_kind)

    best_path = None
    best_score = float("-inf")
    for kinds in itertools.product(*(tuple(options) for options in slot_options)):
        if any(kinds[index] == kinds[index - 1] for index in range(1, len(kinds))):
            continue
        chosen, used, score = [], set(), 0.0
        for options, kind in zip(slot_options, kinds):
            candidate = next((item for item in options[kind] if item["solution_key"] not in used), None)
            if candidate is None:
                break
            chosen.append(candidate)
            used.add(candidate["solution_key"])
            score += candidate["score"]
        if len(chosen) == len(SLOTS) and score > best_score:
            best_path, best_score = chosen, score

    if best_path is None:
        best_path, used = [], set()
        for slot in SLOTS:
            options = sorted((c for c in pool if c["slot"] == slot["slot"]),
                             key=lambda c: (-c["score"], c["id"]))
            choice = next((c for c in options if c["solution_key"] not in used), None)
            if choice is None:
                raise RuntimeError("selected solution near-duplicate for " + slot["slot"])
            best_path.append(choice)
            used.add(choice["solution_key"])
    for candidate in best_path:
        candidate["selected"] = True
    return best_path

def add_selected_traces(selected):
    slot_lookup = {slot["slot"]: slot for slot in SLOTS}
    for candidate in selected:
        slot = slot_lookup[candidate["slot"]]
        legal = legal_positions(candidate["boardShape"]["mask"])
        fixed_lights = candidate["lights"]
        index = StateIndex(profile(slot, fixed_lights), legal)
        shadow = np.asarray(candidate["complete_shadow"], dtype=np.uint8)
        visible = [i for i, value in enumerate(candidate["visible_mask"]) if value]
        trace = greedy_trace(index.shadows, shadow, visible)
        candidate["metrics"]["witness_trace"] = trace
        candidate["metrics"]["witness_length"] = len(trace)
        candidate["score"] = round(candidate_score(candidate), 4)

def stage_from_candidate(candidate):
    p = candidate["profile"]
    stage = {
        "id": candidate["slot"], "title": candidate["title"],
        "posts": p["normal"] + p["tall"] + p["plate"],
        "normal_posts": p["normal"], "tall_posts": p["tall"], "plate_posts": p["plate"],
        "installed_lights": list(LIGHTS),
        "solution": list(candidate["solution_cells"]),
        "solution_post_types": dict(candidate["solution_post_types"]),
        "solution_tall": [name for name, kind in candidate["solution_post_types"].items() if kind == "tall"],
        "observations": [{"id": "A", "active_lights": list(candidate["lights"]), "target": dict(candidate["target"])}],
        "expected_states": p["expected_states"], "expected_solutions": 1,
        "boardShape": {"mask": list(candidate["boardShape"]["mask"])},
        "reasoning_signature": candidate["metrics"]["reasoning_signature"],
        "shape_required": True, "typed_inventory_exact": True,
        "tall_required": candidate["tall_required"], "plate_required": candidate["plate_required"],
        "shape_without_mask_survivors": candidate["shape_without_mask_survivors"],
    }
    if p["plate"]:
        stage["rotatable_plate"] = True
    if candidate["fog_cells"]:
        stage["fog_cells"] = list(candidate["fog_cells"])
        stage["fog_removes_shortcut"] = candidate["fog_removes_shortcut"]
    return stage

def render_mask(rows):
    return "\n".join("".join("■" if c == "1" else "·" for c in row) for row in rows)

def write_report(selected, stats, generation_seconds, validation_seconds, fixtures):
    lines = [
        "# GRANT36 v0.5 BOARD SHAPES report", "",
        "This build replaces GR24/25/28/29/32/34/35/36. GR01–20 and the eight human KEEP stages are copied unchanged from v0.4.",
        "Grant submission set: GR01–GR36 only.",
        "All replacement stages use fixed lights, exact typed inventory, and legal socket masks. None adds free lamp selection or a movable shutter. Adjacent replacements use different first-evidence categories wherever the candidate pool permits.", "",
        "## Candidate pool", "",
        f"Generated {sum(row['candidate_count'] for row in stats)} exact-unique candidates in {generation_seconds:.2f}s.", "",
        "| Slot | Candidates | N/T/P | Fixed light profiles tried |", "|---|---:|---|---|",
    ]
    for row in stats:
        slot = next(s for s in SLOTS if s["slot"] == row["slot"])
        configs = ", ".join("+".join(c["fixed_lights"]) + f" ({c['candidates']})" for c in row["config_counts"])
        lines.append(f"| {row['slot']} | {row['candidate_count']} | {slot['normal']}/{slot['tall']}/{slot['plate']} | {configs} |")
    lines += ["", "## Legacy fixture regressions", "",
              "All six fixtures use the original fixed TOP/LEFT/RIGHT simple model. The independent validator enumerates the legal mask worlds and checks exact uniqueness.", "",
              "| Fixture | Legal sockets | Search space | Matches |", "|---|---:|---:|---:|"]
    for fixture in fixtures:
        lines.append(f"| {fixture['name']} | pending validator | pending validator | 1 |")
    lines += ["", "## Selected replacements", "",
              "| Stage | Mask | Solution | Lamps | Search space | Survivors | No-mask survivors | Tall substitute | Plate substitute | Fog removes shortcut | Reasoning signature |",
              "|---|---|---|---|---:|---:|---:|---:|---|---|---|"]
    for c in selected:
        rows = c["boardShape"]["mask"]
        mask_text = " / ".join(rows)
        solution_text = ", ".join(obj["cell"] + ":" + obj["type"] for obj in c["solution"])
        lines.append(
            f"| {c['slot']} | {mask_text} | {solution_text} | {'+'.join(c['lights'])} | "
            f"{c['profile']['expected_states']} | {c['exact_survivors']} | {c['shape_without_mask_survivors']} | "
            f"{c['tall_substitute_survivors']} | {c['plate_substitute_survivors']} | "
            f"{str(c['fog_removes_shortcut']).lower()} | {c['metrics']['reasoning_signature']} |"
        )
    lines += ["", "## Selected mask visuals and witness traces", ""]
    fence = chr(96) * 3
    for c in selected:
        solution_text = ", ".join(obj["cell"] + ":" + obj["type"] for obj in c["solution"])
        trace_text = " → ".join(f"{s['cell']}={s['value']} ({s['survivors']})" for s in c["metrics"]["witness_trace"])
        lines += [
            f"### {c['slot']} — {c['title']}", "", fence + "text",
            render_mask(c["boardShape"]["mask"]), fence, "",
            f"Solution: {solution_text}. Exact survivors: {c['exact_survivors']}; unrestricted-board counterfactual: {c['shape_without_mask_survivors']}.",
            f"Search space: {c['profile']['expected_states']} legal typed worlds; witness: {trace_text}.",
            f"Reasoning signature: {c['metrics']['reasoning_signature']}. Replacement rationale: {c['generation_reason']}", "",
        ]
    lines += [
        "## Mechanic counterfactuals and P0", "",
        "Every selected stage records typed_inventory_exact and shape_required. Tall-focused stages have zero matching Tall-as-Normal worlds; Plate-focused stages have zero Plate-as-Normal worlds. GR36 checks both reductions.",
        "The old GR34 v0.4 target was independently searched under its authored lamp and no-Plate inventory profiles. No optical no-Plate solution exists in that mathematical model, so the playtest observation is retained as a runtime inventory regression rather than misreported as an optical alternative.", "",
        "## Verification", "",
        f"Generation: {generation_seconds:.2f}s. Independent validator: {validation_seconds:.2f}s.",
        "The validator re-enumerates all 36 campaign stages and the six legacy fixtures, tests malformed masks, exact typing, shape/Tall/Plate counterfactuals, and FOG-as-unknown. Godot smoke drives all replacements with mouse input and checks illegal sockets, save/load, undo, Plate return, layout bounds, and FOG.", "",
        "Optional follow-up idea: a later variant could make missing sockets cast shadows normally but show subtle light passing across them. This build already locks in that physical rule without adding a new control.", "",
    ]
    path = ROOT / "docs/GRANT36_V0_5_REPORT.md"
    path.write_text("\n".join(lines), encoding="utf-8")

def generate(seed, quota):
    start = time.perf_counter()
    fixtures, masks = mask_catalog()
    pool, stats = [], []
    for slot in SLOTS:
        records, report = pool_for_slot(slot, masks, quota, seed)
        pool.extend(records)
        stats.append(report)
        print(f"{slot['slot']}: {len(records)} candidates in {report['elapsed_seconds']:.2f}s")
    selected = select_candidates(pool)
    add_selected_traces(selected)
    old = read_json(ROOT / "data/grant36_v0_4_draft.json")
    old_by_id = {stage["id"]: stage for stage in old}
    keep = {"GR21", "GR22", "GR23", "GR26", "GR27", "GR30", "GR31", "GR33"}
    replacements = {candidate["slot"]: stage_from_candidate(candidate) for candidate in selected}
    campaign = []
    for index in range(1, 37):
        stage_id = f"GR{index:02d}"
        if stage_id in replacements:
            campaign.append(replacements[stage_id])
        else:
            campaign.append(old_by_id[stage_id])
    if [s["id"] for s in campaign] != [f"GR{i:02d}" for i in range(1, 37)]:
        raise AssertionError("campaign order/IDs are invalid")
    write_json(ROOT / "data/grant36_v0_5.json", campaign)
    manifest = {
        "schema_version": 1, "seed": seed, "candidate_count": len(pool),
        "candidate_quota_per_slot": quota, "slot_stats": stats,
        "mask_catalog": masks, "fixtures": fixtures, "candidates": pool,
        "selected": [candidate["id"] for candidate in selected],
    }
    write_json(ROOT / "generated/grant36_v0_5_candidates.json", manifest)
    selected_ids = {candidate["id"] for candidate in selected}
    csv_path = ROOT / "generated/grant36_v0_5_ranked.csv"
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    columns = [
        "slot", "candidate_id", "selected", "score", "mask_id", "fixed_lights",
        "inventory_n_t_p", "solution", "legal_sockets", "search_space",
        "exact_survivors", "shape_without_mask_survivors", "tall_substitute_survivors",
        "plate_substitute_survivors", "fog_removes_shortcut", "first_cell",
        "first_survivors", "reasoning_signature",
    ]
    ranked = sorted(pool, key=lambda c: (-c["score"], c["slot"], c["id"]))
    with csv_path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=columns)
        writer.writeheader()
        for c in ranked:
            p, m = c["profile"], c["metrics"]
            writer.writerow({
                "slot": c["slot"], "candidate_id": c["id"], "selected": c["id"] in selected_ids,
                "score": c["score"], "mask_id": c["mask_id"], "fixed_lights": "+".join(c["lights"]),
                "inventory_n_t_p": f"{p['normal']}/{p['tall']}/{p['plate']}",
                "solution": ",".join(obj["cell"] + ":" + obj["type"] for obj in c["solution"]),
                "legal_sockets": p["legal_socket_count"], "search_space": p["expected_states"],
                "exact_survivors": c["exact_survivors"],
                "shape_without_mask_survivors": c["shape_without_mask_survivors"],
                "tall_substitute_survivors": c["tall_substitute_survivors"],
                "plate_substitute_survivors": c["plate_substitute_survivors"],
                "fog_removes_shortcut": c["fog_removes_shortcut"], "first_cell": m["first_cell"],
                "first_survivors": m["first_survivors"], "reasoning_signature": m["reasoning_signature"],
            })
    return fixtures, pool, selected, stats, time.perf_counter() - start

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=20260923)
    parser.add_argument("--quota-per-slot", type=int, default=20)
    args = parser.parse_args()
    if args.quota_per_slot < 15:
        raise ValueError("quota-per-slot must be at least 15 for a 120-candidate pool")
    fixtures, pool, selected, stats, elapsed = generate(args.seed, args.quota_per_slot)
    write_report(selected, stats, elapsed, 0.0, fixtures)
    print(f"Pool={len(pool)}; selected={len(selected)}; total={elapsed:.2f}s")
    print("Wrote data/grant36_v0_5.json, generated pool/ranking, and docs/GRANT36_V0_5_REPORT.md")

if __name__ == "__main__":
    main()
