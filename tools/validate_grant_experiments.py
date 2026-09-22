"""Independent exhaustive oracle. All unspecified target cells are visible zero."""
import itertools
import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data/grant_experiments_v0_1.json"
DIRECTIONS = {"TOP": (0, 1), "LEFT": (1, 0), "RIGHT": (-1, 0), "BOTTOM": (0, -1)}


def cell(code):
    assert len(code) == 2 and code[0] in "ABCDE" and code[1] in "12345", code
    return (int(code[1]) - 1) * 5 + ord(code[0]) - 65


def shadow(posts, lights, shutters=(), tall=False):
    values = [0] * 25
    for post in posts:
        x, y = post % 5, post // 5
        for light in lights:
            if light == "TOP" and x in shutters:
                continue
            dx, dy = DIRECTIONS[light]
            for distance in range(1, 3 if tall else 2):
                tx, ty = x + dx * distance, y + dy * distance
                if 0 <= tx < 5 and 0 <= ty < 5:
                    values[ty * 5 + tx] += 1
    return values


def target(observation):
    values = [0] * 25
    for code, value in observation["target"].items():
        assert isinstance(value, int) and value >= 0
        values[cell(code)] = value
    return values


def candidates(stage):
    placements = [tuple(map(cell, stage["fixed_posts"]))] if "fixed_posts" in stage else itertools.combinations(range(25), stage["posts"])
    shutters = [(i,) for i in range(5)] if stage.get("movable_shutter") else [tuple(stage.get("fixed_shutters", []))]
    lights = list(itertools.combinations(("TOP", "LEFT", "RIGHT"), 2)) if stage.get("light_puzzle") else [None]
    for posts, slots, active in itertools.product(placements, shutters, lights):
        yield posts, slots, active


def validate():
    stages = json.loads(DATA.read_text(encoding="utf-8"))
    assert [s["id"] for s in stages] == [f"G{i:02}" for i in range(1, 11)]
    for stage in stages:
        observations = stage["observations"]
        targets = list(map(target, observations))
        counts = [0] * len(observations)
        combined = []
        for posts, slots, active in candidates(stage):
            matches = [shadow(posts, active or o["active_lights"], slots, stage.get("tall", False)) == t for o, t in zip(observations, targets)]
            counts = [n + int(ok) for n, ok in zip(counts, matches)]
            if all(matches):
                combined.append((posts, slots, active))
        assert len(combined) == 1, (stage["id"], len(combined))
        posts, slots, active = combined[0]
        assert set(posts) == set(map(cell, stage["solution"]))
        if stage.get("movable_shutter"):
            assert slots == (stage["solution_shutter"],)
        if stage.get("light_puzzle"):
            assert set(active) == set(stage["solution_lights"])
        if "expected_candidates" in stage:
            assert counts + [len(combined)] == stage["expected_candidates"], counts
        print(f'{stage["id"]}: observations={counts}, combined={len(combined)}')
    # Edge clipping, unbounded overlap, and shutter isolation.
    assert shadow([12], ["BOTTOM"])[7] == 1
    assert shadow([12], ["TOP", "LEFT", "RIGHT"], [2])[11:14] == [1, 0, 1]
    assert shadow([12], ["TOP"], tall=True)[22] == 1
    assert max(shadow(range(25), DIRECTIONS, tall=True)) == 8
    print("All 10 experiments exhaustively validated.")


if __name__ == "__main__":
    validate()
