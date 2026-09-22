"""Exhaustive validator for P01-P04 Flat Plate experiments."""
import itertools
import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data/flat_plate_p01_p04_v0_1.json"
DIRECTIONS = ("TOP", "LEFT", "RIGHT", "BOTTOM")
VECTORS = {
    "TOP": (0, 1),
    "LEFT": (1, 0),
    "RIGHT": (-1, 0),
    "BOTTOM": (0, -1),
}


def cell(code: str) -> int:
    return (int(code[1:]) - 1) * 5 + ord(code[0]) - 65


def target(values: dict) -> list[int]:
    result = [0] * 25
    for code, value in values.items():
        result[cell(code)] = int(value)
    return result


def shadow(objects, lights):
    result = [0] * 25
    for index, kind in objects:
        x, y = index % 5, index // 5
        allowed = DIRECTIONS
        if kind == "plate_v":
            allowed = ("LEFT", "RIGHT")
        elif kind == "plate_h":
            allowed = ("TOP", "BOTTOM")
        for light in lights:
            if light not in allowed:
                continue
            dx, dy = VECTORS[light]
            tx, ty = x + dx, y + dy
            if 0 <= tx < 5 and 0 <= ty < 5:
                result[ty * 5 + tx] += 1
    return result


def validate():
    stages = json.loads(DATA.read_text(encoding="utf-8"))
    assert [stage["id"] for stage in stages] == ["P01", "P02", "P03", "P04"]

    for stage in stages:
        wanted = target(stage["observations"][0]["target"])
        solutions = []
        states = 0

        if stage["id"] == "P01":
            fixed = cell("C3")
            object_states = [((fixed, kind),) for kind in ("plate_v", "plate_h")]
            light_states = [tuple(DIRECTIONS)]
        elif stage["id"] == "P02":
            object_states = [
                ((index, kind),)
                for index in range(25)
                for kind in ("plate_v", "plate_h")
            ]
            light_states = [tuple(DIRECTIONS)]
        elif stage["id"] == "P03":
            object_states = [
                ((normal, "normal"), (plate, kind))
                for normal in range(25)
                for plate in range(25)
                if plate != normal
                for kind in ("plate_v", "plate_h")
            ]
            light_states = [tuple(DIRECTIONS)]
        else:
            fixed = cell("C3")
            object_states = [
                ((fixed, "normal"), (plate, kind))
                for plate in range(25)
                if plate != fixed
                for kind in ("plate_v", "plate_h")
            ]
            light_states = list(itertools.combinations(DIRECTIONS, 3))

        for objects in object_states:
            for lights in light_states:
                states += 1
                if shadow(objects, lights) == wanted:
                    solutions.append((objects, lights))

        assert states == int(stage["expected_states"]), (stage["id"], states, stage["expected_states"])
        assert len(solutions) == 1, (stage["id"], len(solutions), solutions[:10])

        objects, lights = solutions[0]
        expected_positions = set(map(cell, stage["solution"]))
        assert {index for index, _ in objects} == expected_positions, (stage["id"], objects)
        for code, kind in stage["solution_post_types"].items():
            assert (cell(code), kind) in objects, (stage["id"], code, kind, objects)
        if stage.get("free_light_selection"):
            assert set(lights) == set(stage["solution_lights"]), (stage["id"], lights)

        print(f'{stage["id"]}: states={states}, unique=1, lights={"+".join(lights)}')


if __name__ == "__main__":
    validate()
