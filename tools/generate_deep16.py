"""Generate and rank the GR21-GR36 deep-puzzle candidate pool.

The generator enumerates ten mechanical families, keeps only exact one-solution
targets, ranks them with a deterministic structural score, and keeps the top
16 distinct candidates from each family: 160 candidates total.

The committed GR21-GR36 set is then checked against that pool. Four FROST
stages are projection variants: hidden cells are ignored while uniqueness is
re-tested against the full family state space.
"""
from __future__ import annotations

import itertools
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/grant36_v0_4.json"
DIRS = ("TOP", "LEFT", "RIGHT", "BOTTOM")
VECTORS = {"TOP": (0, 1), "LEFT": (1, 0), "RIGHT": (-1, 0), "BOTTOM": (0, -1)}

FAMILIES = {
    "LT2": ({"normal": 1, "tall": 1, "plate": 0}, 2, False),
    "LP_S": ({"normal": 1, "tall": 0, "plate": 1}, 4, True),
    "PP": ({"normal": 0, "tall": 0, "plate": 2}, 4, False),
    "TP": ({"normal": 0, "tall": 1, "plate": 1}, 4, False),
    "NN_L3S": ({"normal": 2, "tall": 0, "plate": 0}, 3, True),
    "NTP": ({"normal": 1, "tall": 1, "plate": 1}, 4, False),
    "NNN": ({"normal": 3, "tall": 0, "plate": 0}, 3, False),
    "NTP_L3": ({"normal": 1, "tall": 1, "plate": 1}, 3, False),
    "NTP_S": ({"normal": 1, "tall": 1, "plate": 1}, 4, True),
    "NTP_L3S": ({"normal": 1, "tall": 1, "plate": 1}, 3, True),
}

# The selected non-frost stages deliberately cover different reasoning signatures.
SELECTED_FAMILY = {
    "GR21": "NNN",
    "GR22": "LT2",
    "GR23": "PP",
    "GR24": "LP_S",
    "GR25": "TP",
    "GR26": "NN_L3S",
    "GR27": "NTP",
    "GR28": "NTP_L3",
    "GR33": "NTP_S",
    "GR34": "NTP_L3",
    "GR35": "NTP_S",
    "GR36": "NTP_L3S",
}

FROST_FAMILY = {
    "GR29": "NNN",
    "GR30": "LT2",
    "GR31": "LP_S",
    "GR32": "NN_L3S",
}


def cell(code: str) -> int:
    return (int(code[1:]) - 1) * 5 + ord(code[0]) - 65


