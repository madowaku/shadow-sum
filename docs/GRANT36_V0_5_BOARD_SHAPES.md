# GRANT36 v0.5 — BOARD SHAPES

Status: design lock / implementation target

## Why v0.5 exists

The v0.4 generator succeeded mathematically, but human playtesting exposed a distinction that the proxies did not fully capture.

The best SHADOW SUM stages feel like reading one physical board. The weaker late stages ask the player to search too many external settings: which lamps are active, where the shutter is, which object types are present, and where the objects are.

v0.5 shifts late-game depth back onto the board itself.

## Campaign decision

Keep these v0.4 stages unchanged:

```text
GR21 GR22 GR23
GR26 GR27
GR30 GR31
GR33
```

Replace these slots:

```text
GR24 GR25 GR28 GR29 GR32 GR34 GR35 GR36
```

GR01–GR20 remain unchanged.

The new eight stages are generated/curated under the **BOARD SHAPES** direction.

## Core rule: boardShape.mask

The Shadow Screen remains a fixed 5×5 grid.

Only the POST placement board changes.

```text
1 = socket exists; a Post may be placed here
0 = no socket; placement is impossible here
```

A missing socket is **not a wall** and does not block light.

The shadow engine remains the same discrete optical model. Rays may pass through / across cells whose placement socket is absent. The target Shadow Screen still renders all 25 cells.

If `boardShape.mask` is absent, treat the board as the normal full 5×5 board.

This is crucial: BOARD SHAPES changes the set of legal causes, not the physics of shadow propagation.

## Why board shapes fit SHADOW SUM

A shape is visible before the first move. It narrows causal possibilities without adding another toggle panel.

The player reads:

- where an object could physically exist,
- where a Tall Post can explain distant evidence,
- whether a Plate orientation can fit the remaining legal sockets,
- whether a zero is caused by absence of a Post rather than an external control,
- how the geometry of legal causes changes the meaning of the same shadow pattern.

The intended feeling is still:

> read one apparatus, place a cause, watch the shadow answer.

## Light / shutter policy

Do not remove Light or Shutter mechanics from the game.

However, for the eight new v0.5 replacement stages:

- no free Light selection,
- no movable Shutter,
- no stage whose main deduction is "which environment toggle is correct?",
- use fixed light sets authored into the stage,
- prefer no Shutter at all in replacement stages.

Existing kept stages such as GR23 may retain their current mechanics because human playtest feedback was positive.

## Typed-inventory P0

GR34 v0.4 exposed a failure: the Flat Plate could be omitted and the stage could still clear.

v0.5 acceptance requires both runtime and validator checks for exact typed inventory.

Example:

```text
Normal ×2
Tall ×1
Flat Plate ×1
```

must clear only when exactly those four placed objects exist with those types.

Total object count alone is insufficient.

Also add a **mechanic necessity** analysis for authored late-game stages:

- If a stage is tagged as requiring Tall, verify a reduced model without Tall cannot satisfy all visible evidence.
- If tagged as requiring Plate, verify a reduced model without Plate cannot satisfy all visible evidence.
- If tagged as requiring FOG for its intended late-game role, report whether the fully visible board collapses into a trivial shortcut.
- Board Shape itself is required when the unique solution depends on one or more forbidden sockets being unavailable.

Necessity is a design metric in addition to exact uniqueness.

## Prior variant-board seeds

Reuse the already-designed six variant masks as regression fixtures and generator seeds.

Coordinates below are 1-based `(row,column)`.

### VAR-01 CROSS

Mask:

```text
00100
00100
11111
00100
00100
```

Target:

```text
???1?
?????
1????
?????
???1?
```

POST ×3

Expected solution:

```text
(1,3) (3,2) (5,3)
```

Unique.

### VAR-02 NARROW

Mask:

```text
00000
11111
11111
11111
00000
```

Target:

```text
?????
???1?
?2??1
1?2?1
?????
```

POST ×4

Expected solution:

```text
(2,5) (3,1) (3,3) (4,4)
```

Unique.

### VAR-03 STAIR

Mask:

```text
11000
11100
01110
00111
00011
```

Target:

```text
?????
?2???
1?2??
???2?
??1??
```

