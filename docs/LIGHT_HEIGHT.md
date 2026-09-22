# Light Combination + Tall Post LC01–TP04

A separate eight-puzzle campaign for testing two SHADOW SUM directions without Observation switching:

- **LC01–LC04:** choose the light-source combination directly on one board.
- **TP01–TP04:** infer Post height from shadow reach, then combine height with light selection.

Grant18, G01–G10, and H01–H06 data/saves remain separate.

## Launch

```powershell
godot --path . -- --campaign light-height
godot --path . -- --campaign light-height --stage LC04
godot --path . -- --campaign light-height --stage TP04
godot --path . -- --dev-selector
```

Progress is stored in:

```text
user://shadow_sum_light_height_v0_1.json
```

## Controls

### Light Combination

Four lamp mounts surround the board. In LC01–LC04, tap installed lamps to toggle them directly.

- LC01 and LC02 require exactly two active lights.
- LC03 and LC04 leave the number of active lights unknown.
- No Observation A/B switching is used.

### Tall Posts

A Tall Post casts two cells in each active-light direction. A Normal Post casts one.

TP02–TP04 show separate Normal and Tall inventory sockets. Click an inventory socket to select that type, then click a board socket, or drag directly from the inventory. Moving an already placed Post preserves its type.

## Puzzle set

| Stage | Unknowns | Intended discovery |
|---|---|---|
| LC01 TWO SOURCES | 2 of 4 lights | shadow direction identifies sources |
| LC02 INTERFERENCE | 2 of 4 lights | overlap identifies a pair of sources |
| LC03 HOW MANY LIGHTS? | light subset | light count is itself part of the answer |
| LC04 LIGHT & POST | Posts + light subset | object position and illumination solve together |
| TP01 LONG REACH | Tall position | shadow length reveals height |
| TP02 MIXED HEIGHTS | Normal + Tall | different reaches can overlap |
| TP03 DEPTH FIELD | 2 Normal + 1 Tall | one long-reaching Post participates in multiple overlaps |
| TP04 HEIGHT & LIGHT | Normal + Tall + lights | the same shadow row reveals both height and illumination |

## Exhaustive validation

```powershell
python tools/validate_light_height.py
```

Expected state counts:

| Stage | States | Solutions |
|---|---:|---:|
| LC01 | 6 | 1 |
| LC02 | 6 | 1 |
| LC03 | 15 | 1 |
| LC04 | 4,500 | 1 |
| TP01 | 25 | 1 |
| TP02 | 600 | 1 |
| TP03 | 6,900 | 1 |
| TP04 | 9,000 | 1 |

Godot smoke:

```powershell
godot --headless --path . -d --ignore-error-breaks --script res://tools/light_height_smoke.gd
```

The smoke checks real mouse lamp input, separate Normal/Tall inventory interaction, Tall drag type preservation, undo, TP04 swapped-height rejection, save isolation, and 405×900 / 720×900 bounds.

## Evaluation questions

Do not judge these stages only by clear rate.

For LC01–LC04, watch whether players predict a lamp choice from the target before tapping, rather than cycling combinations until the board happens to match.

For TP01–TP04, ask only **“How did you solve it?”** after the puzzle. Strong evidence is an explanation involving shadow reach or height without being prompted with those terms.

The central test is whether both families preserve the one-board feeling:

```text
hypothesis -> touch -> optical response -> deduction
```

rather than becoming a combination lock.
