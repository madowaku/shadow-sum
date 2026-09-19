# SHADOW SUM v0.1.7d UNKNOWN IS NOT ZERO

## Goal

Teach the first hidden clue without a modal tutorial and without changing the puzzle.

Stage 004 is the first time TARGET contains `?` / fogged cells. The player must immediately understand:

- clear bright glass means **no shadow**;
- fogged / `?` glass means **the shadow value is unobserved**;
- therefore **unknown is not zero**.

The onboarding should feel like the optical instrument briefly explaining itself, then getting out of the way.

This pass is onboarding/presentation only. Do not change Stage004 clues, solution, Post count, difficulty, puzzle rules, hint logic, progress semantics, or solve conditions.

## Current baseline

v0.1.7c SHADOW INK is GREEN on Godot 4.7 stable.

Relevant contracts:

- Stage004 (`MISSING PIECES`) is the first authored stage containing hidden clues (`-1` in stage data).
- hidden TARGET cells already render as frosted glass and retain a visible `?` before solve.
- hidden TARGET reveal on solve is owned by SHADOW INK.
- there is no Stage004 WHISPER hint data.
- status text is already used for short contextual guidance.
- all motion must be event-driven; idle pixels must remain still.
- the whole puzzle must stay one-screen at 405×900, 676×900 and 720×900.

## Product principle

Do not explain the rule with a popup.

Teach by contrasting two existing materials:

1. a clear TARGET cell with authored value 0;
2. a fogged TARGET cell with authored value -1.

The player should be able to understand the grammar without opening HINT.

## Architecture

Add a thin top layer:

```text
main
→ feel_main
→ feel_polish_main
→ interaction_main
→ magnetic_main
→ flow_main
→ progress_main
→ hint_main
→ night_skin_main
→ glass_metal_main
→ shadow_ink_main
→ unknown_main
```

`scenes/main.tscn` should point to `res://src/unknown_main.gd`.

Preferred new files:

```text
src/unknown_main.gd
tools/unknown_smoke.gd
docs/UNKNOWN_IS_NOT_ZERO_v0.1.7d.md
```

Expected updates:

```text
.github/workflows/godot-smoke.yml
scenes/main.tscn
```

Avoid modifying stage data or `whispers_v0_1.json`.

## Trigger

Run the onboarding when the player enters the first authored hidden-clue stage, currently Stage ID 4.

Do not key only by array index if the stage ID is available.

The onboarding runs at most once per application session.

Persistence is intentionally not added in this pass:

- if the player quits before solving Stage004 and returns later, teaching it again is acceptable;
- RESET must not replay it;
- leaving Stage004 and returning during the same session must not replay it.

No save schema changes.

## Micro-sequence

The sequence is non-blocking. Gameplay remains available.

Use Stage004's existing TARGET materials. Suggested cells:

- a clear authored-zero cell such as A1;
- a hidden/fogged cell such as C1.

Do not assume those coordinates without validating the Stage004 data at runtime or in smoke; choose the first visible 0 and first hidden cell if practical.

### Beat 1: clear

After layout settles, wait approximately 0.10–0.15s.

Pulse one visible zero TARGET cell once with a restrained neutral/cool glass rim.

Status:

`CLEAR GLASS  =  NO SHADOW`

Duration roughly 0.9–1.1s.

Do not draw a literal 0 into the cell unless visual QA proves it necessary.

### Beat 2: fogged

Pulse one hidden TARGET cell once. Use its existing frost/fog and a small cyan edge emphasis. Do not reveal its value.

Status:

`FOGGED GLASS  =  SHADOW UNOBSERVED`

Duration roughly 1.1–1.3s.

The `?` remains visible.

### Beat 3: conclusion

Very briefly emphasize the chosen hidden cell or all authored hidden cells with a low-intensity synchronized edge response.

Status:

`UNKNOWN  ≠  ZERO`

Duration roughly 0.7–0.9s.

Then restore the normal Stage004 status produced by the existing gameplay layer.

Total target duration: approximately 2.8–3.2s if uninterrupted.

## Interaction cancellation

The onboarding must never fight the player.

If the player places a Post, begins a drag, presses RESET/BACK/NEXT, or leaves the stage:

- invalidate the onboarding serial immediately;
- stop onboarding tweens;
- restore all affected Control scale/modulate/rim state;
- restore normal status text through the existing update path;
- do not replay during the same session.

Do not disable input while teaching.

If the player acts during Beat 1, the onboarding may end immediately. User action wins.

## Visual ownership

Reuse existing clue cells / ShadowGlassVisual presentation.

Do not add permanent overlays.

Any temporary rim/pulse must:

- be `MOUSE_FILTER_IGNORE`;
- disappear completely after teaching/cancel;
- not mutate authored clue values or `ShadowGlassVisual.clue_hidden`;
- not call reveal functions;
- not affect solve.

Prefer reusing a small dedicated presentation method on `ShadowGlassVisual`, e.g. an onboarding emphasis, over tinting the whole panel if that creates conflict with SHADOW INK.

If adding a visual method, it must coexist with the one-active-motion-tween contract. Do not allow onboarding to leave the material in a stale state.

## Copy

Use the existing English instrument voice.

Primary copy:

```text
CLEAR GLASS  =  NO SHADOW
FOGGED GLASS  =  SHADOW UNOBSERVED
UNKNOWN  ≠  ZERO
```

If compact width makes the second line too long, use:

```text
FOGGED  =  UNOBSERVED
```

Do not add explanatory paragraphs or a modal.

## Question-mark policy

Keep `?` in v0.1.7d.

This pass proves comprehension first. Removing or fading the symbol permanently is a later visual QA decision.

The important improvement is that `?` is no longer an unexplained symbol.

## HINT boundary

