# NOXSUM × GRANT36 v0.5 FINAL SYNC TASK

## Goal

Make the current NOXSUM presentation layer use the **final GRANT36 v0.5 puzzle/runtime implementation** without regressing the NOXSUM home screen, cat visuals, background, localization, or product presentation.

This is a **final content/runtime synchronization**, not a redesign.

The shipping Grant build must contain **exactly GR01–GR36**. Do not expose BS01 or other bonus/review/dev campaigns in the normal product flow.

---

## Source of truth

### Product / presentation base

Preserve the current NOXSUM branch/worktree as the presentation base.

Known integration branch:
- `feature/noxsum-integration-v0.1`

Preserve from NOXSUM:
- `project.godot` product name/icon/main scene
- `scenes/home.tscn`
- `src/home_screen.gd`
- NOX assets under `assets/nox/`
- NOXSUM background/theme/product visuals
- current JP/EN copy and localization behavior
- current HOME / stage-select navigation
- current sound/settings behavior

### Puzzle/runtime source of truth

Take gameplay semantics and final 36-stage content from:
- branch: `feature/grant36-v0.5-board-shapes`
- `data/grant36_v0_5.json`
- `src/experiment_optics.gd`
- the GRANT36-specific logic in `src/experiment_main.gd`
- the `grant36-v05` route in `src/campaign_main.gd`
- `tools/validate_grant36_v05.py`
- `tools/grant36_v05_smoke.gd`

Do **not** use `grant36_v0_4_draft.json` or an older generated/review campaign as product content.

Do **not** solve this by replacing the NOXSUM UI wholesale with the old SHADOW SUM UI.

The two branches have diverged substantially, so prefer a deliberate semantic port over a blind merge.

---

## P0: fix product stage source

The current NOXSUM home screen still points at:

```gdscript
const STAGE_DATA := "res://data/grant20_v0_3.json"
const PROGRESS_PATH := "user://shadow_sum_grant20_v0_3.json"
```

Change the product to use the final 36-stage campaign:

```gdscript
const STAGE_DATA := "res://data/grant36_v0_5.json"
const PROGRESS_PATH := "user://shadow_sum_grant36_v0_5.json"
```

Update progress campaign checks from `grant20_v0_3` to the actual final campaign id `grant36-v05`.

HOME must show 36 stages and resume/select the same progress file used by gameplay.

Acceptance:
- fresh install shows 36 stages
- stage select says 01/36 ... 36/36
- continue resumes first uncleared GRxx
- completing a stage in gameplay immediately agrees with HOME progress after returning/restart
- old Grant20 progress must not masquerade as Grant36 progress

---

## P0: route normal product play to GRANT36 v0.5

The current campaign router defaults to `grant20-v03`.

Normal NOXSUM product launch must route to `grant36-v05`.

Requirements:
- HOME -> PLAY/CONTINUE launches `grant36-v05`
- HOME stage-select jump launches the requested GRxx in `grant36-v05`
- direct developer launch `--campaign=grant36-v05` still works
- `--stage GR28` still works with the final campaign
- developer/review campaigns may remain reachable only through explicit developer arguments
- BS01 bonus is not visible in the normal product UI

Do not leave requested-stage forwarding special-cased only for `grant20-v03`; it must work for `grant36-v05`.

---

## P0: copy the final stage data exactly

Bring `data/grant36_v0_5.json` from the v0.5 source branch into the NOXSUM product branch without editing puzzle semantics.

There must be exactly 36 records:
`GR01` through `GR36`, no gaps and no duplicates.

Critical replacement checkpoints from the human-tested v0.5:

| ID | Required title | Key final mechanic |
|---|---|---|
| GR24 | SHAPE OF THE SILENCE | board shape, fixed TOP+LEFT |
| GR25 | THE LONG WAY THROUGH | board shape + Tall |
| GR28 | PLATE IN THE GAP | board shape + Plate, fixed 4 lights |
| GR29 | VEILED SOCKETS | board shape + FOG |
| GR32 | THE LAST OPEN AXIS | board shape + Tall + Plate |
| GR34 | FOUR CAUSES AGREE | exact Normal/Tall/Plate + board shape |
| GR35 | DENSE BOARD SYNTHESIS | 4-object board-shape synthesis |
| GR36 | THE SHAPED FINALE | final 4-object board-shape synthesis |

Important regression sentinel:

`GR28` must **not** be the old:
- `THREE KINDS OF ABSENCE`
- free 3-light selection
- movable shutter

Final GR28 must be:
- title: `PLATE IN THE GAP`
- Normal x2
- Plate x1
- fixed TOP+LEFT+RIGHT+BOTTOM
- no movable shutter
- board shape:
  ```
  10101
  11111
  00100
  11111
  10101
  ```

If this sentinel fails, stop. The product is still on old content.

---

## P0: port v0.5 optics/runtime semantics

Port the functional v0.5 logic into the NOXSUM runtime while preserving the NOXSUM visual skin.

Required behavior:

### Board Shape
- support optional `boardShape.mask`
- exactly 5 rows x 5 chars, only 0/1
- `1` = legal socket
- `0` = missing socket
- missing socket cannot receive a Post
- missing socket is **not a wall**
- light/shadows pass across missing sockets
- shadow display remains full 5x5
- absent `boardShape` means normal full board

### Exact typed inventory
Clear must require exact inventory use:
- Normal count exact
- Tall count exact
- Plate count exact
- no unknown/generic Plate alias silently behaving as Normal
- no duplicate occupied cells
- no stale `post_types` keys outside placed Posts

