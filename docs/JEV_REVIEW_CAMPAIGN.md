# Jev A/B review campaign

Developer-only campaign for human comparison of the five slots flagged by the Jev second review.

## Launch

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign jev-review
```

Jump to a review stage:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign jev-review --stage RV08
```

## Blind sequence

The UI deliberately shows only the original GR slot and Variant A/B. It does not reveal which variant is the current generator selection or which one Jev/chagepy preferred.

| Review | Slot | Candidate |
|---|---|---|
| RV01 | GR28 A | `three_plate_light_shutter-005` |
| RV02 | GR28 B | `three_plate_light_shutter-006` |
| RV03 | GR30 CHECK | `fog_plate_shutter-010` |
| RV04 | GR31 A | `fog_height_light-007` |
| RV05 | GR31 B | `fog_height_light-006` |
| RV06 | GR34 A | `dense_height_plate_shutter-017` |
| RV07 | GR34 B | `dense_height_plate_shutter-004` |
| RV08 | GR36 A | `finale-015` |
| RV09 | GR36 B | `finale-010` |

GR30 remains a control/check stage because the focused comparison found no stronger pre-playtest replacement.

## FOG

FOG is implemented as **unobserved**, not zero.

The TARGET renders fogged cells as frosted `?` cells. The exact matcher skips those cells while still requiring every visible target cell to match.

## Review telemetry

The existing playtest save records each review stage independently under `RV01` through `RV09`, including:

- solve time,
- action count,
- reset count,
- first action.

The review campaign uses its own save:

```text
user://shadow_sum_jev_review_v0_1.json
```

It does not mutate Grant20 progress.

## Decision rule

Do not choose a variant from solve time alone.

After playing each A/B pair, prefer the one that produces the cleaner sequence of intentional deductions and the stronger "I know why this must be true" feeling. Use time/actions mainly as supporting evidence.

No canonical GR21-GR36 stage is changed by this review campaign.
