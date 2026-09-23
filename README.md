# SHADOW SUM

## Current family-test product: NOXSUM

The default Godot 4.7 launch opens NOXSUM HOME and the final 36-stage GRANT36 v0.5 campaign. PLAY, CONTINUE, and LEVEL SELECT use the same isolated progress file. The Web release build is exported with `NOXSUM Web` to `builds/web/index.html`.

Run the final sync checks with `python tools/validate_grant36_v05.py`, `python tools/validate_noxsum_grant36_sync.py`, and Godot's `res://tools/noxsum_grant36_sync_smoke.gd`. See [the final sync report](docs/NOXSUM_GRANT36_V0_5_SYNC_REPORT.md) for the campaign source and verification.

A minimalist logic puzzle about placing posts so that three directional lights create the target shadow intensities.

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
- JP/EN UI toggle from the header or L; language and sound preferences persist

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

An isolated G01-G10 optical campaign is available with `--campaign experiments`. See [play instructions and validation](docs/GRANT_EXPERIMENTS.md). Default startup remains Grant18.

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
