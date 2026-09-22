# Cause & Light H01–H06

A separate campaign using the existing Experiment optical model. All unspecified target cells are visible zero. Grant18 and G01–G10 puzzle data are unchanged; H progress uses `user://shadow_sum_cause_light_v0_1.json`.

## Launch

```powershell
godot --path . -- --campaign cause-light
godot --path . -- --campaign cause-light --stage H03
godot --path . -- --dev-selector
```

Local Godot executable: `C:\Users\hiro\tools\godot-4.7\Godot_v4.7-stable_win64.exe`.
The developer selector offers GRANT18, G01–G10 EXPERIMENTS, and H01–H06 CAUSE & LIGHT. Ordinary startup still opens Grant18.

H01 has only TOP and LEFT installed; other mounts are invisible. H03 has four installed lamps and always three active: tap an active lamp to make it the only dark lamp. A dark lamp tap does nothing. H04–H06 provide Observation A/B buttons as well as lamp switching; Posts and the shutter remain stationary while shadows rebuild in 180–200 ms. H05 visibly changes between two and three lit sources. H06 uses one plate to suppress both B-column TOP contributions.

UNDO restores lamp/observation/world state; RESET restores the initial three-lamp state in H03, empty Posts, and shutter A. Hints never place an answer. H03's second whisper compares B3 and D5; the other whispers pulse lamp/rail surfaces.

## Verification

```powershell
python tools/validate_cause_light.py
godot --headless --path . -d --ignore-error-breaks --script res://tools/cause_light_smoke.gd
```

Exact exhaustive counts:

| Stage | A | B | Combined |
|---|---:|---:|---:|
| H01 | 1 | — | 1 |
| H02 | 1 | — | 1 |
| H03 | 1 | — | 1 |
| H04 | 4 | 5 | 1 |
| H05 | 2 | 4 | 1 |
| H06 | 2 | 4 | 1 |

H03 enumerates 6,000 states. The smoke covers real Godot mouse input for all six solutions, lamp swaps, wrong-OFF rejection, observation state and board-position preservation, H04's false single-observation candidates, multiple-Post shutter suppression, undo/reset, cancellation of navigation tweens, save isolation/reload, and 405×900 / 720×900 bounds.

Locally verified: all existing smoke scripts, all six glass/metal phases, existing Python validators and analysis tests. Rendered mouse-event playthrough passes. H05 UI reports at both widths have zero overlap, offscreen, or zero-size findings. Whole-project static validation has no errors; 32 pre-existing warnings remain in old scripts. H and G runtime smokes have no warnings/errors. CI has the H validator, smoke and CLI boot checks; remote CI has not been run.

## Human playtest — pending

A scripted mouse playthrough is not a first-time human test. H01–H06 are ready for that test; the full Definition of Done remains open until it happens.

Ask only “How did you solve it?” after each puzzle. Do not ask whether the player understood shutters or noticed light counts. Record their exact words, including incorrect explanations, without treating a clear as proof of discovery.

| Player / date | Stage | Exact explanation | First action | Whisper level | Time / resets | Observed hesitation |
|---|---|---|---|---|---|---|
| | H03 | | | | | |
| | H05 | | | | | |
| | H06 | | | | | |

Evaluate whether H03 separates OFF from blocked paths, H05 uses changed illumination as evidence, and H06 explains multiple gaps with one cause. Leave adoption into Grant18 undecided until actual player evidence exists.
