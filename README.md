# SHADOW SUM

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
