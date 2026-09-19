#!/usr/bin/env python3
"""Exhaustive fixed-Post-count verification, independent of the teaching solver."""
from __future__ import annotations
import itertools
import json
from pathlib import Path

SIZE = 5
DATA_PATH = Path(__file__).resolve().parents[1] / 'data/stages_v0_1.json'


def coord_to_index(coord: str) -> int:
    if not isinstance(coord, str) or len(coord) != 2 or coord[0] not in 'ABCDE' or coord[1] not in '12345':
        raise ValueError(f'Invalid coordinate: {coord}')
    return (int(coord[1])-1)*SIZE + ord(coord[0])-ord('A')


def shadow_for(indices):
    posts = [[False]*SIZE for _ in range(SIZE)]
    for index in indices:
        r,c = divmod(index,SIZE)
        posts[r][c] = True
    return [[int(r>0 and posts[r-1][c]) + int(c>0 and posts[r][c-1]) + int(c<SIZE-1 and posts[r][c+1]) for c in range(SIZE)] for r in range(SIZE)]


def matches_visible(indices, clues):
    shadow = shadow_for(indices)
    return all(value < 0 or shadow[r][c] == value for r,row in enumerate(clues) for c,value in enumerate(row))


def validate_stage(stage):
    required, clues = stage['posts'], stage['clues']
    assert type(required) is int and 1 <= required <= 25, 'Invalid Post count'
    assert len(clues)==5 and all(isinstance(row,list) and len(row)==5 for row in clues), 'Invalid board dimensions'
    assert all(type(v) is int and -1 <= v <= 3 for row in clues for v in row), 'Invalid clue'
    solution = tuple(coord_to_index(c) for c in stage['solution'])
    assert len(set(solution)) == len(solution) == required, 'Duplicate/missing solution Posts'
    assert matches_visible(solution,clues), 'Authored solution does not match'
    # Enumerate EVERY placement with this Post count. No inference/trace reused.
    masks = []
    for r,row in enumerate(clues):
        for c,value in enumerate(row):
            if value < 0: continue
            source = 0
            for rr,cc in [(r-1,c),(r,c-1),(r,c+1)]:
                if 0 <= rr < SIZE and 0 <= cc < SIZE:
                    source |= 1 << (rr*SIZE+cc)
            masks.append((source,value))
    masks.sort(key=lambda x:(x[1]!=0,x[0].bit_count()))
    matches = []
    for candidate in itertools.combinations(range(25),required):
        placement = sum(1 << i for i in candidate)
        if all((placement & mask).bit_count()==value for mask,value in masks):
            matches.append(candidate)
            if len(matches)>1: break
    assert len(matches)==1, f'Expected 1 solution, found {len(matches)}'
    assert set(matches[0])==set(solution), 'Unique solution differs from authored solution'


def main():
    stages = json.loads(DATA_PATH.read_text(encoding='utf-8'))
    assert [s['id'] for s in stages] == list(range(1,19)), 'Campaign must contain ordered IDs 1–18'
    for stage in stages:
        validate_stage(stage)
        print(f"PASS {stage['id']:03} {stage['title']}")
    print(f'Validated {len(stages)} stages exhaustively: all solutions match and are unique.')

if __name__ == '__main__':
    main()
