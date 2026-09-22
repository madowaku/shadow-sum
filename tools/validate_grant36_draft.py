"""Independent exhaustive GR21-GR36 validator (standard library only).

No generator imports, reverse indexes, cached shadows, or ranking logic. Legal
worlds and ray optics come from the pre-existing GRANT20 reference validator.
Atomic shadows are encoded in carry-free 4-bit lanes to accelerate addition.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import time

from validate_grant20_v03 import cell, code, object_states, light_states, shutter_states, shadow

ROOT = Path(__file__).resolve().parents[1]
KINDS = ("normal", "tall", "plate_v", "plate_h")
CELLS = {code(c) for c in range(25)}


def pack(values):
    return sum(int(value) << (4 * i) for i, value in enumerate(values))


def mask(cells):
    return sum(15 << (4 * cell(c)) for c in set(cells))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def normalized_world(world):
    """Independent translation / horizontal mirror canonicalization for auditing."""
    variants = []
    for sign in (1, -1):
        pts = [(cell(o["cell"]) % 5 if sign == 1 else 4 - cell(o["cell"]) % 5,
                cell(o["cell"]) // 5, o["type"]) for o in world["objects"]]
        x0, y0 = min(p[0] for p in pts), min(p[1] for p in pts)
        lights = tuple(sorted(({"RIGHT": "LEFT", "LEFT": "RIGHT"}.get(v, v) if sign == -1 else v) for v in world["lights"]))
        shutter = world["shutter"]
        if shutter is not None:
            shutter = (4 - shutter if sign == -1 else shutter) - x0
        variants.append((tuple(sorted((x-x0, y-y0, k) for x, y, k in pts)), lights, -99 if shutter is None else shutter))
    return min(variants)


def legal_world(stage, world):
    objects = [(cell(o["cell"]), o["type"]) for o in world["objects"]]
    require(all(o["cell"] in CELLS and o["type"] in KINDS for o in world["objects"]), "invalid object")
    require(len({p for p, _ in objects}) == stage["posts"], "objects must occupy distinct cells")
    kinds = Counter("plate" if k.startswith("plate_") else k for _, k in objects)
    require(all(kinds[k] == stage.get(k + "_posts", 0) for k in ("normal", "tall", "plate")), "inventory mismatch")
    require(len(set(world["lights"])) == len(world["lights"]), "repeated light")
    require(set(world["lights"]) in [set(lights) for lights in light_states(stage)], "illegal lights")
    require(world["shutter"] in shutter_states(stage), "illegal shutter")
    return objects


def stage_world(stage):
    return {"objects": [{"cell": name, "type": stage["solution_post_types"][name]} for name in stage["solution"]],
            "lights": stage.get("solution_lights", stage["observations"][0]["active_lights"]),
            "shutter": stage.get("solution_shutter")}


def validate_stage(stage, candidate=None):
    start = time.perf_counter()
    label = stage["id"]
    require(len(stage["observations"]) == 1, f"{label}: exactly one observation required")
    require(stage.get("review_only") is True, f"{label}: draft must be review-only")
    require(not stage.get("fixed_posts"), f"{label}: unexpected fixed object constraint")
    require(not stage.get("fixed_shutters"), f"{label}: unexpected fixed shutter constraint")
    require(1 <= stage["posts"] <= 4, f"{label}: nibble encoding supports <=4 objects")
    require(set(stage["solution_post_types"]) == set(stage["solution"]), f"{label}: incomplete type metadata")
    require(set(stage.get("solution_tall", [])) == {c for c, k in stage["solution_post_types"].items() if k == "tall"}, f"{label}: tall metadata")
    fog = stage.get("fog_cells", [])
    require(len(fog) == len(set(fog)) and set(fog) <= CELLS, f"{label}: invalid fog cells")
    require(not fog or 3 <= len(fog) <= 6, f"{label}: fog must hide 3–6 cells")
    target = stage["observations"][0]["target"]
    require(set(target) == CELLS - set(fog), f"{label}: explicitly encode every observed zero, omit fog")
    require(all(type(v) is int and 0 <= v <= stage["posts"] for v in target.values()), f"{label}: invalid intensity")
    visible_mask = mask(target)
    wanted = sum(v << (4 * cell(c)) for c, v in target.items())
    authored = stage_world(stage)
    objects = legal_world(stage, authored)
    if "generator_profile" in stage:
        profile = stage["generator_profile"]
        require(all(stage[k + "_posts"] == profile[k] for k in ("normal", "tall", "plate")), f"{label}: profile inventory mismatch")
        require(stage.get("active_light_count", 0) == profile["light_count"], f"{label}: profile light count mismatch")
        require(bool(stage.get("free_light_selection")) == bool(profile["light_count"]), f"{label}: profile light freedom mismatch")
        require(bool(stage.get("movable_shutter")) == profile["shutter"], f"{label}: profile shutter mismatch")
        require(not profile["plate"] or stage.get("rotatable_plate"), f"{label}: plate must rotate")
        require(stage["expected_states"] == profile["expected_states"], f"{label}: profile state count mismatch")
        if not profile["light_count"]:
            require(stage["observations"][0]["active_lights"] == profile["fixed_lights"], f"{label}: profile fixed lights mismatch")
    authored_shadow = shadow(objects, authored["lights"], authored["shutter"])
    require(list(authored_shadow) == stage["solution_complete_shadow"], f"{label}: complete shadow metadata mismatch")
    require((pack(authored_shadow) & visible_mask) == wanted, f"{label}: authored world violates visible target")
    if fog:
        require(any(authored_shadow[cell(c)] > 0 for c in fog), f"{label}: fog needs an actual nonzero hidden clue")
        # Explicit regression guard: defaulting missing target entries to zero rejects this valid authored world.
        require(pack(authored_shadow) != wanted, f"{label}: unknown-vs-zero guard not exercised")

    trace = candidate["metrics"]["witness_trace"] if candidate else []
    trace_masks = []
    trace_counts = [0] * len(trace)
    running = 0
    for step in trace:
        require(step["cell"] in target and target[step["cell"]] == step["value"], f"{label}: invalid witness clue")
        running |= mask([step["cell"]])
        trace_masks.append(running)

    # Separate reference ray computation; not the generator's vector tables.
    configs = [(lights, shutter) for lights in light_states(stage) for shutter in shutter_states(stage)]
    tables = [{(pos, kind): pack(shadow(((pos, kind),), lights, shutter))
               for pos in range(25) for kind in KINDS} for lights, shutter in configs]
    state_count, solution_count, found = 0, 0, None
    for legal_objects in object_states(stage):
        # Pre-existing combination enumerator treats same-type copies as indistinguishable.
        for (lights, shutter), table in zip(configs, tables):
            encoded = sum(table[obj] for obj in legal_objects)
            state_count += 1
            difference = (encoded ^ wanted) & visible_mask
            if difference == 0:
                solution_count += 1
                found = (legal_objects, lights, shutter)
            for i, prefix in enumerate(trace_masks):
                if difference & prefix:
                    break
                trace_counts[i] += 1
    require(state_count == stage["expected_states"], f"{label}: enumerated {state_count}, expected {stage['expected_states']}")
    require(solution_count == 1, f"{label}: expected one solution, got {solution_count}")
    found_objects, found_lights, found_shutter = found
    require(sorted(found_objects) == sorted(objects) and set(found_lights) == set(authored["lights"])
            and found_shutter == authored["shutter"], f"{label}: unique solution differs from metadata")
    if candidate:
        require(trace_counts == [s["survivors"] for s in trace], f"{label}: witness counts disagree: {trace_counts}")
        require(candidate["solution"] == authored, f"{label}: pool / draft solution mismatch")
        require(candidate["complete_shadow"] == list(authored_shadow), f"{label}: pool complete shadow mismatch")
        require(candidate["fog_cells"] == fog, f"{label}: pool fog mismatch")
        require(candidate["visible_mask"] == [code(i) not in fog for i in range(25)], f"{label}: visibility mask mismatch")
        require(candidate["profile"] == stage["generator_profile"], f"{label}: profile metadata mismatch")
        require(candidate["metrics"]["legal_world_states"] == state_count, f"{label}: pool state count mismatch")
        for near in candidate["near_miss_worlds"]:
            near_objects = legal_world(stage, near["world"])
            near_shadow = shadow(near_objects, near["world"]["lights"], near["world"]["shutter"])
            errors = [{"cell": code(c), "target": target[code(c)], "actual": near_shadow[c]}
                      for c in range(25) if code(c) in target and near_shadow[c] != target[code(c)]]
            require(errors == near["rejected_by"] and len(errors) == near["visible_hamming_distance"] > 0, f"{label}: invalid near-miss rejection")
    return {"id": label, "states": state_count, "solution_count": solution_count,
            "visible_cells": len(target), "fog_cells": fog, "witness_survivors": trace_counts,
            "fog_unknown_not_zero_exercised": bool(fog), "seconds": round(time.perf_counter() - start, 3)}


def audit_pool(pool, stages):
    candidates = pool["candidates"]
    require(len(candidates) >= 150, "fewer than 150 pool candidates")
    require(len({c["id"] for c in candidates}) == len(candidates), "duplicate candidate IDs")
    require(len({normalized_world(c["solution"]) for c in candidates}) == len(candidates), "translated/mirrored duplicate in pool")
    counts = Counter(c["profile"]["bucket"] for c in candidates)
    require(all(counts[b] >= 20 for b in ("two", "three", "fog", "dense", "finale")), "bucket below 20")
    require(dict(counts) == pool["bucket_counts"], "bucket metadata mismatch")
    by_id = {c["id"]: c for c in candidates}
    selected = [by_id[s["generator_candidate_id"]] for s in stages]
    require(len({c["id"] for c in selected}) == 16, "duplicate selection")
    require([c["candidate_id"] for c in pool["selection"]] == [c["id"] for c in selected], "selection provenance mismatch")
    expected_buckets = ["two"] * 4 + ["three"] * 4 + ["fog"] * 4 + ["dense"] * 3 + ["finale"]
    require([c["profile"]["bucket"] for c in selected] == expected_buckets, "wrong stage buckets")
    for c in candidates:
        p = c["profile"]
        families = (["HEIGHT"] if p["tall"] else []) + (["PLATE"] if p["plate"] else []) + (["LIGHT"] if p["light_count"] else []) + (["SHUTTER"] if p["shutter"] else [])
        require(families == p["families"], f"{c['id']}: incorrect family declaration")
        require(p["bucket"] not in ("two", "three") or len(families) == (2 if p["bucket"] == "two" else 3), "incorrect cause count")
        require(p["bucket"] != "dense" or (3 <= len(families) <= 4 and 3 <= p["normal"] + p["tall"] + p["plate"] <= 4), "incorrect dense inventory")
        require(c["unique_solution_count"] == 1, "pool uniqueness flag")
        require(c["seed"] == pool["seed"], "seed mismatch")
        objects = [(cell(o["cell"]), o["type"]) for o in c["solution"]["objects"]]
        require(list(shadow(objects, c["solution"]["lights"], c["solution"]["shutter"])) == c["complete_shadow"], "pool reference optical mismatch")
    for a, b in zip(selected, selected[1:]):
        require((a["profile"]["families"], a["reasoning_signature"]) != (b["profile"]["families"], b["reasoning_signature"]), "repeated adjacent signature")
    require(sum(bool(c["profile"]["tall"] or c["profile"]["plate"]) for c in selected[8:12]) >= 2, "fog needs object properties")
    require(any(c["profile"]["light_count"] or c["profile"]["shutter"] for c in selected[8:12]), "fog needs uncertain apparatus")
    return selected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--draft", type=Path, default=ROOT / "data/grant36_v0_4_draft.json")
    parser.add_argument("--pool", type=Path, default=ROOT / "generated/grant36_candidates.json")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    start = time.perf_counter()
    draft = json.loads(args.draft.read_text(encoding="utf-8"))
    source = ROOT / "data/grant20_v0_3.json"
    old = json.loads(source.read_text(encoding="utf-8"))
    require(draft[:20] == old, "GR01–GR20 changed")
    require([s["id"] for s in draft] == [f"GR{i:02}" for i in range(1, 37)], "stage IDs/order")
    pool = json.loads(args.pool.read_text(encoding="utf-8"))
    # The parsed GR01-GR20 equality check above is authoritative. The stored raw
    # source hash is provenance only: Git can change LF/CRLF bytes on checkout.
    selected = audit_pool(pool, draft[20:])
    results = []
    for stage, candidate in zip(draft[20:], selected):
        result = validate_stage(stage, candidate)
        results.append(result)
        print(f"{result['id']}: states={result['states']:,}, unique={result['solution_count']}, visible={result['visible_cells']}, {result['seconds']:.3f}s", flush=True)
    report = {"validator": "independent GRANT20 reference rays + exhaustive combinations + carry-free 4-bit lanes",
              "draft_sha256": hashlib.sha256(args.draft.read_bytes()).hexdigest(),
              "stages": results, "total_states": sum(r["states"] for r in results),
              "total_seconds": round(time.perf_counter() - start, 3), "all_passed": True}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: 16/16, {report['total_states']:,} worlds, {report['total_seconds']:.3f}s", flush=True)


if __name__ == "__main__":
    main()
