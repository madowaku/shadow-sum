# GRANT20 v0.3

GRANT20 v0.3 extends the curated Grant candidate from 14 to 20 puzzles without adding a new optical rule.

The first thirteen stages keep the GRANT14 discovery curve. The former final CALIBRATION moves to GR20, and six synthesis puzzles are inserted between the last discovery and the finale.

## Design goal

The added puzzles are not tutorials for new gimmicks. They are the part where the player gets to *use* what they already understand:

```text
discover a rule
    ↓
combine familiar causes
    ↓
read one board more deeply
    ↓
final calibration
```

Observation switching remains excluded.

## Launch

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign grant20-v03
```

Jump to the synthesis section:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign grant20-v03 --stage GR14
```

Final calibration:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign grant20-v03 --stage GR20
```

Progress is isolated in `user://shadow_sum_grant20_v0_3.json`.

## Campaign

| # | Stage | Focus | Search states |
|---|---|---|---:|
| GR01 | FIRST SHADOW | basic Post causality | 25 |
| GR02 | OVERLAP | shadows add | 300 |
| GR03 | EMPTY SPEAKS | zero shadow is evidence | 2,300 |
| GR04 | FOURTH LIGHT | illumination is environmental | 25 |
| GR05 | TWO SOURCES | infer 2 of 4 lamps | 6 |
| GR06 | LIGHT & POST | infer lamps and Posts together | 4,500 |
| GR07 | SHUTTER | local TOP path can be blocked | 300 |
| GR08 | TWO UNKNOWNS | Post positions + shutter | 1,500 |
| GR09 | LONG REACH | height changes reach | 25 |
| GR10 | MIXED HEIGHTS | Normal + Tall | 600 |
| GR11 | TURN THE PLATE | orientation changes allowed directions | 2 |
| GR12 | CROSS SECTION | Normal + Flat Plate | 1,200 |
| GR13 | EDGE OR DARK? | dark source vs thin edge | 192 |
| GR14 | LONG & LIT | Tall + Normal + 2-of-4 lights | 3,600 |
| GR15 | PLATE & SHUTTER | Flat Plate + local occlusion | 6,000 |
| GR16 | TWO AXES | two independently oriented plates | 1,200 |
| GR17 | REACH & EDGE | Tall + Flat Plate | 1,200 |
| GR18 | LIGHT THROUGH A GAP | 3-of-4 lights + shutter | 6,000 |
| GR19 | THREE MATERIALS | Normal + Tall + Flat Plate | 27,600 |
| GR20 | CALIBRATION | all core causes together | 552,000 |

Every stage must have exactly one solution under the implemented optical model.

## The six added synthesis puzzles

### GR14 LONG & LIT
The player must read both reach and illumination from the same horizontal pattern. This is the first time height and a light subset are unknown together.

### GR15 PLATE & SHUTTER
A missing vertical contribution can come from local occlusion, while another absence comes from the plate's thin edge. The point is to separate two familiar kinds of “nothing happened.”

### GR16 TWO AXES
Two Flat Plates occupy one column but face different ways. No new rule appears; orientation itself becomes the whole deduction.

### GR17 REACH & EDGE
Tall reach and Flat Plate selectivity share the same target field. The player must distinguish “farther” from “fewer directions.”

### GR18 LIGHT THROUGH A GAP
Exactly three lamps are active and one TOP path is blocked. Global source absence and local path blockage must be read from one board.

### GR19 THREE MATERIALS
Normal, Tall, and Flat Plate coexist under four fixed lights. This is a material-reading exam before the apparatus itself becomes uncertain again.

## GR20 CALIBRATION

The final stage is unchanged in concept from GRANT14 v0.2:

- Normal Post x1
- Tall Post x1
- Flat Plate x1
- exactly 3 of 4 lights
- one movable TOP shutter

Unique solution:

```text
Normal      B2
Tall        C1
Flat Plate  C4 vertical
Lights      TOP + LEFT + RIGHT
Shutter     B
```

No new rule appears in GR20.

## Validation

```powershell
python tools/validate_grant20_v03.py
```

The independent validator exhaustively checks exact state counts and uniqueness for all twenty stages.

Godot smoke:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --headless --path C:\Dev\Projects\shadow-sum `
  -d --ignore-error-breaks --script res://tools/grant20_v03_smoke.gd
```

The smoke solves all 20 through real mouse input, checks the six synthesis-stage configurations, verifies the GR20 Flat Plate return-to-inventory regression, tests final wrong causes, WHISPER non-mutation, compact/wide layout bounds, save reload, and isolation from every earlier campaign.

## Playtest focus

The main question is no longer “did the player understand each gimmick?”

Watch whether GR14–GR19 create the feeling that there is still more depth inside already-known rules.

Useful signals:

- the player predicts a cause before touching the apparatus,
- the player explains an absence as one of several possible physical causes,
- the player uses reach, orientation, and illumination together rather than one at a time,
- GR20 feels like a culmination rather than a sudden difficulty spike,
- finishing GR20 still produces “I want more.”
