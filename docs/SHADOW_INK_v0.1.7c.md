# SHADOW SUM v0.1.7c SHADOW INK Motion Polish

## Goal

Turn the static GLASS & METAL materials into a quiet time-based optical experience.

The pass must make three moments feel physical:

1. shadow density seeps into frosted glass instead of switching;
2. a Post seats into a Socket like a small precision part;
3. solving reveals hidden TARGET shadow as a calm final settling, not a celebratory flash.

This is still presentation-only. Puzzle rules, authored stages, save/progress, hints, Post count, drag/magnetic semantics, and solve conditions are frozen.

The desired feeling is: **ink settling inside glass in a dark optical instrument**.

## Current baseline

v0.1.7b is fully GREEN on Godot 4.7 stable.

Important existing behavior:

- `feel_polish_main.gd` already tweens the semantic LIVE StyleBox colors for 0.18s and applies a tiny scale breath.
- `glass_metal_main.gd` owns mouse-transparent `ShadowGlassVisual`, `SocketVisual`, and `PostVisual` material overlays.
- drag preview calls `_update_live_cell()` repeatedly while moving.
- `flow_main.gd` uses `SOLVE_BREATH = 0.45` before enabling NEXT.
- v0.1.7b keeps explicit `?` on hidden TARGET cells. Do not remove it in this pass.
- CI uses `tools/godot_checked.sh`; any Godot ERROR diagnostics must fail CI even when Godot exits zero.

Do not implement a second competing full-cell color tween. The semantic background tween remains authoritative. SHADOW INK adds material motion on top.

## Architecture

Add a new top presentation layer:

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
```

`scenes/main.tscn` should point to `res://src/shadow_ink_main.gd`.

Preferred new file:

```text
src/shadow_ink_main.gd
tools/shadow_ink_smoke.gd
docs/SHADOW_INK_v0.1.7c.md
```

Expected updates:

```text
src/ui/shadow_glass_visual.gd
src/ui/post_visual.gd
src/night_tokens.gd
src/main.gd                 # solve presentation only, if needed
src/interaction_main.gd     # motion constants only, if needed
.github/workflows/godot-smoke.yml
```

Do not move authoritative state into visual nodes.

## Motion principles

- no idle looping animation;
- no particles;
- no screen shake;
- no elastic/cartoon bounce;
- no neon flash;
- no continuously moving fog or grain;
- every motion must correspond to an actual state change;
- latest state always wins over an in-flight visual tween;
- motion must remain calm at bedtime brightness.

Use SINE / QUAD easing unless a tiny mechanical seat benefits from a restrained BACK ease.

## 1. Shadow ink seep

### Semantic contract

The underlying shadow levels remain exact integers 0, 1, 2, 3.

`ShadowGlassVisual` may keep a floating presentation value such as `display_level`, but it must never become puzzle state.

### Visual behavior

When LIVE changes:

- 0 → 1: a thin smoky veil settles into the glass;
- 1 → 2: ink appears to deepen inward;
- 2 → 3: the deepest level should feel heavier, not brighter;
- decreases recede slightly faster than increases;
- the top glass reflection and deterministic grain remain stable.

Do not redraw animated random noise.

Suggested material-only alpha mapping:

```text
display 0 = 0.00 extra ink
display 1 = 0.035
display 2 = 0.075
display 3 = 0.120
```

Tune after real-screen QA. Preserve readability above texture.

### Timing

Suggested starting values:

```text
INK_SEEP_BASE        0.18s
INK_DEEPEN_2         0.20s
INK_DEEPEN_3         0.23s
INK_RECEDE           0.15s
INK_PREVIEW          0.09s
```

Drag preview must use the shorter preview timing so the shadow never trails behind the pointer.

### Tween ownership

Each `ShadowGlassVisual` should own at most one active ink tween.

Before starting a new transition:

1. kill the previous tween if valid;
2. begin from the current presentation value;
3. tween to the latest requested value.

Do not queue transitions.

Provide an immediate setter for stage load/reset so Stage B never morphs from Stage A.

## 2. Hidden fog motion

Hidden TARGET remains explicit `?` in v0.1.7c.

The fog may move only on state transitions:

- when a hidden clue first appears after loading a stage, allow a single subtle 0.20–0.30s fog-settle;
- no repeating breath;
- when solved, fog fades away while the real density settles in.

