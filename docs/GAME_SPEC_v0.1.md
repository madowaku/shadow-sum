# SHADOW SUM v0.1 Game Specification

## 1. Core fantasy

Place physical posts on a board. Three lights project their shadows onto a separate screen. Reconstruct the observed shadow pattern using only position, overlap, and missing information.

The game should feel like a quiet optical instrument rather than a number puzzle wearing a shadow skin.

## 2. Board model

- Board: 5×5
- Coordinates: A1–E5
- A stage specifies the exact number of Posts available.
- A Post is binary: present or absent.
- Player may place/remove Posts until the required count and visible clues are satisfied.

## 3. Shadow rule

For each shadow-screen cell `(r,c)`:

```text
S(r,c) = P(r-1,c) + P(r,c-1) + P(r,c+1)
```

Out-of-bounds terms contribute zero.

Interpretation:

- `0` clear
- `1` light shadow
- `2` overlapping double shadow
- `3` full triple shadow
- hidden clue: no observation is available at that screen cell

A hidden clue does **not** mean zero shadow.

## 4. Separation of spaces

The Placement Board and Shadow Screen are conceptually separate surfaces.

This avoids giving away a Post position simply because an object visibly occupies the same cell as its clue.

Prototype UI may show three diagnostic sections:

1. Target Shadow
2. Current / Your Shadow
3. Placement Board

Final presentation should visually collapse this into a more physical optical apparatus while preserving the conceptual separation.

## 5. Completion condition

A stage clears when both conditions are true:

1. Number of placed Posts equals the stage Post count.
2. Every visible shadow clue equals the current generated shadow value.

Hidden cells are ignored for validation.

All 18 v0.1 stages have exactly one valid placement under these rules.

## 6. Difficulty language

### Intro 001–003
Teach only the physical rule.

- three projected directions
- overlap
- full triple shadow

### Easy 004–006
Introduce missing observations (`?`).

### Medium 007–009
Longer PURE deduction chains and sparse clue fields.

### Hard 010–012
Long PURE chains and subset/difference reasoning.

### Eclipse 013–015
Contradiction reasoning: assume a Post state, propagate, find impossibility.

### Umbra 016–018
Depth-2 reasoning. Sparse weak clues, especially value `1` shadows.

## 7. Stage set

Runtime data lives in:

`data/stages_v0_1.json`

The stage file includes declared solutions for QA and future hint-system development. Production builds may later strip these if desired.

Run:

```powershell
python tools/validate_stages.py
```

to verify declared solutions and uniqueness exhaustively.

## 8. v0.1 visual direction

Target mood: a small floating optical puzzle instrument.

- dark surrounding space
- warm physical light sources
- pale translucent receiving screen
- Posts read as small sculptural objects, not generic buttons
- shadow intensities should blend visually even though the core model remains discrete 0/1/2/3
- successful solve should briefly reveal the **complete** shadow field, including previously hidden cells

Final solve beat:

`fragmentary clues -> solved placement -> complete shadow blooms into view`

The full reveal is part of the reward, not just validation feedback.

## 9. Architecture rule

Game logic stays deterministic and grid-based. Visual lighting is presentation.

Do not use rendered light/shadow pixels as the authoritative puzzle state.

This keeps:

- solver and generator compatibility
- deterministic tests
- stable stage validation
- freedom to radically change visuals later

## 10. Next milestone

### v0.1.1 Optical Toy Pass

Replace diagnostic presentation with a single coherent apparatus while preserving the same rules:

- floating board + shadow screen
- three visible light emitters
- Post placement feedback
- animated shadow recomposition
- hidden cells represented as damaged/frosted/occluded screen regions
- Stage 001–003 first-time teaching without modal tutorial text
- solve reveal animation

The milestone is successful when Stage 001 can be understood and solved by a first-time player without reading the rule formula.
