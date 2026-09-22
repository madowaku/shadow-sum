# Flat Plate P01–P04

A four-puzzle experiment campaign for a directional object:

- **vertical plate `│`** responds to LEFT / RIGHT light only
- **horizontal plate `─`** responds to TOP / BOTTOM light only

The plate stays on the same 5×5 board as other SHADOW SUM pieces. Its orientation changes which light directions can produce a shadow.

## Launch

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign flat-plate
```

Individual stage:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign flat-plate --stage P04
```

Progress uses `user://shadow_sum_flat_plate_v0_1.json`.

## Interaction

A placed Flat Plate starts vertical. Tap the plate to rotate it 90 degrees.

For movable stages, drag the plate from its inventory socket to the board or drag an already placed plate to a new socket. Moving preserves orientation. A fixed plate can still rotate when the stage permits it.

The design goal is immediate causality:

```text
tap plate
   ↓
│ becomes ─
   ↓
left/right shadows retract
top/bottom shadows appear
```

No Observation switching is used.

## Stages

| Stage | Search space | Core discovery |
|---|---:|---|
| P01 TURN THE PLATE | 2 | orientation alone changes the shadow axis |
| P02 WHERE / WHICH WAY | 50 | infer both plate position and orientation |
| P03 CROSS SECTION | 1,200 | Normal Post + Flat Plate overlap |
| P04 EDGE OR DARK? | 192 | distinguish a dark lamp from the plate's thin edge |

P04 keeps a Normal Post fixed at C3. That Post reveals which three lamps are actually active. The Flat Plate then explains why one expected direction is still absent.

## Validation

```powershell
python tools/validate_flat_plate.py
```

All four stages are exhaustively enumerated and must have exactly one solution.

Godot smoke:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --headless --path C:\Dev\Projects\shadow-sum `
  -d --ignore-error-breaks --script res://tools/flat_plate_smoke.gd
```

The smoke covers rotation, reset, undo, plate drag orientation preservation, mixed Normal/Plate overlap, P04 lamp correction, save isolation, and 405×900 / 720×900 bounds.

## Playtest question

After each stage, ask only:

> How did you solve it?

The useful signal is whether the player spontaneously talks about **direction**, **orientation**, **thin edge**, or equivalent physical reasoning. A clear obtained by rotating until it happens to fit is not enough evidence.
