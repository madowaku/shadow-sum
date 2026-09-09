#!/usr/bin/env python3
"""Validate SHADOW SUM stage data.

Checks:
1. Declared solution uses the requested number of posts.
2. Declared solution matches every visible clue.
3. Exactly one placement with that post count matches all visible clues.

Run from repository root:
    python tools/validate_stages.py
"""

from __future__ import annotations

import itertools
import json
from pathlib import Path

SIZE = 5
DATA_PATH = Path(__file__).resolve().parents[1] / "data" / "stages_v0_1.json"


def coord_to_index(coord: str) -> int:
    col = ord(coord[0].upper()) - ord("A")
    row = int(coord[1:]) - 1
    if not (0 <= row < SIZE and 0 <= col < SIZE):
        raise ValueError(f"Invalid coordinate: {coord}")
    return row * SIZE + col


def shadow_for(indices: tuple[int, ...] | list[int]) -> list[list[int]]:
    posts = [[False] * SIZE for _ in range(SIZE)]
    for index in indices:
        row, col = divmod(index, SIZE)
        posts[row][col] = True

    shadow = [[0] * SIZE for _ in range(SIZE)]
    for row in range(SIZE):
        for col in range(SIZE):
            value = 0
            if row > 0 and posts[row - 1][col]:
                value += 1
            if col > 0 and posts[row][col - 1]:
                value += 1
            if col < SIZE - 1 and posts[row][col + 1]:
                value += 1
            shadow[row][col] = value
    return shadow


def matches_visible(indices: tuple[int, ...] | list[int], clues: list[list[int]]) -> bool:
    shadow = shadow_for(indices)
    for row in range(SIZE):
        for col in range(SIZE):
            clue = int(clues[row][col])
            if clue >= 0 and shadow[row][col] != clue:
                return False
    return True


def validate_stage(stage: dict) -> None:
    stage_id = int(stage["id"])
    required = int(stage["posts"])
    clues = stage["clues"]
    solution = tuple(coord_to_index(coord) for coord in stage["solution"])

    if len(solution) != required:
        raise AssertionError(
            f"Stage {stage_id:03d}: solution has {len(solution)} posts, expected {required}"
        )

    if not matches_visible(solution, clues):
        raise AssertionError(f"Stage {stage_id:03d}: declared solution does not match clues")

    matches: list[tuple[int, ...]] = []
    for candidate in itertools.combinations(range(SIZE * SIZE), required):
        if matches_visible(candidate, clues):
            matches.append(candidate)
            if len(matches) > 1:
                break

    if len(matches) != 1:
        raise AssertionError(
            f"Stage {stage_id:03d}: expected exactly 1 solution, found {'2+' if len(matches) > 1 else 0}"
        )


def main() -> None:
    stages = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    for stage in stages:
        validate_stage(stage)
        print(f"PASS {int(stage['id']):03d}  {stage['title']}")
    print(f"\nValidated {len(stages)} stages: all solutions match and are unique.")


if __name__ == "__main__":
    main()
