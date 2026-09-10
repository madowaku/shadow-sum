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

## Stage-specific teaching

### 001 FIRST LIGHT
The player should understand `one Post → three shadow contributions` by watching the board, not by reading a modal tutorial.

### 002 OVERLAP
The first transition to level 2 must feel physically heavier than level 1. This is the tactile explanation of addition.

### 003 BLACK CORE
The first transition to level 3 must be unmistakably heavier than level 2 without becoming loud or flashy.

## Implementation notes

`src/feel_main.gd` subclasses the existing prototype controller. This keeps the feel layer separable from puzzle logic and makes it easy to tune or remove without touching `ShadowRules`.

Audio is synthesized at runtime using tiny `AudioStreamWAV` buffers. No external SFX assets are required for this pass.

## QA checklist

- [ ] Godot 4.7 project imports successfully.
- [ ] Main scene boots in headless smoke test.
- [ ] Stage 001 placement produces immediate click + existing 3-way projection.
- [ ] Removing a Post produces a softer response.
- [ ] Stage 002 first double overlap reads heavier than a single shadow.
- [ ] Stage 003 full shadow reads heavier than a double shadow.
- [ ] Match pulses never persist as solution-revealing markers.
- [ ] Solving still reveals hidden target cells correctly.
- [ ] Rapid placement/removal leaves cell scale and modulation at sane values.
- [ ] Test at 720×900 and 360×800 before closing the feel pass.
