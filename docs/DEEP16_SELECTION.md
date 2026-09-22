# DEEP16 Selection / GR21–GR36

GR21–GR36 were built from an exhaustive deterministic candidate search rather than hand-writing sixteen more tutorial boards.

## Candidate generation

`tools/generate_deep16.py` enumerates ten mechanical families:

| Family | Unknowns |
|---|---|
| NNN | three Normal Posts + 3-of-4 lights |
| LT2 | Normal + Tall + 2-of-4 lights |
| PP | two oriented Flat Plates |
| LP_S | Normal + Plate + movable shutter |
| TP | Tall + Plate |
| NN_L3S | two Normal + 3-of-4 lights + shutter |
| NTP | Normal + Tall + Plate |
| NTP_L3 | three materials + 3-of-4 lights |
| NTP_S | three materials + shutter |
| NTP_L3S | three materials + 3-of-4 lights + shutter |

For each family the script:

1. enumerates every legal world state,
2. renders its exact shadow field,
3. groups identical targets,
4. discards every target with more than one solution,
5. scores the remaining targets structurally,
6. keeps sixteen distinct high-ranked candidates.

That produces an exact **160-candidate pool**.

The score is intentionally modest. It favors readable but non-trivial fields with several lit cells, overlaps, and enough shadow mass to support multi-step reasoning. It is not treated as a substitute for human playtesting.

## Selection

The final sixteen were selected for different reasoning signatures, not simply the top sixteen numerical scores.

| Stage | Title | Main reasoning |
|---|---|---|
| GR21 | DEEP OVERLAP | pure Normal chain with two overlaps |
| GR22 | LONG CROSS | Tall reach + unknown 2-light subset |
| GR23 | CROSSED AXES | two Flat Plate orientations |
| GR24 | EDGE & SHUTTER | orientation absence vs local blockage |
| GR25 | REACH & EDGE II | Tall reach vs Plate selectivity |
| GR26 | GLOBAL / LOCAL | lamp absence vs shutter absence |
| GR27 | THREE SIGNATURES | Normal + Tall + Plate under fixed light |
| GR28 | THREE LIGHTS | three materials + unknown 3-light subset |
| GR29 | FIRST FROST | pure core reasoning with four hidden readings |
| GR30 | FROSTED HEIGHT | Tall evidence partly hidden |
| GR31 | FROSTED EDGE | Plate + shutter with hidden evidence |
| GR32 | FROSTED CAUSE | unknown lights + shutter + hidden evidence |
| GR33 | APPARATUS | three materials + shutter |
| GR34 | MISSING SKY | three materials + unknown lights |
| GR35 | DARK COLUMN | dense three-material shutter puzzle |
| GR36 | DEEP CALIBRATION | three materials + lights + shutter |

## FROST rule

A frosted TARGET cell is **unobserved**, not zero.

The full physical world still produces a shadow there, but the solve check ignores that reading. The four FROST stages were independently re-tested after hiding their chosen cells and remain one-solution puzzles under the visible readings alone.

The UI renders these as frosted cells with a `?`, while CURRENT remains fully visible.

## Verification

Run:

```powershell
python tools/generate_deep16.py
python tools/validate_grant36_v04.py
```

The first command rebuilds the 160-candidate search and verifies that the committed GR21–GR36 solutions match their source families. The second exhaustively validates the full 36-stage campaign, including uniqueness under FROST visibility masks.

Godot integration:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum
```

On the `feature/grant36-v0.4` branch, ordinary startup opens GRANT36 v0.4.

The key playtest question for GR21 onward is no longer “did the player learn the rule?” It is whether each board produces a genuinely different chain of deductions.