def code(index: int) -> str:
    return chr(65 + index % 5) + str(index // 5 + 1)


def shadow(objects, lights, shutter=None):
    result = [0] * 25
    for index, kind in objects:
        x, y = index % 5, index // 5
        reach = 2 if kind == "tall" else 1
        for light in lights:
            if light == "TOP" and shutter is not None and x == shutter:
                continue
            if kind == "plate_v" and light not in ("LEFT", "RIGHT"):
                continue
            if kind == "plate_h" and light not in ("TOP", "BOTTOM"):
                continue
            dx, dy = VECTORS[light]
            for distance in range(1, reach + 1):
                tx, ty = x + dx * distance, y + dy * distance
                if 0 <= tx < 5 and 0 <= ty < 5:
                    result[ty * 5 + tx] += 1
    return tuple(result)


def object_states(counts):
    cells = range(25)
    for normals in itertools.combinations(cells, counts["normal"]):
        rem1 = [i for i in cells if i not in normals]
        for talls in itertools.combinations(rem1, counts["tall"]):
            rem2 = [i for i in rem1 if i not in talls]
            for plates in itertools.combinations(rem2, counts["plate"]):
                orientations = itertools.product(("plate_v", "plate_h"), repeat=len(plates))
                if not plates:
                    orientations = [()]
                for orient in orientations:
                    yield tuple(
                        [(i, "normal") for i in normals]
                        + [(i, "tall") for i in talls]
                        + [(i, kind) for i, kind in zip(plates, orient)]
                    )


def state_space(name):
    counts, light_count, movable_shutter = FAMILIES[name]
    lights = list(itertools.combinations(DIRS, light_count)) if light_count < 4 else [DIRS]
    shutters = range(5) if movable_shutter else [None]
    for objects in object_states(counts):
        for active in lights:
            for shutter in shutters:
                yield objects, tuple(active), shutter


def metrics(target):
    nonzero = [value for value in target if value]
    return {
        "lit": len(nonzero),
        "overlaps": sum(value >= 2 for value in nonzero),
        "max": max(nonzero, default=0),
        "mass": sum(nonzero),
    }


def score(target, state):
    m = metrics(target)
    result = 100
    result -= abs(m["lit"] - 8) * 4
    result -= abs(m["overlaps"] - 2) * 5
    result -= abs(m["mass"] - 11) * 2
    result += len(set(target)) * 2
    edge_objects = sum(
        index % 5 in (0, 4) or index // 5 in (0, 4)
        for index, _kind in state[0]
    )
    return result - edge_objects * 2


def candidate_pool():
    pool = []
    all_states = {}
    for family in FAMILIES:
        groups = defaultdict(list)
        states = []
        for state in state_space(family):
            target = shadow(*state)
            groups[target].append(state)
            states.append((state, target))
        all_states[family] = states

        unique = [(target, states[0]) for target, states in groups.items() if len(states) == 1]
        unique.sort(key=lambda item: (score(item[0], item[1]), item[0]), reverse=True)

        picked = []
        signatures = set()
        for target, state in unique:
            positions = tuple(sorted(index for index, _kind in state[0]))
            m = metrics(target)
            signature = (positions, m["lit"], m["overlaps"], m["max"])
            if signature in signatures:
                continue
            signatures.add(signature)
            picked.append(
                {
                    "family": family,
                    "score": score(target, state),
                    "objects": [(code(index), kind) for index, kind in state[0]],
                    "lights": list(state[1]),
                    "shutter": state[2],
                    "metrics": m,
                }
            )
            if len(picked) == 16:
                break
        assert len(picked) == 16, family
        pool.extend(picked)
    assert len(pool) == 160
    return pool, all_states


def stage_state(stage):
    types = stage.get("solution_post_types", {})
    tall = set(stage.get("solution_tall", []))
    objects = []
    for name in stage["solution"]:
        kind = types.get(name, "tall" if name in tall or stage.get("tall") else "normal")
        objects.append((cell(name), kind))
    lights = tuple(stage.get("solution_lights", stage["observations"][0]["active_lights"]))
    shutter = stage.get("solution_shutter")
    if shutter is None and stage.get("fixed_shutters"):
        shutter = int(stage["fixed_shutters"][0])
    return tuple(objects), lights, shutter


def target_tuple(stage):
    values = [0] * 25
    for name, value in stage["observations"][0]["target"].items():
        values[cell(name)] = int(value)
    return tuple(values)


def visible_unique(stage, states):
    wanted = target_tuple(stage)
    hidden = {cell(name) for name in stage["observations"][0].get("hidden_cells", [])}
    visible = [i for i in range(25) if i not in hidden]
    matches = [
        state for state, actual in states
        if all(actual[i] == wanted[i] for i in visible)
    ]
    return matches


def main():
    pool, all_states = candidate_pool()
    stages = {stage["id"]: stage for stage in json.loads(DATA.read_text(encoding="utf-8"))}

    print("DEEP16 GENERATOR v0.4")
    print("=" * 72)
    print(f"Candidate pool: {len(pool)} exact-unique puzzles across {len(FAMILIES)} families")
    for family in FAMILIES:
        print(f"  {family:9s}: 16 ranked candidates")

    print("\nSelected GR21-GR36:")
    for stage_id in [f"GR{i:02}" for i in range(21, 37)]:
        stage = stages[stage_id]
        family = SELECTED_FAMILY.get(stage_id) or FROST_FAMILY[stage_id]
        state = stage_state(stage)
        expected_target = target_tuple(stage)
        assert shadow(*state) == expected_target, (stage_id, "solution target mismatch")

        matches = visible_unique(stage, all_states[family])
        assert len(matches) == 1, (stage_id, family, len(matches))
        assert matches[0] == state, (stage_id, "unique state differs")

        hidden = stage["observations"][0].get("hidden_cells", [])
        tag = f" frost={len(hidden)}" if hidden else ""
        print(
            f"  {stage_id} {stage['title']:<18s} family={family:<8s} "
            f"states={stage['expected_states']}{tag}"
        )

    print("\nSelection check: 16/16 unique, including 4 frosted projections.")


if __name__ == "__main__":
    main()
