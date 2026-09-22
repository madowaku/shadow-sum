"""Exhaustive validator for LC01-LC04 and TP01-TP04."""
import itertools
import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data/light_height_lc01_tp04_v0_1.json"
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


def shadow(posts, lights, tall_posts=()):
    result = [0] * 25
    tall = set(tall_posts)
    for index in posts:
        x, y = index % 5, index // 5
        reach = 2 if index in tall else 1
        for light in lights:
            dx, dy = VECTORS[light]
            for distance in range(1, reach + 1):
                tx, ty = x + dx * distance, y + dy * distance
                if 0 <= tx < 5 and 0 <= ty < 5:
                    result[ty * 5 + tx] += 1
    return result


def light_sets(stage):
    if not stage.get("free_light_selection"):
        return [tuple(stage["observations"][0]["active_lights"])]
    if "active_light_count" in stage:
        return list(itertools.combinations(stage["installed_lights"], int(stage["active_light_count"])))
    return [
        combo
        for count in range(1, len(stage["installed_lights"]) + 1)
        for combo in itertools.combinations(stage["installed_lights"], count)
    ]


def post_states(stage):
    if "fixed_posts" in stage:
        posts = tuple(map(cell, stage["fixed_posts"]))
        tall = tuple(map(cell, stage.get("fixed_tall_posts", [])))
        if stage.get("tall"):
            tall = posts
        return [(posts, tall)]

    if stage.get("tall"):
        return [(combo, combo) for combo in itertools.combinations(range(25), int(stage["posts"]))]

    if "normal_posts" in stage or "tall_posts" in stage:
        tall_count = int(stage.get("tall_posts", 0))
        normal_count = int(stage.get("normal_posts", 0))
        states = []
        for tall in itertools.combinations(range(25), tall_count):
            remaining = [index for index in range(25) if index not in tall]
            for normal in itertools.combinations(remaining, normal_count):
                states.append((tuple(tall) + tuple(normal), tuple(tall)))
        return states

    return [(combo, tuple()) for combo in itertools.combinations(range(25), int(stage["posts"]))]


def validate():
    stages = json.loads(DATA.read_text(encoding="utf-8"))
    assert [s["id"] for s in stages] == ["LC01", "LC02", "LC03", "LC04", "TP01", "TP02", "TP03", "TP04"]

    for stage in stages:
        wanted = target(stage["observations"][0]["target"])
        solutions = []
        states = 0
        for posts, tall in post_states(stage):
            for lights in light_sets(stage):
                states += 1
                if shadow(posts, lights, tall) == wanted:
                    solutions.append((posts, tall, lights))

        assert states == int(stage["expected_states"]), (stage["id"], states, stage["expected_states"])
        assert len(solutions) == 1, (stage["id"], len(solutions), solutions[:10])

        posts, tall, lights = solutions[0]
        assert set(posts) == set(map(cell, stage["solution"])), (stage["id"], posts)
        assert set(tall) == set(map(cell, stage.get("solution_tall", []))), (stage["id"], tall)
        if stage.get("free_light_selection"):
            assert set(lights) == set(stage["solution_lights"]), (stage["id"], lights)

        print(f'{stage["id"]}: states={states}, unique=1, lights={"+".join(lights)}')


if __name__ == "__main__":
    validate()
