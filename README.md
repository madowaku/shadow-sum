# NOXSUM

Reconstruct where NOX the cat was from the shadows kept by the Nocturnal Optical Archive. One plate can hold several moments; darker squares reveal overlap, without revealing their order.

The default Godot launch opens the [36-record Grant presentation](docs/NOXSUM_GRANT_36.md). The [Godot Web export](docs/NOXSUM_WEB_EXPORT.md) is built for a 720×900 PC browser viewport and reflows at 405×900 and 360×800. The [NOX character lock](assets/nox/CHARACTER_LOCK_v0.1.md) governs every pose and HOME visual. Earlier SHADOW SUM experiments and review campaigns remain available through CLI campaign flags.

## Core rule

For each screen cell `(r, c)`:

```text
shadow(r,c) = post(r-1,c) + post(r,c-1) + post(r,c+1)
```

Each post contributes one level of shadow to the south, west, and east neighboring screen cells. Values are rendered as:

- `0` = clear
- `1` = light shadow
- `2` = double shadow
- `3` = full shadow
- hidden clue = unknown / unobserved

The player is told the required number of posts and must place them so every visible shadow clue matches.

## v0.1 target

- Godot 4.7
- 5×5 board prototype
- click/tap to place/remove posts
- live shadow recomputation
- visible-clue validation
- 18 handcrafted stages from Intro to Umbra
- data-driven stage format
- JP/EN UI toggle from the header or L; HOME sound ON/OFF and SETTINGS BGM/SE volume sliders persist on this device

## Milestone 1

Stage 001 playable end-to-end:

`place posts -> recompute shadows -> validate -> clear`

## Repository layout

```text
project.godot
src/
  main.gd
  shadow_rules.gd
  stage_data.gd
scenes/
  main.tscn
data/
  stages_v0_1.json
docs/
  GAME_SPEC_v0.1.md
```

## Status

Implementation sprint started September 2026.

## Grant experiments

An isolated G01-G10 optical campaign is available with `--campaign experiments`. See [play instructions and validation](docs/GRANT_EXPERIMENTS.md). Default startup opens NOXSUM; use `--campaign grant18` for that legacy build.

## Cause & Light

H01-H06 is available with --campaign cause-light. See [play instructions and validation](docs/CAUSE_LIGHT.md). Use --dev-selector to choose among the three campaigns.


## Light & Height

LC01-LC04 and TP01-TP04 are available with `--campaign light-height`. They test direct four-lamp combination puzzles and Normal/Tall Post reasoning on a single board, without Observation switching. See [play instructions and validation](docs/LIGHT_HEIGHT.md). `--dev-selector` includes this fourth campaign.


## Flat Plate

P01-P04 is available with `--campaign flat-plate`. A Flat Plate casts only along the axis broadside to the light, so tapping it rotates both the physical object and the shadow axis. See [play instructions and validation](docs/FLAT_PLATE.md).


## Grant14 v0.2

A curated 14-puzzle Grant candidate is available with `--campaign grant14-v02`. It keeps all reasoning on one optical board and progressively introduces light selection, shutter occlusion, Tall Posts, and Flat Plate orientation before a final integrated calibration puzzle. See [campaign design, launch instructions, and validation](docs/GRANT14_V0_2.md).


## Grant20 v0.3

A 20-puzzle curated Grant candidate is available with `--campaign grant20-v03`. It keeps the GRANT14 discovery curve, adds six synthesis puzzles using only already-learned optics, and moves the integrated CALIBRATION finale to GR20. See [campaign structure, launch instructions, and validation](docs/GRANT20_V0_3.md).

### GR21–GR36 draft playtest

Use `--campaign grant36-draft` to test the generated draft independently of GRANT20.
A fresh draft starts at GR21; use `--stage GR29` for FOG or the in-game TEST STAGE
picker to jump freely. In the Godot editor, open `scenes/grant36_draft.tscn` and press
F6. Progress is saved separately. See [launch instructions and verification](docs/GRANT36_PLAYTEST.md).


## Variant Boards v0.1

Six puzzles using only the original three-light rules are available with `--campaign variants`. The same 5x5 scene reads a placement-only `boardShape` mask; light and shadow remain unchanged. Use `--dev-selector` and choose **VAR01–VAR06 VARIANT BOARDS**, or run:

```powershell
& 'C:\Users\hiro\tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . -- --campaign variants
```

See [data format, verification and completion report](docs/VARIANT_BOARD_IMPLEMENTATION_REPORT.md).

## NOXSUM opening prototype

The standalone Remotion Studio project is in [tools/noxsum-opening-remotion](tools/noxsum-opening-remotion/README.md). Run `npm install`, `py prepare_assets.py`, and `npx remotion studio --no-open` from that directory to inspect the 405 × 900 and 1600 × 900 compositions. Godot handoff timing is in [docs/NOXSUM_OPENING_TIMING_v0.1.json](docs/NOXSUM_OPENING_TIMING_v0.1.json).
