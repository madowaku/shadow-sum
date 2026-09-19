#!/usr/bin/env python3
"""Explain bounded deductions, not human difficulty or a runtime hint solver.

Levels: direct saturation; subset subtraction; one hypothetical socket checked
with direct/subset propagation. No nested assumptions. Exact uniqueness is
checked independently by validate_stages.py.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

SIZE = 5
ALL = (1 << 25) - 1
ROOT = Path(__file__).resolve().parents[1]


def cells(mask):
    return [i for i in range(25) if mask & (1 << i)]


def code(i):
    return chr(65 + i % 5) + str(i // 5 + 1)


def sources(i):
    r, c = divmod(i, 5)
    return sum(1 << j for j in ([i-5] if r else []) + ([i-1] if c else []) + ([i+1] if c < 4 else []))


def constraints(stage):
    return [(sources(r*5+c), value, code(r*5+c)) for r, row in enumerate(stage['clues']) for c, value in enumerate(row) if value >= 0] + [(ALL, stage['posts'], 'COUNT')]


def propagate(equations, filled=0, empty=0, subsets=False):
    trace = []
    while True:
        residual = []
        action = None
        for mask, value, label in equations:
            left = mask & ~(filled | empty)
            need = value - (mask & filled).bit_count()
            if need < 0 or need > left.bit_count():
                return filled, empty, trace, label
            if left:
                residual.append((left, need, label))
                if action is None and need in (0, left.bit_count()):
                    action = (left, bool(need), 'direct', [label])
        if action is None and subsets:
            for a, va, la in residual:
                for b, vb, lb in residual:
                    if a == b or a & b != a:
                        continue
                    delta, need = b ^ a, vb - va
                    if need < 0 or need > delta.bit_count():
                        return filled, empty, trace, f'{lb} minus {la}'
                    if need in (0, delta.bit_count()):
                        action = (delta, bool(need), 'subset', [la, lb])
                        break
                if action:
                    break
        if action is None:
            return filled, empty, trace, None
        mask, occupied, kind, labels = action
        if occupied:
            filled |= mask
        else:
            empty |= mask
        trace.append(dict(kind=kind, sources=labels, cells=[code(i) for i in cells(mask)], occupied=occupied))


def explain(stage, level=2):
    equations = constraints(stage)
    filled, empty, trace, conflict = propagate(equations, subsets=level >= 1)
    assert conflict is None, conflict
    while level >= 2 and filled | empty != ALL:
        alternatives = []
        for index in cells(ALL & ~(filled | empty)):
            for assumed in (False, True):
                bit = 1 << index
                _, _, proof, conflict = propagate(equations, filled | (bit if assumed else 0), empty | (0 if assumed else bit), True)
                if conflict:
                    alternatives.append((len(proof), index, assumed, proof, conflict))
        if not alternatives:
            break
        _, index, assumed, proof, conflict = min(alternatives, key=lambda x: (x[2], x[0], x[1]))
        trace.append(dict(kind='contradiction', cells=[code(index)], occupied=not assumed, assumed=assumed, proof=proof, conflict=conflict))
        if assumed:
            empty |= 1 << index
        else:
            filled |= 1 << index
        filled, empty, following, conflict = propagate(equations, filled, empty, True)
        assert conflict is None
        trace.extend(following)
    return dict(filled=[code(i) for i in cells(filled)], undecided=25-(filled|empty).bit_count(), trace=trace)


def metrics(stage):
    direct = explain(stage, 0)
    subset = explain(stage, 1)
    full = explain(stage, 2)
    probes = [t for t in full['trace'] if t['kind'] == 'contradiction']
    return dict(id=stage['id'], title=stage['title'], posts=stage['posts'], hidden=sum(v < 0 for row in stage['clues'] for v in row), direct_fixed=25-direct['undecided'], direct_posts=len(direct['filled']), subset_fixed=25-subset['undecided'], assumptions=len(probes), longest_contradiction=max([len(p['proof']) for p in probes], default=0), undecided=full['undecided'], trace=full['trace'])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=Path, default=ROOT/'data/stages_v0_1.json')
    parser.add_argument('--json', type=Path)
    args = parser.parse_args()
    report = [metrics(s) for s in json.loads(args.data.read_text(encoding='utf-8'))]
    for item in report:
        print('{id:02} {title:18} Posts={posts} fog={hidden:2} direct={direct_fixed:2}/25 subset={subset_fixed:2}/25 assumptions={assumptions} proof={longest_contradiction} unresolved={undecided}'.format(**item))
    if args.json:
        args.json.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')

if __name__ == '__main__':
    main()