### FOG
- hidden clue means unobserved, not zero
- FOG cells are ignored by target matching
- hidden cells remain visually distinct from board-shape missing sockets

### Tall
- Tall reaches 2 cells in each active applicable light direction
- exact Tall inventory is enforced

### Plate
- `plate_v`: LEFT/RIGHT cast, TOP/BOTTOM pass
- `plate_h`: TOP/BOTTOM cast, LEFT/RIGHT pass
- placed Plate can rotate
- movable Plate can return to Plate inventory
- Plate cannot be satisfied by a Normal Post

### Lights
- free-light stages enforce `active_light_count`
- fixed-light stages are not editable
- installed BOTTOM must remain visible when applicable
- BOTTOM must be clickable in GRANT36 free-light stages
- specifically re-test GR22, GR23, GR27, GR31 because all require BOTTOM in their solutions

### Shutter
- movable shutter remains supported only where authored
- board-shape replacement stages GR24/25/28/29/32/34/35/36 must not accidentally inherit movable shutter or free-light controls

---

## P0: preserve NOXSUM presentation

Do not regress these product-facing pieces while syncing runtime:
- title `NOXSUM`
- HOME scene as main scene
- NOX cat artwork and NOX-specific object presentation
- current atmospheric background
- current responsive layout
- current JP/EN mode
- current HOME/back flow
- current sound/settings persistence
- current stage dropdown / stage-select affordance

If gameplay copy is derived from stage `title` or `hints`, keep the underlying final v0.5 puzzle data authoritative and apply NOXSUM/localized presentation as a display layer. Do not fork puzzle geometry just to localize text.

---

## P1: add a hard sync validator

Add a test such as:

`tools/validate_noxsum_grant36_sync.py`

It must fail if the product drifts back to old content.

Minimum checks:
1. exactly 36 stages
2. IDs are exactly GR01..GR36
3. product HOME points to `data/grant36_v0_5.json`
4. product progress path is the Grant36 v0.5 progress file
5. GR24/25/28/29/32/34/35/36 match final v0.5 semantic records
6. GR28 regression sentinel above
7. GR36 is `THE SHAPED FINALE`
8. no BS01 in product campaign
9. all board masks validate
10. every stage is independently exact-unique under the final validator

Prefer checking semantic JSON equality for the entire 36-stage array against the synced product data rather than only checking titles.

---

## P1: Godot smoke coverage

Extend or add NOXSUM integration smoke tests.

Required user-flow tests:

### HOME
- boot `res://scenes/home.tscn`
- 36-stage collection recognized
- choose GR28 from stage select
- router opens GR28 of `grant36-v05`

### GR28 sentinel
Assert at runtime:
- title = `PLATE IN THE GAP`
- board mask present
- no free-light selection
- no movable shutter
- four fixed lights
- missing socket rejects click/drag
- Plate can be placed and rotated
- authored solution clears

### BOTTOM regression
On GR22:
- BOTTOM lamp is visible
- interactive
- starts inactive
- click turns it on
- second click turns it off

Repeat or otherwise cover GR23/27/31 path assumptions.

### FOG / Board Shape distinction
- GR29 FOG renders as unknown
- a missing board socket renders as unavailable socket, not FOG
- shadow still propagates across missing socket

### Exact inventory
- substituting Normal for required Plate does not clear
- omitting required typed object does not clear
- exact authored composition does clear

### Responsive UI
At least:
- 360x800
- 405x900
- 720x900

No controls out of viewport, no overlapping click targets that block play.

---

## P1: full validation before family test

Run, at minimum:

```text
python tools/validate_grant36_v05.py
python tools/validate_noxsum_grant36_sync.py
```

and the relevant Godot smoke scene/script for GRANT36 + NOXSUM integration.

If there is already a repository-wide test command, run it too.

Do not report completion only because GR28 looks correct. All 36 stages and the runtime semantics must pass.

---

## P1: manual spot check

After automated tests pass, manually open:

- GR01: baseline
- GR22: free lights + BOTTOM
- GR23: light + shutter
- GR27: Tall + Plate + free light
- GR28: first critical replacement sentinel
- GR29: board shape + FOG
- GR32: board shape + Tall + Plate
- GR34: exact 4-object typed inventory
- GR35: dense board
- GR36: finale

For each, compare the runtime header/control set to the authored v0.5 data.

---

## Definition of done

FINAL SYNC is complete only when all of these are true:

- NOXSUM product visuals remain intact
- normal HOME launch uses GRANT36 v0.5
- HOME and gameplay share the same 36-stage data/progress
- final v0.5 GR01–36 are present exactly once
- GR28 is `PLATE IN THE GAP`, not `THREE KINDS OF ABSENCE`
- all eight v0.5 board-shape replacements are present
- Board Shape / FOG / Tall / Plate / typed inventory semantics match v0.5
- BOTTOM input regression remains fixed
- independent validator passes all 36
- NOXSUM integration smoke passes
- compact and wide layouts pass
- no BS01/bonus/review content appears in normal Grant flow
- fresh family-test build starts at NOXSUM HOME and can play through GRANT36

---

## Human-test note

Do not change puzzle difficulty or reorder stages during this sync.

The purpose of this task is to make the polished NOXSUM shell faithfully run the already human-tested GRANT36 v0.5 campaign. Any puzzle redesign discovered during sync should be logged separately rather than silently changed.
