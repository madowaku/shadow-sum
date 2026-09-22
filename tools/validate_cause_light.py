"""Exact H-series candidate counts using the existing independent optical oracle."""
import itertools
import json
from pathlib import Path
from validate_grant_experiments import cell, shadow, target, DIRECTIONS

DATA = Path(__file__).resolve().parents[1] / "data/cause_light_h01_h06_v0_1.json"
EXPECTED = [[1], [1], [1], [4, 5], [2, 4], [2, 4]]


def validate():
    stages = json.loads(DATA.read_text(encoding="utf-8"))
    assert [s["id"] for s in stages] == [f"H{i:02}" for i in range(1, 7)]
    for stage, expected in zip(stages, EXPECTED):
        observations = stage["observations"]
        targets = list(map(target, observations))
        counts = [0] * len(targets)
        solutions = []
        light_sets = list(itertools.combinations(DIRECTIONS, 3)) if stage.get("light_puzzle") else [None]
        states = 0
        for posts, slot, lights in itertools.product(itertools.combinations(range(25), stage["posts"]), range(5), light_sets):
            states += 1
            matches = [shadow(posts, lights or o["active_lights"], [slot]) == t for o, t in zip(observations, targets)]
            counts = [n + int(ok) for n, ok in zip(counts, matches)]
            if all(matches):
                solutions.append((posts, slot, lights))
        assert counts == expected, (stage["id"], counts, expected)
        assert len(solutions) == 1, (stage["id"], solutions)
        posts, slot, lights = solutions[0]
        assert set(posts) == set(map(cell, stage["solution"]))
        assert slot == stage["solution_shutter"]
        if stage.get("light_puzzle"):
            assert states == 6000
            assert set(lights) == set(stage["solution_lights"])
        assert stage["expected_candidates"] == expected + [1]
        print(f'{stage["id"]}: observations={counts}, combined=1, states={states}')


if __name__ == "__main__":
    validate()
