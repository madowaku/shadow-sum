# SHADOW SUM v0.1.3 — PICK → SLIDE → CLICK Interaction Pass

## Goal

Turn repositioning into part of the puzzle pleasure without turning hover into a free answer scanner.

The interaction language is:

1. **PICK** an already placed Post,
2. **SLIDE** it across the placement board,
3. let LIVE SHADOW follow only when the Post enters a valid socket,
4. **CLICK** into place on release.

Normal tap-to-place and tap-to-remove remain available.

## Rules

- Dragging starts only from an occupied Post.
- A short movement threshold protects ordinary taps from becoming accidental drags.
- The authoritative `posts` state is unchanged during drag.
- A temporary preview grid drives LIVE SHADOW while dragging.
- Preview updates only on valid sockets. Merely hovering empty screen space does not reveal arbitrary shadow states.
- Occupied sockets other than the source are invalid targets.
- Releasing outside a valid socket cancels the move.
- Releasing on the source socket cancels the move.
- A successful move preserves the total number of Posts.
- Solve detection runs only after a committed drop.

## Feel language

### PICK
- Small rising pickup tone.
- A gold ghost Post lifts under the pointer.
- The source stays logically intact until drop.

### SLIDE
- Entering a new valid socket updates LIVE SHADOW immediately.
- The candidate socket gains a small cyan/gold magnetic emphasis.
- Each new socket produces a tiny, quiet magnetic tick.
- No sound spam while travelling between sockets.

### CLICK
- Successful drop uses a short descending mechanical click.
- The destination Post compresses, overshoots slightly, then settles.
- Existing double/full shadow feedback still applies to the committed result.
- Existing solve pulse and solve chime still apply if the move completes the puzzle.

### CANCEL
- Releasing on the source or outside a valid socket restores the exact pre-drag state.
- Cancellation uses a softer falling tone. No penalty language.

## Architecture

`src/interaction_main.gd` subclasses `src/feel_polish_main.gd`.

Layer order:

`main.gd` → deterministic puzzle/UI core  
`feel_main.gd` → micro audio and overlap feedback  
`feel_polish_main.gd` → liquid shadow transitions and responsive layout  
`interaction_main.gd` → temporary drag preview and commit/cancel behavior

The stage data and `ShadowRules` remain untouched.

## Automated QA

`tools/interaction_smoke.gd` verifies:

- a fully allocated but unsolved board can still move a Post,
- PICK succeeds only from an occupied socket,
- SLIDE preview does not mutate authoritative `posts`,
- LIVE SHADOW matches the temporary preview grid,
- CLICK moves exactly one Post and preserves Post count,
- same-socket release cancels without state changes.

The normal feel and layout smoke tests remain active as regression coverage.

## Windows hands-on QA

- [ ] A normal tap on an occupied Post still removes it without feeling delayed.
- [ ] Small pointer jitter does not accidentally begin a drag.
- [ ] PICK feels immediate once the drag threshold is crossed.
- [ ] The ghost remains visually attached to mouse/finger movement.
- [ ] Socket-to-socket shadow updates feel readable rather than frantic.
- [ ] Dropping onto a socket feels more satisfying than tap-remove + tap-place.
- [ ] Releasing off-board cancels predictably.
- [ ] 360×800 touch targets remain comfortable.
- [ ] Rapid repeated moves never leave ghost Posts, scaled buttons, or stale shadow previews.
