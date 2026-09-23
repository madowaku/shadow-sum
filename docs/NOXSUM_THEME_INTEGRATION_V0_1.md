# NOXSUM Theme Integration v0.1

NOX is one cat, not several cats. The board represents multiple moments from NOX's past superimposed on one reconstruction surface. Each placed trace means: NOX was here at one moment. The final shadow field is the sum of the shadows produced by those moments.

## Runtime mapping

- Normal Post -> SIT trace
- Tall Post -> STAND trace
- Shutter -> SLEEP trace on the TOP-light rail
- Flat Plate -> optical apparatus, unchanged for v0.1
- TARGET -> RECORDED SHADOW
- CURRENT -> RECONSTRUCTION

Placed SIT/STAND traces are intentionally slightly translucent so they read as past moments of the same NOX. Inventory NOX remains fully opaque. SLEEP uses the existing shutter rail and blocks TOP light exactly as before.

## Puzzle invariants

This integration must not change stage data, solutions, legal-state counts, optical computation, save format, Grant20 progression, or Flat Plate behavior. The authoritative optical implementation remains `src/experiment_optics.gd` and the authoritative Grant20 data remains `data/grant20_v0_3.json`.

## Brand

Application title: `NOXSUM`

HOME tagline: `RECONSTRUCT THE PAST FROM THE SHADOWS`

Story line: `NOX is gone. The shadows remember.`

The app icon uses crossing light/shadow bands with the intersection as the darkest point.

## Assets

- `assets/nox/nox_sit.svg`
- `assets/nox/nox_stand.svg`
- `assets/nox/nox_sleep.svg`
- `assets/nox/noxsum_icon.svg`

These are lightweight runtime vector assets. Final illustrated NOX art can replace them later without changing runtime semantics.

## Acceptance checks

- [ ] Normal Post renders as SIT NOX.
- [ ] Tall Post renders as STAND NOX.
- [ ] Shutter renders as sleeping NOX.
- [ ] Flat Plate still renders as the optical plate.
- [ ] Placed traces read as time echoes.
- [ ] Inventory traces remain clearly draggable.
- [ ] All 20 Grant puzzles retain their existing solutions.
- [ ] Existing Grant20 save files still resume.
- [ ] HOME reads NOXSUM.
- [ ] App icon imports correctly.
- [ ] 405x900 remains readable.

## Follow-up

1. Replace vector stand-ins with approved high-resolution NOX sprites.
2. Create a dedicated Stool Sit HOME illustration.
3. Tune trace opacity from screenshots.
4. Decide whether Flat Plate eventually receives a NOX-action metaphor.
5. Rewrite hint copy directly once terminology is final.
