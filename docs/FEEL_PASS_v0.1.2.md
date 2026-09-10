# SHADOW SUM v0.1.2 — ONE MORE TURN Feel Pass

## Design target

Make the core loop satisfying before adding more mechanics:

1. place a Post,
2. watch three shadow contributions arrive,
3. feel overlaps gain weight,
4. notice a useful match without being told the solution,
5. solve and immediately want the next board.

The deterministic grid rules remain authoritative. Visuals and audio never determine puzzle state.

## Micro-feedback language

### Place
- Immediate short high click.
- Post compresses, then returns with a small back-ease.
- Existing north / west / east projection animation remains the readable cause-and-effect layer.

### Remove
- Softer descending click.
- No punishment sound. Experimentation should feel cheap.

### Single shadow (0 → 1)
- Projection motion is the feedback.
- No heavy secondary effect.

### Double shadow (1 → 2)
- Short low `TON` cue.
- Cell briefly compresses vertically and rebounds.
- Three emitters pulse together once.

### Full shadow (2 → 3)
- Lower, heavier `ZUN` cue.
- Cell compresses more, overshoots slightly, then settles.
- Emitters pulse warm for one beat.

### Visible clue match
- A changed LIVE SHADOW cell that now equals a non-zero visible TARGET clue receives one tiny bright pulse.
- This is encouragement, not a correctness meter. No persistent green state is shown.

### Solve
- Keep the existing complete-shadow reveal and gold solve pulse.
- Add a restrained three-note rising chime, one note per light direction.
- Do not turn the solve beat into a fanfare.

## v0.1.2b — Liquid shadow tuning

Shadow density changes should not read as four flat UI colours swapping instantly. `src/feel_polish_main.gd` keeps the same discrete 0/1/2/3 puzzle state but interpolates the visible StyleBox colour for 0.18 seconds.

- Increasing density settles inward by a tiny amount before returning to rest.
- Decreasing density breathes outward slightly before returning.
- This animation never delays or changes the authoritative ShadowRules result.
- The existing directional projection animation remains faster and more readable than the density settle. Cause first, material response second.

The intended feeling is closer to light being absorbed into smoked glass than a button changing colour.

## v0.1.2b — Responsive canvas

The project uses a `405×900` 9:20 base canvas with `canvas_items` stretch mode and `expand` aspect handling.

Why 405×900:
- it scales uniformly to the 360×800 phone test target,
- it keeps the existing 720×900 desktop window useful by expanding horizontal logical space,
- it also behaves sensibly on 720×1280 and other taller portrait targets.

Compact mode is selected from the visible logical canvas width, not raw physical window pixels.

### Compact layout targets
- TARGET and LIVE remain visible together horizontally. Comparing them should never require scrolling.
- Shadow cells: 32 logical units.
- Post hit targets: 48 logical units.
- Outer margins and emitter labels tighten before the puzzle board itself is sacrificed.
- `LIVE SHADOW` shortens to `LIVE` in compact mode.
- Footer copy and legend become shorter, but core puzzle information stays visible.

No vertical ScrollContainer is used in the core play screen. The puzzle should feel like one instrument, not a form.

## Stage-specific teaching

### 001 FIRST LIGHT
The player should understand `one Post → three shadow contributions` by watching the board, not by reading a modal tutorial.

### 002 OVERLAP
The first transition to level 2 must feel physically heavier than level 1. This is the tactile explanation of addition.

### 003 BLACK CORE
The first transition to level 3 must be unmistakably heavier than level 2 without becoming loud or flashy.

## Implementation notes

`src/feel_main.gd` subclasses the existing prototype controller and owns audio / impact feedback. `src/feel_polish_main.gd` subclasses that feel layer and owns liquid colour settling plus responsive layout. The inheritance layers deliberately keep `ShadowRules` and stage data untouched.

Audio is synthesized at runtime using tiny `AudioStreamWAV` buffers. No external SFX assets are required for this pass.

## QA checklist

- [x] Godot 4.7 project imports successfully in CI.
- [x] Main scene boots in headless smoke test.
- [x] Automated feel smoke solves Stage 001 and exercises level-2 and level-3 overlaps.
- [ ] 360×800 logical-layout smoke passes with no Control outside the visible canvas.
- [ ] Stage 001 placement produces immediate click + existing 3-way projection on local Windows build.
- [ ] Removing a Post produces a softer response on local Windows build.
- [ ] Stage 002 first double overlap reads heavier than a single shadow.
- [ ] Stage 003 full shadow reads heavier than a double shadow.
- [ ] Liquid density transition feels smooth rather than sluggish.
- [ ] Match pulses never persist as solution-revealing markers.
- [ ] Solving still reveals hidden target cells correctly.
- [ ] Rapid placement/removal leaves cell scale and modulation at sane values.
- [ ] Visual review at both 720×900 and 360×800 before closing the feel pass.
