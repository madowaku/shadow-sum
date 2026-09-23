"""Exhaustive independent validator for SHADOW SUM GRANT20 v0.3."""
import itertools
import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data/grant20_v0_3.json"

DIRECTIONS = ("TOP", "LEFT", "RIGHT", "BOTTOM")
VECTORS = {
    "TOP": (0, 1),
    "LEFT": (1, 0),
    "RIGHT": (-1, 0),
    "BOTTOM": (0, -1),
}


def cell(code: str) -> int:
    return (int(code[1:]) - 1) * 5 + ord(code[0]) - 65


def code(index: int) -> str:
    return chr(65 + index % 5) + str(index // 5 + 1)


def target(values: dict) -> tuple[int, ...]:
    result = [0] * 25
    for name, value in values.items():
        result[cell(name)] = int(value)
    return tuple(result)


def shadow(objects, lights, shutter=None) -> tuple[int, ...]:
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
                tx = x + dx * distance
                ty = y + dy * distance
                if 0 <= tx < 5 and 0 <= ty < 5:
                    result[ty * 5 + tx] += 1
    return tuple(result)


def fixed_variants(stage):
    fixed_codes = stage.get("fixed_posts", [])
    if not fixed_codes:
        return [tuple()]

    choices = []
    declared = stage.get("fixed_post_types", {})
    for name in fixed_codes:
        kind = declared.get(name, "tall" if stage.get("tall") else "normal")
        if stage.get("rotatable_plate") and str(kind).startswith("plate_"):
            choices.append(((cell(name), "plate_v"), (cell(name), "plate_h")))
        else:
            choices.append(((cell(name), str(kind)),))
    return [tuple(items) for items in itertools.product(*choices)]


def category(kind: str) -> str:
    if kind in ("plate_v", "plate_h"):
        return "plate"
    if kind in ("normal", "tall"):
        return kind
    raise ValueError(f"unknown post type: {kind}")


def legal_positions(stage):
    if "boardShape" not in stage:
        return tuple(range(25))
    board_shape = stage["boardShape"]
    if not isinstance(board_shape, dict) or not isinstance(board_shape.get("mask"), list):
        raise ValueError("boardShape.mask must be a 5-row array")
    rows = board_shape["mask"]
    if len(rows) != 5:
        raise ValueError("boardShape.mask must have exactly five rows")
    result = []
    for row_index, row in enumerate(rows):
        if not isinstance(row, str) or len(row) != 5 or any(char not in "01" for char in row):
            raise ValueError("boardShape.mask rows must be exactly five 0/1 characters")
        result.extend(row_index * 5 + column for column, char in enumerate(row) if char == "1")
    return tuple(result)


def object_states(stage):
    wanted_total = int(stage["posts"])
    allowed = legal_positions(stage)
    allowed_set = set(allowed)
    for fixed in fixed_variants(stage):
        if any(index not in allowed_set for index, _ in fixed) or len({index for index, _ in fixed}) != len(fixed):
            continue
        used = {index for index, _ in fixed}
        fixed_counts = {"normal": 0, "tall": 0, "plate": 0}
        for _, kind in fixed:
            fixed_counts[category(kind)] += 1

        if any(key in stage for key in ("normal_posts", "tall_posts", "plate_posts")):
            requested = {
                "normal": int(stage.get("normal_posts", 0)),
                "tall": int(stage.get("tall_posts", 0)),
                "plate": int(stage.get("plate_posts", 0)),
            }
        elif stage.get("tall"):
            requested = {"normal": 0, "tall": wanted_total, "plate": 0}
        else:
            # Fixed special objects count toward the total even when the stage
            # does not declare an explicit inventory mix (GR11 fixed plate).
            requested = dict(fixed_counts)
            requested["normal"] += wanted_total - len(fixed)

        remaining_counts = {name: requested[name] - fixed_counts[name] for name in requested}
        if any(value < 0 for value in remaining_counts.values()):
            continue

        available = [index for index in allowed if index not in used]
        normal_count = remaining_counts["normal"]
        tall_count = remaining_counts["tall"]
        plate_count = remaining_counts["plate"]

        for normals in itertools.combinations(available, normal_count):
            after_normal = [i for i in available if i not in normals]
            for talls in itertools.combinations(after_normal, tall_count):
                after_tall = [i for i in after_normal if i not in talls]
                for plates in itertools.combinations(after_tall, plate_count):
                    base = list(fixed)
                    base.extend((i, "normal") for i in normals)
                    base.extend((i, "tall") for i in talls)
                    if plate_count == 0:
                        yield tuple(base)
                        continue
                    for orientations in itertools.product(("plate_v", "plate_h"), repeat=plate_count):
                        objects = list(base)
                        objects.extend((i, kind) for i, kind in zip(plates, orientations))
                        yield tuple(objects)


def light_states(stage):
    if not stage.get("free_light_selection"):
        return [tuple(stage["observations"][0]["active_lights"])]
    installed = tuple(stage["installed_lights"])
    if "active_light_count" in stage:
        return list(itertools.combinations(installed, int(stage["active_light_count"])))
    return [
        combo
        for count in range(1, len(installed) + 1)
        for combo in itertools.combinations(installed, count)
    ]


def shutter_states(stage):
    if stage.get("movable_shutter"):
        return list(range(5))
    fixed = stage.get("fixed_shutters", [])
    return [int(fixed[0]) if fixed else None]


def validate_solution_metadata(stage, objects, lights, shutter):
    assert {index for index, _ in objects} == set(map(cell, stage["solution"])), (stage["id"], objects)
    expected_types = stage.get("solution_post_types", {})
    for name, kind in expected_types.items():
        assert (cell(name), kind) in objects, (stage["id"], name, kind, objects)
    if stage.get("solution_tall"):
        for name in stage["solution_tall"]:
            assert (cell(name), "tall") in objects, (stage["id"], name, objects)
    if stage.get("free_light_selection"):
        assert set(lights) == set(stage["solution_lights"]), (stage["id"], lights)
    if stage.get("movable_shutter"):
        assert shutter == int(stage["solution_shutter"]), (stage["id"], shutter)


def validate():
    stages = json.loads(DATA.read_text(encoding="utf-8"))
    assert [s["id"] for s in stages] == [f"GR{i:02}" for i in range(1, 21)]

    for stage in stages:
        wanted = target(stage["observations"][0]["target"])
        solutions = []
        states = 0

        for objects in object_states(stage):
            for lights in light_states(stage):
                for shutter in shutter_states(stage):
                    states += 1
                    if shadow(objects, lights, shutter) == wanted:
                        solutions.append((objects, lights, shutter))

        expected_states = int(stage["expected_states"])
        assert states == expected_states, (stage["id"], states, expected_states)
        assert len(solutions) == 1, (stage["id"], len(solutions), solutions[:10])

        objects, lights, shutter = solutions[0]
        validate_solution_metadata(stage, objects, lights, shutter)

        readable = ",".join(f"{code(i)}:{kind}" for i, kind in objects)
        shutter_text = "-" if shutter is None else chr(65 + shutter)
        print(
            f'{stage["id"]}: states={states}, unique=1, '
            f'objects={readable}, lights={"+".join(lights)}, shutter={shutter_text}'
        )


if __name__ == "__main__":
    validate()
