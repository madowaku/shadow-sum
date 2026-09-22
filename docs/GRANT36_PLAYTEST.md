# GR21–GR36 draft playtest

The generated draft now has an opt-in Godot test mode. Default F5/startup still
loads GRANT20; original stage data and original save files are unchanged.

## Start from the Godot editor

1. Open this project in Godot 4.7.
2. Open `scenes/grant36_draft.tscn` in the FileSystem panel.
3. Press **F6 (Run Current Scene)**.

A fresh draft starts at **GR21**. The **TEST STAGE** picker jumps freely to any of
the 36 stages, including GR01–GR20 for comparison. FOG stages are labelled in the
picker. F5 still runs the ordinary GRANT20 campaign.

## Start from PowerShell

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" `
  --path C:\Dev\Projects\shadow-sum `
  -- --campaign grant36-draft --stage GR21
```

Change `GR21` to `GR29`–`GR32` to test FOG, or `GR36` for the four-object finale.
Omit `--stage` to resume at the first unfinished stage starting from GR21.
`--dev-selector` also includes **GR21–GR36 DRAFT PLAYTEST**.

## Playing and reviewing

- Select Normal / Tall / Plate from the inventory, then place it on the board.
  Dragging also works. Tap a plate to rotate it; drag it back to its inventory to
  remove it. Move the shutter along its rail and toggle the allowed lamps.
- A **?** on TARGET means **unobserved**, not zero. Only visible target cells are
  equality constraints. CURRENT always shows the physical shadow, including at
  positions hidden on TARGET. The hidden cells remain hidden after clearing.
- The FOG stages have 3, 3, 5, and 3 hidden cells respectively. They are exactly
  unique using the remaining observed cells.
- WHISPER is disabled on GR21–GR36 because hints have not been authored. The
  original twenty stages retain their existing hints.
- BACK, RESET and UNDO retain their normal behavior. NEXT unlocks after a clear.
  The final REPLAY returns to GR21. TEST STAGE remains available to skip a puzzle
  without marking it solved.

Draft progress is isolated in `user://shadow_sum_grant36_v0_4_draft.json`, with
campaign ID `grant36_v0_4_draft`. Solves record time, actions, first action and reset
count there. The mode does not change any of the prior campaign save files.

The [selection report](../generated/grant36_selection_report.md) contains solutions
and explicit near misses. Keep it closed during blind playtests. The data remain
review-only; the main campaign has not been extended to 36 stages.

## Verification

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64_console.exe" `
  --headless --path C:\Dev\Projects\shadow-sum `
  -d --ignore-error-breaks --script res://tools/grant36_draft_smoke.gd

& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64_console.exe" `
  --headless --path C:\Dev\Projects\shadow-sum `
  -d --ignore-error-breaks --script res://tools/grant20_v03_smoke.gd
```

The draft smoke solves all 16 new stages through mouse input, compares all 25
computed shadow values with generator metadata, rejects 64 authored near misses,
checks all four FOG displays and unknown-vs-zero behavior, exercises the actual
stage menu, verifies inventory return / UNDO / RESET / final REPLAY, reloads the
draft save, and checks all player save files remain untouched. Its temporary save
uses a separate smoke-only filename and is removed after the run.

Both smoke tests pass with zero runtime errors or warnings. Every new stage fits
at 405×900 and 720×900; FOG UI reports have zero overlap, zero-size, or offscreen
findings at both sizes. A rendered FOG screenshot was also inspected. See
`generated/grant36_playtest_validation.json` for the verification snapshot.

Whole-project static loading finds no parse/load errors. It still reports existing
warnings in untouched older scripts; those are separate from the clean draft and
GRANT20 runtime runs. The bundled skill's scenario runner also emits its own enum
conversion warnings, outside the project.

`generated/.gdignore` keeps candidate reports and ranking CSVs out of Godot asset
imports. Godot would otherwise interpret ranking column names as translation
locales. Runtime puzzle data live under `data/` and are still loaded normally.