The Stage 004 teaching/onboarding copy is explicitly deferred.

## 3. Post mechanical seat

The Post should feel seated, not selected.

### Tap placement

After authoritative placement:

- PostVisual appears slightly lifted;
- moves down 1.5–2.5 logical px;
- specular/rim briefly tightens;
- settles at 1.00 scale.

Suggested total: 0.14–0.18s.

### Drag release

Keep all current drag/magnetic state semantics.

After a valid drop:

- no large bounce;
- target Socket briefly warms;
- Post settles once;
- source Socket returns quietly.

If current Button bounce in `interaction_main.gd` fights the metal illusion, presentation-only constants may be reduced. Suggested target scale envelope:

```text
0.94 → 1.018 → 1.00
```

Do not change hit testing, threshold, magnetic radius, source/target logic, or commit timing.

### Invalid/same-socket release

No reward bounce. Use the existing soft cancel behavior.

## 4. Solve: hidden world settles into view

The solve payoff should become quieter than the old gold wave.

Required order:

1. authoritative solve happens immediately as today;
2. hidden TARGET cells lose fog;
3. their true shadow density settles in;
4. a restrained warm glint may pass once;
5. NEXT still becomes available after the existing solve breath.

The final effect should read as **the missing observation becoming visible**, not a victory explosion.

### Timing constraint

Everything important must fit inside the existing `SOLVE_BREATH = 0.45s`.

Suggested hidden-cell stagger:

```text
SOLVE_HIDDEN_STAGGER 0.012–0.014s
SOLVE_INK_SETTLE     0.17–0.19s
SOLVE_GLINT          <= 0.12s
```

Stagger hidden TARGET cells only. Do not run a 25-cell gold parade.

If the existing `main.gd::_play_solve_beat()` / `_reveal_hidden_target_cells()` presentation conflicts with this goal, it is acceptable to refactor those presentation methods while preserving:

- immediate `stage_solved` truth;
- `flow_main.gd` solve serial;
- 0.45s NEXT breath;
- progress persistence timing;
- all existing solve tests.

Do not bypass `flow_main.gd`.

## 5. Animation cancellation / stale state

This is a hard requirement.

Stage change, RESET, BACK, NEXT, or a newer drag preview must not allow an old tween to modify the new presentation.

Use one or both:

- per-visual tween kill;
- presentation serial/generation token owned by `shadow_ink_main.gd`.

Test RESET while ink is moving.

## 6. Sound boundary

Do not add new audio in v0.1.7c.

Existing micro-tones/chime remain for now. This pass should first prove the motion language visually.

Sound retuning is a later pass.

## 7. Responsive boundary

No motion code may change layout footprint.

Must remain GREEN at:

- 405×900
- 676×900
- 720×900

Visual children remain `MOUSE_FILTER_IGNORE`.

## 8. Automated QA

Add `tools/shadow_ink_smoke.gd` and run through `tools/godot_checked.sh`.

Minimum assertions:

### Scene / ownership

- main scene uses `shadow_ink_main.gd`;
- all four GLASS & METAL visual arrays remain 25;
- visual Controls remain mouse-transparent;
- motion nodes never mutate `posts`.

### Ink transition

- Stage002/003 density transitions begin from prior presentation state and converge to exact latest requested level;
- a second update during an active tween cancels/replaces the previous target;
- after enough time, presentation reaches the latest level;
- stage load/reset applies clean initial presentation, not prior-stage interpolation.

### Drag

- drag preview still does not mutate authoritative Posts;
- rapid target changes do not build a tween backlog;
- cancel restores presentation to authoritative Posts;
- valid drop still commits exactly once.

### Post seat

- occupied PostVisual remains present;
- placement/drag settle is presentation-only;
- source/target Socket state returns correctly.

### Hidden / solve

- Stage004 hidden cells retain `?` plus frosted state before solve;
- on a solved stage with hidden TARGET cells, fog is removed and the true level is visible by the end of the 0.45s solve breath;
- NEXT remains locked during breath and unlocks according to existing flow;
- RESET/stage change during a transition leaves no stale visual state.

### Full regression

Keep every existing smoke GREEN:

- feel
- interaction
- magnetic
- flow
- progress
- WHISPER HINTS
- MONOCHROME NIGHT
- GLASS & METAL
- 405×900 / 676×900 / 720×900

