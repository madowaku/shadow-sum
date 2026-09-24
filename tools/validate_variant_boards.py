"""Exhaustively verify the six authored Variant Board puzzles."""
import json
from pathlib import Path
from board_shape import enabled_cells
from validate_stages import validate_stage

DATA = Path(__file__).resolve().parents[1] / 'data/variant_boards_v0_1.json'

def main():
    stages = json.loads(DATA.read_text(encoding='utf-8'))
    assert [s['id'] for s in stages] == list(range(1, 7))
    assert [s['title'] for s in stages] == ['CROSS', 'NARROW', 'STAIR', 'CORNER', 'HOLLOW', 'BRIDGE']
    for stage in stages:
        matches = validate_stage(stage)
        print(f"PASS VAR-{stage['id']:02} {stage['title']}: {len(enabled_cells(stage))} sockets, {len(matches)} solution, expected coordinates match")

if __name__ == '__main__':
    main()
