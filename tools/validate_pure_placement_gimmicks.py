"""Exhaustive validator for the NOXSUM pure-placement gimmick lab."""
from __future__ import annotations

from collections import defaultdict
from itertools import combinations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/pure_placement_gimmicks_v0_1.json"
ORDER = ("TOP", "LEFT", "RIGHT", "BOTTOM")
DIRECTIONS = {
    "TOP": (0, 1),
    "LEFT": (1, 0),
    "RIGHT": (-1, 0),
    "BOTTOM": (0, -1),
}
FAMILIES = ("FIXED_NOX", "SWITCH", "BLOCKER", "MIRROR")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def cell(code: str) -> int:
    require(len(code) == 2 and code[0] in "ABCDE" and code[1] in "12345", f"invalid cell {code!r}")
    return (int(code[1]) - 1) * 5 + ord(code[0]) - ord("A")


def code(index: int) -> str:
    return chr(ord("A") + index % 5) + str(index // 5 + 1)


def reflect(direction: tuple[int, int], orientation: str) -> tuple[int, int]:
    dx, dy = direction
    require(orientation in ("/", "\\"), f"invalid mirror orientation {orientation!r}")
    return (-dy, -dx) if orientation == "/" else (dy, dx)


def switch_lights(stage: dict, posts: set[int], base_lights: tuple[str, ...]) -> tuple[str, ...]:
    active = set(base_lights)
    for switch in stage.get("placement_switches", []):
        if cell(switch["cell"]) not in posts:
            continue
        for direction in switch.get("off", []):
            active.discard(direction)
        for direction in switch.get("on", []):
            active.add(direction)
    return tuple(direction for direction in ORDER if direction in active)


def edge_starts(light: str):
    dx, dy = DIRECTIONS[light]
    if light == "TOP":
        for x in range(5):
            yield x, 0, dx, dy
    elif light == "BOTTOM":
        for x in range(5):
            yield x, 4, dx, dy
    elif light == "LEFT":
        for y in range(5):
            yield 0, y, dx, dy
    elif light == "RIGHT":
        for y in range(5):
            yield 4, y, dx, dy


def shadow(stage: dict, posts: set[int], base_lights: tuple[str, ...]) -> tuple[int, ...]:
    active_lights = switch_lights(stage, posts, base_lights)
    blockers = {cell(name) for name in stage.get("blockers", [])}
    mirrors = {cell(name): orientation for name, orientation in stage.get("mirrors", {}).items()}

    if not blockers and not mirrors:
        result = [0] * 25
        for index in posts:
            x, y = index % 5, index // 5
            for light in active_lights:
                dx, dy = DIRECTIONS[light]
                tx, ty = x + dx, y + dy
                if 0 <= tx < 5 and 0 <= ty < 5:
                    result[ty * 5 + tx] += 1
        return tuple(result)

    result = [0] * 25
    for light in active_lights:
        for start_x, start_y, start_dx, start_dy in edge_starts(light):
            x, y, dx, dy = start_x, start_y, start_dx, start_dy
            visited: set[tuple[int, int, int, int]] = set()
            while 0 <= x < 5 and 0 <= y < 5:
                state = (x, y, dx, dy)
                if state in visited:
                    break
                visited.add(state)
                index = y * 5 + x
                if index in blockers:
                    break
                if index in mirrors:
                    dx, dy = reflect((dx, dy), mirrors[index])
                    x += dx
                    y += dy
                    continue
                if index in posts:
                    tx, ty = x + dx, y + dy
                    if 0 <= tx < 5 and 0 <= ty < 5:
                        result[ty * 5 + tx] += 1
                x += dx
                y += dy
    return tuple(result)


def target_tuple(stage: dict) -> tuple[int, ...]:
    target = stage["observations"][0]["target"]
    return tuple(int(target.get(code(index), 0)) for index in range(25))


def apparatus_cells(stage: dict) -> set[int]:
    occupied = {cell(name) for name in stage.get("blockers", [])}
    occupied |= {cell(name) for name in stage.get("mirrors", {})}
    return occupied


def worlds(stage: dict):
    fixed = {cell(name) for name in stage.get("fixed_posts", [])}
    legal = set(range(25)) - apparatus_cells(stage)
    require(fixed <= legal, f"{stage['id']}: fixed NOX overlaps apparatus")
    movable_count = int(stage["posts"]) - len(fixed)
    require(movable_count >= 0, f"{stage['id']}: more fixed posts than total posts")
    choices = sorted(legal - fixed)
    for extra in combinations(choices, movable_count):
        yield fixed | set(extra)


def validate_schema(stages: list[dict]) -> None:
    require(len(stages) == 12, f"expected 12 stages, got {len(stages)}")
    ids = [stage["id"] for stage in stages]
    require(ids == [f"PP{i:02d}" for i in range(1, 13)], "PP01-PP12 order changed")
    grouped = defaultdict(list)
    for stage in stages:
        family = stage.get("gimmick_family")
        require(family in FAMILIES, f"{stage['id']}: unknown family {family!r}")
        grouped[family].append(stage["id"])
        require(len(stage.get("observations", [])) == 1, f"{stage['id']}: exactly one observation required")
        require(not stage.get("free_light_selection"), f"{stage['id']}: free light control is forbidden")
        require(not stage.get("movable_shutter"), f"{stage['id']}: movable shutter is forbidden")
        require(int(stage.get("normal_posts", 0)) == int(stage["posts"]), f"{stage['id']}: v0.1 must be SIT-only")
        require(int(stage.get("tall_posts", 0)) == 0, f"{stage['id']}: STAND deferred in v0.1")
        require(int(stage.get("plate_posts", 0)) == 0, f"{stage['id']}: Plate/WARK deferred in v0.1")
        require(set(stage["solution"]) >= set(stage.get("fixed_posts", [])), f"{stage['id']}: fixed trace missing from solution")
        require(not (set(stage["solution"]) & set(stage.get("blockers", []))), f"{stage['id']}: solution overlaps blocker")
        require(not (set(stage["solution"]) & set(stage.get("mirrors", {}))), f"{stage['id']}: solution overlaps mirror")
        for direction in stage["observations"][0]["active_lights"]:
            require(direction in ORDER, f"{stage['id']}: bad light {direction}")
        for switch in stage.get("placement_switches", []):
            cell(switch["cell"])
            for direction in switch.get("on", []) + switch.get("off", []):
                require(direction in ORDER, f"{stage['id']}: bad switch light {direction}")
        for name in stage.get("blockers", []):
            cell(name)
        for name, orientation in stage.get("mirrors", {}).items():
            cell(name)
            require(orientation in ("/", "\\"), f"{stage['id']}: bad mirror orientation")
    require(all(len(grouped[family]) == 3 for family in FAMILIES), f"expected 3 stages per family, got {dict(grouped)}")


def validate_stage(stage: dict) -> tuple[int, set[int]]:
    target = target_tuple(stage)
    base_lights = tuple(stage["observations"][0]["active_lights"])
    survivors: list[set[int]] = []
    count = 0
    for posts in worlds(stage):
        count += 1
        if shadow(stage, posts, base_lights) == target:
            survivors.append(posts)

    expected_states = int(stage["expected_states"])
    require(count == expected_states, f"{stage['id']}: searched {count} states, expected {expected_states}")
    require(len(survivors) == 1, f"{stage['id']}: expected one solution, got {len(survivors)}")
    expected_solution = {cell(name) for name in stage["solution"]}
    require(survivors[0] == expected_solution,
            f"{stage['id']}: survivor {[code(i) for i in sorted(survivors[0])]} != authored solution {stage['solution']}")

    family = stage["gimmick_family"]
    if family == "SWITCH":
        reduced = dict(stage)
        reduced.pop("placement_switches", None)
        require(shadow(reduced, expected_solution, base_lights) != target,
                f"{stage['id']}: switch is not mechanically required by authored solution")
    elif family == "BLOCKER":
        reduced = dict(stage)
        reduced.pop("blockers", None)
        require(shadow(reduced, expected_solution, base_lights) != target,
                f"{stage['id']}: blocker is not mechanically required by authored solution")
    elif family == "MIRROR":
        reduced = dict(stage)
        reduced.pop("mirrors", None)
        require(shadow(reduced, expected_solution, base_lights) != target,
                f"{stage['id']}: mirror is not mechanically required by authored solution")

    return count, survivors[0]


def main() -> None:
    stages = json.loads(DATA.read_text(encoding="utf-8"))
    validate_schema(stages)
    print("NOXSUM pure-placement gimmick validator")
    print("=" * 72)
    for stage in stages:
        states, solution = validate_stage(stage)
        print(f"{stage['id']}  {stage['gimmick_family']:<10}  states={states:4d}  unique  "
              + " ".join(code(index) for index in sorted(solution)))
    print("=" * 72)
    print("12/12 unique; 4 families × 3 stages validated.")


if __name__ == "__main__":
    main()
