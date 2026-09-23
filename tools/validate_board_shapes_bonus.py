"""Independent exact-world check for the optional board-shapes bonus stage."""
from __future__ import annotations

import copy
import json
from pathlib import Path

from validate_grant20_v03 import cell, legal_positions, object_states, shadow
from validate_grant36_v05 import (
    enumerate_stages,
    normalized_solution,
    reduced_stage,
    require,
    typed_inventory_exact,
)

ROOT = Path(__file__).resolve().parents[1]
BONUS = ROOT / "data/grant36_v0_5_bonus.json"
POOL = ROOT / "generated/grant36_v0_5_candidates.json"
CAMPAIGN = ROOT / "data/grant36_v0_5.json"


def matching_worlds(stage: dict) -> list[tuple]:
    observation = stage["observations"][0]
    lights = observation["active_lights"]
    visible = {cell(name): int(value) for name, value in observation["target"].items()}
    matches = []
    for objects in object_states(stage):
        values = shadow(objects, lights)
        if all(values[index] == value for index, value in visible.items()):
            matches.append(objects)
    return matches


def main() -> None:
    stages = json.loads(BONUS.read_text(encoding="utf-8"))
    require(len(stages) == 1 and stages[0]["id"] == "BS01", "bonus must contain only BS01")
    stage = stages[0]
    campaign = json.loads(CAMPAIGN.read_text(encoding="utf-8"))
    require(len(campaign) == 36 and not any(item["id"] == "BS01" for item in campaign),
            "bonus must remain separate from the 36-stage campaign")
    manifest = json.loads(POOL.read_text(encoding="utf-8"))
    candidate = next(item for item in manifest["candidates"] if item["id"] == stage["source_candidate"])
    require(stage["boardShape"]["mask"] == candidate["boardShape"]["mask"], "bonus mask drifted")
    require(stage["solution_post_types"] == candidate["solution_post_types"], "bonus solution drifted")
    require(stage["observations"][0]["target"] == candidate["target"], "bonus target drifted")
    require(stage["observations"][0]["active_lights"] == candidate["lights"], "bonus lights drifted")
    require(typed_inventory_exact(stage), "bonus typed inventory mismatch")
    require(len(stage["observations"][0]["target"]) == 25, "bonus must show all 25 shadow cells")
    require(not stage.get("free_light_selection") and not stage.get("movable_shutter"),
            "bonus must be a board deduction")

    counts, spaces = enumerate_stages([stage])
    require(counts["BS01"] == 1 and spaces["BS01"] == 858, "bonus is not exact unique on 858 worlds")
    unrestricted = copy.deepcopy(stage)
    unrestricted.pop("boardShape")
    unrestricted["id"] = "BS01-NO-SHAPE"
    unrestricted["expected_states"] = 0
    no_shape_counts, no_shape_spaces = enumerate_stages([unrestricted], require_unique=False)
    require(no_shape_counts[unrestricted["id"]] == 3 and no_shape_spaces[unrestricted["id"]] == 6900,
            "the board shape no longer excludes two optical alternatives")
    no_tall = reduced_stage(stage, "tall")
    no_tall["id"] = "BS01-NO-TALL"
    reduced_counts, _ = enumerate_stages([no_tall], require_unique=False)
    require(reduced_counts[no_tall["id"]] == 0, "Tall is not necessary for the bonus target")

    legal = set(legal_positions(stage))
    worlds = matching_worlds(unrestricted)
    valid = [world for world in worlds if all(position in legal for position, _ in world)]
    require(len(valid) == 1 and tuple(sorted(valid[0])) == normalized_solution(stage),
            "the authored solution is not the sole legal matching world")
    excluded = [world for world in worlds if world not in valid]
    require(len(excluded) == 2 and all(any(position not in legal for position, _ in world) for world in excluded),
            "two alternative worlds must be rejected by absent sockets")
    print("BS01: 858 legal worlds -> 1 solution; full board: 6900 worlds -> 3 solutions; no Tall: 0")
    print("Two optical alternatives require missing sockets, so the silhouette supplies the decisive clue.")


if __name__ == "__main__":
    main()
