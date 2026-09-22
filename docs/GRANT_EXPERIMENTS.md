# Grant Experiments G01–G10

The experimental campaign is playable and deliberately separate from Grant18. The original 18 puzzles, gameplay scripts, main scene and save schema are unchanged. `project.godot` now starts a small campaign selector; its default remains Grant18.

## Play

With Godot 4.7 on PATH, from the repository:

```powershell
godot --path . -- --campaign experiments
godot --path . -- --campaign experiments --stage G05
godot --path . -- --campaign grant18
```

On this workstation:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64.exe" --path C:\Dev\Projects\shadow-sum -- --campaign experiments
```

Alternatively open `scenes/experiments.tscn` in Godot and run the current scene (F6). `--stage G01` starts at the first experiment even with existing progress. The normal experiment launch resumes at the first uncleared stage.

- Tap an empty socket to place a Post; tap an occupied socket to remove it.
- Drag a Post or the inventory Post: floating metal and a magnetic socket show the landing point. The live shadow previews the candidate; committed state changes only on release. Invalid drops restore the committed view.
- Touch the lamps with open arc marks to switch observations. Small screw marks indicate fixed lamps. Unlit lamps have no glow.
- Drag the rail plate or tap a rail slot. A–E label the columns. Fixed plates cannot move.
- G07 holds its Posts fixed; tapping a lamp selects the one source to turn off. Tapping that dark lamp restores all three.
- UNDO restores the previous world/observation state. RESET restores the stage's initial optical state. BACK replays the previous experiment.
- WHISPER is manual only and never places a Post. Hints highlight an optical surface and record I/II/III usage. G02 has one small idle lamp pulse, without explanatory text.
- Logical solve is immediate. Reveal begins at 450 ms, resonance at 650 ms, and NEXT unlocks at 900 ms. Reset/navigation cancels outstanding presentation.

## Model and isolation

`src/experiment_optics.gd` is the discrete source of truth. Posts occupy binary cells; each active direction contributes one unit at every step of its cast length. TOP shutters suppress only the TOP contributions from Posts in that column. Tall Posts have cast length two. Contributions beyond the board are discarded; intensities are not clamped to three. Every observation must match, with the required Post count and optical constraints.

`data/grant_experiments_v0_1.json` specifies all ten experiments. Unspecified target cells are **visible zero**, not fog. A/B share Posts and shutters. The Python validator independently enumerates every legal Post, shutter and light configuration. G10 assertions are exactly **5 / 4 / 1**.

Experiment progress: `user://shadow_sum_grant_experiments_v0_1.json`.
Grant18 progress: `user://shadow_sum_grant18_progress_v1.json`.
The experiment code never reads `SHADOW_SUM_PROGRESS_PATH` or the Grant18 save. Automated experiment tests use a separate disposable save. Completed-stage records include highest hint level, first touched object type, elapsed seconds, action count and reset count; they do not infer discovery or enjoyment.

The experiment UI uses a local Theme and existing NIGHT color tokens. The Theme is scoped to this campaign so the original campaign's presentation does not change.

## Verification

```powershell
python tools/validate_grant_experiments.py
godot --headless --path . -d --ignore-error-breaks --script res://tools/grant_experiment_smoke.gd
```

Verified locally with Godot 4.7:

- All ten puzzles exhaustively unique; G10 observation counts 5 / 4 / 1.
- Mouse and touch placement, lamp taps, inventory/Post dragging, rail dragging/tapping, optical recomputation, wrong-shutter rejection and all-observation clear validation.
- RESET/UNDO, canceled solve and hint animations, 900 ms NEXT gate, all-ten progression and original-save byte preservation.
- 405×900, 676×900 and 720×900: all ten stages fit; touch targets at least 44 px and do not overlap. Skill `ui_report` also passes all three widths without zero-size, overlap or offscreen findings.
- Original stage validators, analysis tests and the complete existing smoke suite pass locally, including all six glass/metal phases. Existing GDScript warnings remain in the old campaign; the experiment boot and smoke have zero warnings/errors.
- Real rendered viewport captures inspected for the optical UI. Human comfort on an actual phone is still untested.

The CI workflow includes the new exhaustive validator, smoke and experiment-launch check. A remote CI run has not been triggered by this local work.

## Human gate — still pending

This is an implementation/prototype milestone, **not completion of the specification's human-evaluation Definition of Done**. Recruit 5–8 first-time players; say only “Please try this puzzle.” Do not explain the new optics. Use [the playtest sheet](GRANT_EXPERIMENTS_PLAYTEST.md). Leave KEEP / MOBILE / DROP undecided until observing real players. No experimental puzzle is adopted into Grant18 yet.

Source brief: [Godot implementation specification v0.1](GRANT_EXPERIMENTS_SPEC_v0_1.md).