POST ×4

Expected solution:

```text
(2,1) (2,3) (3,4) (4,3)
```

Unique.

### VAR-04 CORNER

Mask:

```text
11000
11000
11000
11111
11111
```

Target:

```text
?????
?1???
1????
?1111
?1?1?
```

POST ×4

Expected solution:

```text
(2,1) (4,3) (4,4) (5,1)
```

Unique. Prior candidate trace: `1820 → … → 1`.

### VAR-05 HOLLOW

Mask:

```text
11111
10001
10001
10001
11111
```

Target:

```text
?2?2?
?????
?????
?????
1?1??
```

POST ×4

Expected solution:

```text
(1,1) (1,3) (1,5) (5,2)
```

Unique. Prior candidate trace: `1820 → 91 → 13 → 2 → 1`.

### VAR-06 BRIDGE

Mask:

```text
11011
11111
00100
11111
11011
```

Target:

```text
?????
????1
???1?
???2?
1?2??
```

POST ×4

Expected solution:

```text
(2,4) (4,3) (4,5) (5,2)
```

Unique. Prior candidate trace: `3876 → 136 → 30 → 4 → 2 → 1`.

These exact old puzzles are not automatically the final GR24–GR36 replacements. They are fixtures proving the mask semantics and useful shape seeds.

## Replacement structure

The first search target is:

| Slot | Intended focus | Preferred shape source |
|---|---|---|
| GR24 | first late-game board-shape read, Normal only | CROSS |
| GR25 | board shape + Tall reach | NARROW |
| GR28 | board shape + Plate orientation | STAIR |
| GR29 | board shape + FOG, no environment toggles | CORNER |
| GR32 | board shape + Tall/Plate interaction | HOLLOW |
| GR34 | board shape + exact typed inventory | BRIDGE |
| GR35 | dense 4-object synthesis, fixed lights | generated asymmetric mask |
| GR36 | final calibration: Normal×2 + Tall×1 + Plate×1, fixed lights | generated/readable mask |

This mapping is a search brief, not a requirement to keep a weak result.

## GR36 finale policy

Do not equate "finale" with "most controls."

Preferred finale:

```text
Normal ×2
Tall ×1
Flat Plate ×1
one readable variant board
fixed authored lights
no movable shutter
no free light selection
no FOG unless it clearly improves the puzzle
```

The final stage should require learned shadow reading more deeply, not require the player to sweep configuration controls.

A strong GR36 should use several kinds of board evidence:

- overlap,
- zero / absence,
- Tall reach,
- Plate directional absence,
- legal-socket geometry.

The target is a multi-step deduction chain with a small number of plausible intermediate worlds, not a large raw state-space number.

## Shape-quality constraints

Generated masks should:

- contain roughly 12–21 active sockets,
- be one connected placement region unless a deliberately split stage is being tested,
- avoid single isolated sockets unless logically essential,
- avoid excessive rotational/reflection symmetry across many consecutive stages,
- leave enough interior structure that the solution is not determined only by edge sockets,
- visibly read as a deliberate instrument plate, not random missing squares.

Deduplicate under left/right reflection where equivalent.

## Selection criteria

Exact uniqueness is mandatory but not sufficient.

Rank candidates by:

1. mechanic necessity,
2. causal readability,
3. distinct solve path from adjacent KEEP stages,
4. deliberate use of shape geometry,
5. distributed evidence,
6. low brute-force temptation,
7. low edge abuse,
8. moderate action/control burden.

Do not reward free-Light/Shutter uncertainty because those mechanics are intentionally de-emphasized in this pass.

## v0.5 acceptance

v0.5 is ready for human playtest when:

- GR01–20 unchanged,
- eight KEEP stages unchanged,
- eight replacement stages exact-unique,
- no replacement uses free Light selection,
- no replacement uses movable Shutter,
- typed inventory is enforced at runtime,
- every replacement passes mechanic-necessity checks,
- board masks are rendered and enforced for click/drag placement,
- FOG remains unobserved, not zero,
- the exact validator understands masks,
- a smoke test solves all 36 through real input,
- human review can launch GR24–GR36 directly.

Do not call v0.5 final based on solver metrics. Human feel decides.