Do not add a Stage004 WHISPER hint just to teach this grammar.

Onboarding explains notation. WHISPER explains reasoning.

Keep those systems separate.

## State and serial ownership

`unknown_main.gd` may own presentation-only state such as:

```text
unknown_intro_shown_this_session
unknown_intro_serial
unknown_intro_tweens
```

It must not own puzzle state.

Use a serial/generation check for delayed beats so that BACK/NEXT/stage changes cannot write stale status text into a later stage.

## Automated QA

Add `tools/unknown_smoke.gd` and run it through `tools/godot_checked.sh`.

Minimum assertions:

### Trigger

- root scene uses `unknown_main.gd`;
- Stage001–003 do not trigger UNKNOWN onboarding;
- first entry to Stage004 triggers it;
- Stage004 has at least one visible zero clue and one hidden clue before running the visual sequence;
- RESET does not replay it;
- leave Stage004 and return in the same session does not replay it.

### Non-destructive

Capture authoritative state before onboarding and confirm after each beat:

- `posts` unchanged;
- clue data unchanged;
- stage index unchanged;
- Post count unchanged;
- progress/completed IDs unchanged;
- hint index unchanged;
- `stage_solved` unchanged.

### Material grammar

- chosen clear cell is not hidden;
- chosen fogged cell remains hidden throughout onboarding;
- `?` remains visible on the fogged cell;
- no hidden value is revealed;
- temporary emphasis returns to resting material state.

### Cancellation

Test at least:

- place a Post during Beat 1;
- RESET during Beat 2;
- stage change/BACK during Beat 2.

After cancellation:

- no delayed copy leaks into the new/restored state;
- no temporary scale/modulate survives;
- SHADOW INK motion/tweens remain valid;
- input remains functional.

### Solve

Solve Stage004 after onboarding and confirm the existing SHADOW INK hidden reveal still works unchanged.

### Full regression

All existing CI must stay GREEN:

- Feel
- PICK/SLIDE/CLICK
- Magnetic
- Flow
- Progress
- WHISPER HINTS
- MONOCHROME NIGHT
- GLASS & METAL
- SHADOW INK
- 405×900 / 676×900 / 720×900

## Human QA

Test with somebody or simulate a first-time player who has not read documentation.

Before interacting with Stage004, ask only:

> What do you think the fogged `?` cell means?

Successful answers should be equivalent to:

> The shadow there exists, but I do not know how strong it is.

Failure answers include:

> It means zero.
> It is an unusable cell.
> It is a random wildcard.
> I need to fill that square.

If the player understands after the 3-second sequence, do not add more tutorial text.

## Explicit non-goals

Do not add:

- stage changes;
- reduced hidden count in Stage004;
- WHISPER content for Stage004;
- persistent onboarding save flags;
- modal dialogs;
- tutorial pages;
- arrows covering the board;
- new sound effects;
- Tripo/3D assets;
- Daily Shadow;
- ads;
- localization infrastructure.

## Done definition

v0.1.7d is done when:

- first contact with hidden clues explains itself in about three seconds;
- the player can interact immediately and cancel the teaching naturally;
- hidden still visually means unobserved, not empty;
- no puzzle or save semantics change;
- no stale onboarding callback survives navigation;
- Stage004 solve/reveal remains intact;
- all Godot 4.7 CI is GREEN;
- the game returns to complete stillness after the event.


## Implementation and verification

The `unknown_main.gd` entry layer schedules teaching only for authored stage
ID 4. It scans actual clues in row order for the first 0 and first -1; no
cell coordinate is embedded in the implementation. The opportunity is marked
consumed before the 0.12s layout delay, so input during that delay also prevents
replay. The three beats last 1.0, 1.2 and 0.8 seconds (3.12s including setup).
The flag is in memory only; reset/navigation do not clear it and app restart
may teach the unsolved stage again. No save schema or WHISPER data changed.

`ShadowGlassVisual.emphasize_notation()` animates only a thin inset rim using
the existing single `ink_tween` slot. It does not write density, fog, hidden
state, or reveal. A separate ownership flag lets cancellation clear only the
notation effect without killing a later SHADOW INK reveal. There is no new
input surface, scale animation, repeating effect, or whole-cell tint.

A serial check guards every delayed beat. Placement, drag, reset, navigation,
hint requests and solve presentation invalidate it before delegating to the
existing methods. Natural completion restores status with `_update_all()`;
no old status string is replayed. Copy uses the existing status font and
measures available width before selecting the specified shorter fog copy.

`tools/unknown_smoke.gd` checks each beat's posts, full stage data, progress,
save content, hint state, stage index/count and solve truth. It also checks
hidden density/frost/question marks, input availability, selected-cell-only
emphasis, eight cancellation paths, early input before Beat1, session-only
replay suppression, natural progression and persisted resume at Stage004,
WHISPER priority after navigation, SHADOW INK solve reveal, NEXT breath,
copy width and all control bounds at 405x900, 676x900 and 720x900.

```sh
bash tools/godot_checked.sh --headless --fixed-fps 120 --path . \
  --script res://tools/unknown_smoke.gd
```

The smoke uses isolated disposable `user://unknown_smoke_case_*.json` files,
never the player's save. Optional real-render captures of all three beats
are enabled by `SHADOW_SUM_CAPTURE_DIR` with an absolute output directory;
omit `--headless` when capturing. Real OpenGL captures verified the full copy
fits at 405px and the chosen fogged cell retains its question mark and frost.
These are implementation/visual checks, not a claim of human comprehension
testing with an unbriefed participant.

The previous SHADOW INK smoke now verifies its exact script in the inheritance
chain; the new smoke pins `unknown_main.gd` as the scene root. All previous
behavior assertions remain. CI includes the new checked UNKNOWN step.