## 9. Human QA

After automated GREEN, inspect real rendered gameplay.

Ask:

1. Does 1→2→3 feel like shadow gaining depth inside glass rather than a UI tile changing color?
2. Does a Post feel heavier when it seats, without looking bouncy?
3. Is drag preview responsive enough to feel attached to the hand?
4. Does solve make hidden information quietly appear before NEXT asks for attention?
5. Can the game sit idle indefinitely without anything shimmering or pulsing?

The last answer must be yes.

## 10. Explicit non-goals

Do not add:

- Tripo/3D assets;
- shaders that require a new rendering architecture;
- animated random grain;
- particles;
- BGM/new SE;
- Stage004 onboarding copy;
- Daily Shadow;
- ads;
- achievements;
- stage changes;
- puzzle logic changes.

Tripo exploration can begin after v0.1.7c is GREEN.

## Done definition

v0.1.7c is complete when:

- SHADOW INK motion is visible but restrained;
- no gameplay state is owned by animation code;
- rapid drag updates remain responsive;
- solve reveal completes within the current flow breath;
- no stale tween survives reset/navigation;
- all Godot 4.7 headless CI steps are GREEN;
- a real screenshot/video reads as a quiet optical toy, not an animated UI dashboard.


## Implementation and verification

`shadow_ink_main.gd` is the entry presentation layer. It replaces only the
solve-material, Post-seat, magnetic-capture and panel-motion hooks; the
existing interaction/flow/progress/hint methods still own all decisions.
`SOLVE_BREATH` remains 0.45s. No assets, audio, rules, or stages were added.

Glass uses one replaceable tween for floating ink density, fog and glint.
Ordinary increase durations are 0.18/0.20/0.23s, recession 0.15s, and preview
0.09s. Switching into preview replaces an in-flight normal tween even when
its integer target is unchanged. The existing 0.18s semantic StyleBox tween
is retained, now replacing its predecessor from the currently displayed
color. No second full-cell color tween was introduced. Fixed grain and top
reflection do not move; only an inset ink veil changes opacity.

Post seating transforms drawing coordinates, never the Button hit target:
0.94 -> 1.018 -> 1.0 over 0.17s with a 2px downward seat and fading specular.
Invalid/same-socket releases do not invoke this hook. Existing cell wipes,
squashes and the 25-cell solve wave are replaced by material feedback.
Existing overlap tones are preserved behind a presentation generation check.

Only authored hidden TARGET cells reveal. Their authored solution density
uses the same source as the previous reveal, so alternative valid placements
do not change the authored reveal contract. Fog exposes the true background,
ink settles in 0.18s, then a warm edge glint lasts 0.05s. Hidden-only stagger
is 0.012s, capped at 0.20s for a worst-case future board: total <= 0.43s.
`?` and frost remain until solve. Visible TARGET cells do not join the effect.

Stage/reset cancels every material tween, clears preview, invalidates delayed
presentation feedback and snaps fresh values. Existing NEXT invitation and
pick-ghost tweens now have cancellable ownership too; flow serial and commit
timing are unchanged.

Run timing assertions with deterministic 120Hz simulation (avoids a long
headless startup frame skipping the midpoint observation):

```sh
SHADOW_SUM_PROGRESS_PATH=user://shadow_ink_smoke_progress.json \
  bash tools/godot_checked.sh --headless --fixed-fps 120 --path . \
  --script res://tools/shadow_ink_smoke.gd
```

The smoke covers all authored hidden stages, real Stage002/003 density,
interrupted targets, 13 rapid socket crossings, cancel, duplicate release,
seat geometry, reset during drag, reset/load/BACK/NEXT during reveal, and
existing breath timing. GLASS smoke checks the actual script inheritance
chain rather than pinning the root to its superseded entry script; all of
its inventory and behavior checks remain. SHADOW INK separately pins the
new root script. Existing layout smoke covers all three required sizes.

For repeatable real-render inspection (OpenGL, not headless), set an absolute
output folder and use `tools/shadow_ink_capture.gd` with `--fixed-fps 60`.
It captures Stage003 density/seat, Stage004 frost/reveal/reset, rapid drag,
cancel and valid release as 110 frames at 405x900. The captured scenario ends
at rest; there is no idle animation in the new materials.
