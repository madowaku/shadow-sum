# Astra task — GRANT36 v0.5 BOARD SHAPES

## Goal

Implement and generate the next human-playtest build of SHADOW SUM:

```text
GRANT36 v0.5 — BOARD SHAPES
```

Read first:

```text
docs/GRANT36_V0_5_BOARD_SHAPES.md
docs/GRANT36_V0_4_PLAYTEST_2026_09_22.md
docs/GRANT36_GENERATION.md
src/experiment_optics.gd
src/experiment_main.gd
data/grant36_v0_4_draft.json
```

Work on the existing branch `feature/grant36-v0.5-board-shapes` or create a child work branch. Do not merge to main.

## P0 — typed inventory bug

Before generating new stages, reproduce the GR34 v0.4 observation that the stage can clear without using the Flat Plate.

Fix the actual cause.

Acceptance:

- exact Normal/Tall/Plate counts are required,
- a placed Plate cannot be silently substituted by Normal,
- fixed/movable inventory handling still works,
- Plate return-to-inventory remains working,
- add a regression test that fails on the old behavior.

Do not paper over this by changing GR34 data; GR34 is being replaced anyway.

## P1 — boardShape.mask runtime

Add optional stage data:

```json
"boardShape": {
  "mask": [
    "00100",
    "00100",
    "11111",
    "00100",
    "00100"
  ]
}
```

Semantics:

- exactly 5 rows of exactly 5 chars,
- only `0` and `1`,
- `1` = legal placement socket,
- `0` = no placement socket,
- missing socket is not a wall,
- shadow propagation is unchanged,
- Shadow Screen remains all 25 cells,
- absent boardShape = full 5×5 compatibility.

Runtime requirements:

- missing sockets visually read as absent/deactivated metal holes, not target fog,
- no click placement on missing sockets,
- no drag/drop destination on missing sockets,
- dragging a board object onto a missing socket must reject safely,
- reset/undo/save/load cannot reintroduce an illegal placement,
- fixed posts must also be validated against the mask,
- layout remains inside compact/wide bounds.

## P2 — solver and validator mask support

Update generator/validator models so object position enumeration is restricted to legal sockets.

Do not alter optical rays because of the mask.

Add the six exact regression fixtures from the v0.5 design doc:

```text
CROSS
NARROW
STAIR
CORNER
HOLLOW
BRIDGE
```

Confirm each old fixture is still unique under its original simple model.

Add malformed-mask tests.

## P3 — mechanic necessity

Add explicit reports/tests beyond uniqueness.

At minimum record:

- `typed_inventory_exact`
- `shape_required`
- `tall_required`
- `plate_required`
- `fog_removes_shortcut` when relevant

Suggested counterfactuals:

- shape_required: allow every 5×5 socket; if the same visible target now has an additional valid world, the shape contributes to uniqueness,
- tall_required: search a reduced model where Tall is unavailable/replaced by Normal; reject authored "Tall focus" stages that remain solvable,
- plate_required: search a reduced model where Plate is unavailable/replaced by Normal; reject authored "Plate focus" stages that remain solvable,
- typed_inventory_exact: runtime/validator both require authored typed counts.

Do not claim a mechanic is "required" only because the authored solution contains it.

## P4 — generate replacement pool

Keep unchanged:

```text
GR21 GR22 GR23 GR26 GR27 GR30 GR31 GR33
```

Replace:

```text
GR24 GR25 GR28 GR29 GR32 GR34 GR35 GR36
```

Generate a pool of at least **120 exact-unique board-shape candidates** across those eight slot profiles.

Use the six known masks as seeds. Also generate additional deliberate masks for GR35/GR36.

No replacement candidate may use:

- free Light selection,
- movable Shutter.

Use fixed lights only.

FOG is allowed where the slot profile asks for it.

## P5 — selection

Select eight replacements.

Hard gate:

- exact unique,
- exact typed inventory,
- shape contributes to uniqueness,
- intended Tall/Plate mechanic passes necessity counterfactual where applicable,
- no free Light selection,
- no movable Shutter,
- no mirror/near duplicate of another selected stage,
- no runtime-illegal object position.

Target profiles:

```text
GR24 shape + Normal
GR25 shape + Tall
GR28 shape + Plate
GR29 shape + FOG
GR32 shape + Tall + Plate
GR34 shape + typed Normal/Tall/Plate
GR35 dense shape synthesis, 4 objects
GR36 finale: Normal×2 + Tall×1 + Plate×1, fixed lights
```

Prefer a different first deduction across adjacent replacements.

## P6 — campaign integration

Create:

```text
data/grant36_v0_5.json
```

with GR01–20 unchanged, the eight human KEEP stages copied unchanged from v0.4, and eight new replacements.

Add a campaign id:

```text
grant36-v05
```

Use an isolated progress save such as:

```text
user://shadow_sum_grant36_v0_5.json
```

Do not overwrite Grant20, Grant36 draft, or Jev-review saves.

Default boot behavior should not change unless specifically required for this feature branch. An explicit campaign flag is sufficient.

## P7 — tests

Add independent validation and Godot smoke coverage.

Required:

- all 36 exact-unique,
- six old variant fixtures pass,
- illegal socket placement rejected,
- board drag cannot land on `0`,
- save/load does not restore illegal positions,
- typed inventory regression,
- FOG still means unobserved,
- every replacement stage solved through real mouse input,
- compact/wide layout bounds,
- old Grant20 validator remains green.

For GR34 replacement, explicitly test that removing/substituting Plate cannot clear the stage.

For GR36, explicitly test reduced models for Tall and Plate necessity.

## Deliverables

At minimum:

```text
data/grant36_v0_5.json
docs/GRANT36_V0_5_REPORT.md
generated/grant36_v0_5_candidates.json
generated/grant36_v0_5_ranked.csv
tools/generate_grant36_v05_board_shapes.py
tools/validate_grant36_v05.py
tools/grant36_v05_smoke.gd
```

Update runtime source files as needed.

The report should include:

- candidate counts per slot/profile,
- selected mask visual for each replacement,
- solution state,
- search-space size,
- exact survivor count,
- mechanic-necessity counterfactual results,
- reasoning signature,
- why it replaces the v0.4 stage,
- generation/validation timings.

## Stop condition

After implementation, generation, exact validation, campaign wiring, and smoke tests are green:

1. commit and push,
2. report the branch and commit,
3. report the eight selected replacement stages,
4. report any stage where mechanic necessity was difficult to satisfy,
5. stop for human playtest.

Do not merge.
Do not add Reflection.
Do not reintroduce Observation switching.
Do not add free Light/Shutter uncertainty to the eight replacement stages.
