# GRANT14 v0.2

A curated 14-puzzle campaign that rebuilds SHADOW SUM around the mechanics that preserved the strongest one-board cause-and-effect feel.

The campaign deliberately excludes Observation switching. Every puzzle stays on one optical board:

```text
hypothesis -> touch apparatus -> shadow changes -> deduction
```

## Launch

Because `godot` is not currently on PATH on the main Windows dev machine:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign grant14-v02
```

Jump to the final puzzle:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign grant14-v02 --stage GR14
```

Progress is isolated in:

```text
user://shadow_sum_grant14_v0_2.json
```

## Progression

| # | Stage | Main idea | Exact search states |
|---|---|---|---:|
| GR01 | FIRST SHADOW | basic Post causality | 25 |
| GR02 | OVERLAP | shadows add | 300 |
| GR03 | EMPTY SPEAKS | zero shadow is evidence | 2,300 |
| GR04 | FOURTH LIGHT | light count is environmental | 25 |
| GR05 | TWO SOURCES | infer 2 of 4 lamps | 6 |
| GR06 | LIGHT & POST | infer objects and lights together | 4,500 |
| GR07 | SHUTTER | a lit source can still be blocked locally | 300 |
| GR08 | TWO UNKNOWNS | infer Posts plus shutter column | 1,500 |
| GR09 | LONG REACH | shadow reach reveals height | 25 |
| GR10 | MIXED HEIGHTS | Normal and Tall objects coexist | 600 |
| GR11 | TURN THE PLATE | orientation changes the shadow axis | 2 |
| GR12 | CROSS SECTION | Normal Post + directional Flat Plate | 1,200 |
| GR13 | EDGE OR DARK? | distinguish dark source from thin edge | 192 |
| GR14 | CALIBRATION | Light + Shutter + Normal + Tall + Plate | 552,000 |

Every stage is required to have exactly one solution.

## Conceptual reveals

The campaign is edited around four model updates rather than around a pile of disconnected gimmicks.

### GR04: the fourth light

The player can no longer treat “three shadow directions” as an intrinsic Post rule. The apparatus determines illumination.

### GR07: shutter

A missing shadow no longer means a missing object or dark lamp. A local optical path can be blocked.

### GR09: Tall Post

Object geometry changes reach. Shadow length becomes evidence about the object itself.

### GR11: Flat Plate

Object orientation changes which light directions can produce a shadow. Absence becomes evidence about cross-section.

## Final calibration

GR14 uses only already learned rules:

- Normal Post x1
- Tall Post x1
- Flat Plate x1
- exactly 3 of 4 lamps
- one movable TOP shutter

Unique solution:

```text
Normal      B2
Tall        C1
Flat Plate  C4 vertical
Lights      TOP + LEFT + RIGHT
Shutter     B
```

The intended reasoning layers are:

1. long reach points to the Tall Post,
2. a local missing TOP contribution points to the shutter,
3. directional absence points to the Flat Plate orientation,
4. the remaining global pattern determines the three active lights.

The player should not need a new rule in the final stage.

## Validation

Independent exhaustive search:

```powershell
python tools/validate_grant14_v02.py
```

Godot end-to-end smoke:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --headless --path C:\Dev\Projects\shadow-sum `
  -d --ignore-error-breaks --script res://tools/grant14_v02_smoke.gd
```

The smoke solves all 14 stages through real mouse input and also checks:

- GR04 fourth-light reveal
- GR07 fixed shutter visibility
- GR09 two-cell Tall reach
- GR11 tap rotation
- GR14 wrong orientation and wrong shutter rejection
- WHISPER never mutates the solution state
- 405x900 and 720x900 bounds
- dedicated save reload
- isolation from Grant18, G, H, Light & Height, and Flat Plate saves

## Playtest focus

The useful question after a puzzle is simply:

> How did you solve it?

Watch for spontaneous causal language rather than a successful clear alone.

Especially record whether players independently express these updates:

- GR04: shadows come from the lamps, not from a hard-coded three-direction rule
- GR07: the lamp can be on while one path is blocked
- GR09: reach implies height
- GR11: orientation explains directional absence
- GR13: “dark lamp” and “thin edge” are different causes
- GR14: the player decomposes the final pattern into several familiar causes rather than brute-forcing controls

GRANT14 v0.2 is still a playtest campaign. Default startup remains the existing Grant18 until this edited sequence proves itself with first-time players.
