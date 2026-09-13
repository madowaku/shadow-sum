# SHADOW SUM v0.1.6 — WHISPER HINTS Implementation Spec

## Goal

WHISPER HINTS must preserve the feeling of solving the puzzle yourself.
The system may illuminate **where to think** and **what kind of reasoning to try**, but it must not place Posts, mutate puzzle state, or directly reveal the answer.

Core principle:

> Show the doorway, not the room behind it.

This pass introduces the UI contract, data format, animation grammar, and first authored hints for Stage 003, Stage 012, and Stage 013.

---

## 1. Player-facing UI

### Footer

Current footer:

`‹ BACK   RESET   NEXT ›`

v0.1.6 footer:

`‹ BACK   RESET   HINT ◐   NEXT ›`

The HINT button is disabled after the stage is solved.

### Button states

| State | Button text |
|---|---|
| No whisper shown | `HINT ◐` |
| Whisper I shown | `HINT I` |
| Whisper II shown | `HINT II` |
| Whisper III shown | `HINT III` |
| No more whispers | `HINT III` disabled |
| Solved stage | disabled |

The player may continue playing between whispers. Pressing HINT again advances to the next authored whisper for that stage.

### Status text

Whisper text temporarily replaces the normal status line for ~3.2 seconds, then the ordinary stage status returns unless the player has already changed stage/reset/solved.

No modal dialog is used for ordinary whispers.

---

## 2. Hint philosophy

A whisper may:

- pulse one or more TARGET cells;
- pulse one or more Placement Board sockets;
- emphasize the Post counter;
- run a short ordered visual chain;
- suggest an assumption or comparison in one sentence.

A whisper must never:

- add/remove/move a Post;
- write to the authoritative `posts` array;
- mark a socket as definitely correct/incorrect with permanent UI;
- auto-solve a step;
- expose the full solution array;
- survive a stage change or RESET;
- count as stage progress.

All whisper visuals are temporary and cosmetic.

---

## 3. Visual grammar

### TARGET focus

A clue cell receives a soft cyan-gold outline pulse:

- scale: `1.00 → 1.045 → 1.00`
- duration: ~0.42 s
- repeat: 2 unless otherwise authored
- do not change the displayed shadow value

### Socket focus

A Placement Board socket receives a thin warm ring:

- no Post preview
- no shadow preview
- scale: `1.00 → 1.06 → 1.00`
- duration: ~0.38 s

### Counter emphasis

The `POSTS x / y` portion of the counter line briefly brightens.
`LIGHT x / 18` must not brighten at the same time, to avoid confusing puzzle inventory with campaign progress.

### Assumption effect

For contradiction teaching only:

- `assume_empty`: draw a faint hollow ring / small `○` overlay on a socket
- `assume_filled`: draw a faint translucent Post silhouette

These are visual thought experiments only. They must never call `ShadowRules.compute_shadow()` with a changed authoritative state and must not persist after the sequence ends.

### Contradiction effect

A target clue may briefly receive a muted red edge pulse to indicate that an assumption has made the clue impossible.
Avoid loud failure audio. This is a reasoning cue, not a punishment.

---

## 4. Data format

Stage JSON gains an optional `whispers` array.

```json
"whispers": [
  {
    "id": "003-1",
    "kind": "focus",
    "access": "free",
    "text": "Start with the darkest shadow.",
    "targets": [
      { "surface": "clue", "cell": "C3", "effect": "pulse" }
    ]
  }
]
```

### Whisper object

| Field | Required | Values / meaning |
|---|---:|---|
| `id` | yes | Stable unique ID, e.g. `012-2` |
| `kind` | yes | `focus`, `compare`, `assume`, `chain` |
| `access` | yes | `free` or `deep` |
| `text` | yes | Short English player-facing whisper |
| `targets` | no | Simultaneous visual targets |
| `sequence` | no | Ordered visual events |
| `emphasize_post_counter` | no | Boolean |

### Target object

```json
{
  "surface": "clue",
  "cell": "D1",
  "effect": "pulse"
}
```

`surface`:

- `clue`
- `socket`

`effect`:

- `pulse`
- `assume_empty`
- `assume_filled`
- `forced_empty`
- `forced_filled`
- `contradiction`

`forced_*` effects are only used inside authored reasoning chains and are shown as temporary ghost annotations. They are not persisted player notes.

### Sequence event

```json
{
  "delay": 0.32,
  "surface": "socket",
  "cell": "C2",
  "effect": "forced_filled"
}
```

Events are played in ascending `delay` order.

---

## 5. Runtime architecture

Add:

`src/hint_main.gd`

Inheritance chain:

`main → feel → feel_polish → interaction → magnetic → flow → progress → hint`

`scenes/main.tscn` should point to `res://src/hint_main.gd`.

### Runtime state

Suggested fields:

```gdscript
var hint_button: Button
var whisper_index := 0
var whisper_serial := 0
var whisper_tweens: Array[Tween] = []
```

### Lifecycle

On `_load_stage()` and `_reset_stage()`:

- increment `whisper_serial`;
- stop/kill active whisper tweens;
- clear assumption overlays;
- reset `whisper_index = 0`;
- restore button text to `HINT ◐`.

On solve:

- disable HINT;
- cancel active whisper visuals;
- let the existing solve flow own the screen.

Hint progression is **not saved** in `KEEP THE LIGHT` progress.

---

## 6. Stage 003 — BLACK CORE

Purpose: teach the meaning of `▓ = 3` without a tutorial modal.

Target clue `C3` has exactly three possible sources: `C2`, `B3`, `D3`.
All three are Posts in the unique solution.

### Whisper I

**Text:**

`Start with the darkest shadow.`

**Visual:** TARGET `C3` pulses twice.

```json
{
  "id": "003-1",
  "kind": "focus",
  "access": "free",
  "text": "Start with the darkest shadow.",
  "targets": [
    { "surface": "clue", "cell": "C3", "effect": "pulse" }
  ]
}
```

### Whisper II

**Text:**

`Which three sockets can reach it?`

**Visual:** clue `C3`, then sockets `C2`, `B3`, `D3` pulse.

```json
{
  "id": "003-2",
  "kind": "chain",
  "access": "free",
  "text": "Which three sockets can reach it?",
  "sequence": [
    { "delay": 0.00, "surface": "clue", "cell": "C3", "effect": "pulse" },
    { "delay": 0.26, "surface": "socket", "cell": "C2", "effect": "pulse" },
    { "delay": 0.34, "surface": "socket", "cell": "B3", "effect": "pulse" },
    { "delay": 0.42, "surface": "socket", "cell": "D3", "effect": "pulse" }
  ]
}
```

### Whisper III

**Text:**

`Three shadows means all three sources are present.`

**Visual:** `C2`, `B3`, `D3` receive simultaneous warm rings.

```json
{
  "id": "003-3",
  "kind": "focus",
  "access": "free",
  "text": "Three shadows means all three sources are present.",
  "targets": [
    { "surface": "socket", "cell": "C2", "effect": "pulse" },
    { "surface": "socket", "cell": "B3", "effect": "pulse" },
    { "surface": "socket", "cell": "D3", "effect": "pulse" }
  ]
}
```

All Stage 003 whispers are free because this is core-rule teaching.

---

## 7. Stage 012 — DIFFERENCE

Purpose: introduce subset/global-count reasoning.

Important solver fact:

After the normal PURE deductions, `B3`, `C4`, and `D5` are forced Posts. One Post remains globally.
The visible clue at `D1` is `░ = 1` and its only sources are `C1` and `E1`.
Therefore that clue already accounts for the single remaining Post, which means every other still-undecided socket outside `{C1, E1}` must be empty.

This is the cleanest human-facing introduction to the stage's SUBSET step.

### Whisper I

**Text:**

`Clear the certain shadows first.`

**Visual:** focus the key PURE anchors `B4` and `C5` plus nearby zero clue `A5`.

```json
{
  "id": "012-1",
  "kind": "focus",
  "access": "free",
  "text": "Clear the certain shadows first.",
  "targets": [
    { "surface": "clue", "cell": "A5", "effect": "pulse" },
    { "surface": "clue", "cell": "B4", "effect": "pulse" },
    { "surface": "clue", "cell": "C5", "effect": "pulse" }
  ]
}
```

### Whisper II

**Text:**

`This shadow already needs the last remaining Post.`

**Visual:** emphasize the Post counter; pulse clue `D1`; then pulse sockets `C1` and `E1`.

```json
{
  "id": "012-2",
  "kind": "compare",
  "access": "free",
  "text": "This shadow already needs the last remaining Post.",
  "emphasize_post_counter": true,
  "sequence": [
    { "delay": 0.00, "surface": "clue", "cell": "D1", "effect": "pulse" },
    { "delay": 0.28, "surface": "socket", "cell": "C1", "effect": "pulse" },
    { "delay": 0.36, "surface": "socket", "cell": "E1", "effect": "pulse" }
  ]
}
```

The text is intentionally phrased as a reasoning cue, not `C1/E1 is the answer`.

### Whisper III

**Text:**

`If that shadow uses the last Post, every other undecided socket must be empty.`

**Visual:** pulse `D1`, pulse `C1/E1`, then briefly dim/ring the remaining undecided sockets using `forced_empty` ghost marks.
Do not place either `C1` or `E1`.

```json
{
  "id": "012-3",
  "kind": "chain",
  "access": "free",
  "text": "If that shadow uses the last Post, every other undecided socket must be empty.",
  "emphasize_post_counter": true,
  "sequence": [
    { "delay": 0.00, "surface": "clue", "cell": "D1", "effect": "pulse" },
    { "delay": 0.22, "surface": "socket", "cell": "C1", "effect": "pulse" },
    { "delay": 0.22, "surface": "socket", "cell": "E1", "effect": "pulse" }
  ]
}
```

Stage 012 is a technique-teaching stage, so all three whispers remain free.

---

## 8. Stage 013 — FALSE SHADOW

Purpose: introduce contradiction / failed-literal reasoning.

Human teaching path:

1. Normal PURE deductions establish several empty cells and force `C1` as a Post.
2. Choose uncertain socket `A2`.
3. Assume `A2` is empty.
4. That assumption forces `C2` and `B3` to be Posts.
5. Further consequences force `A3` and `C3` empty.
6. The visible `░` clue at `B3` then has no possible source left, contradiction.
7. Therefore `A2` cannot be empty.

The game does not state the final conclusion; the player makes it.

### Whisper I

**Text:**

`When deduction stops, test one uncertain socket.`

**Visual:** socket `A2` pulses softly.

```json
{
  "id": "013-1",
  "kind": "assume",
  "access": "free",
  "text": "When deduction stops, test one uncertain socket.",
  "targets": [
    { "surface": "socket", "cell": "A2", "effect": "pulse" }
  ]
}
```

### Whisper II

**Text:**

`Suppose A2 were empty. Follow what that forces.`

**Visual:** temporary `assume_empty` mark on `A2`, then pulse affected clues/sockets.

```json
{
  "id": "013-2",
  "kind": "assume",
  "access": "free",
  "text": "Suppose A2 were empty. Follow what that forces.",
  "sequence": [
    { "delay": 0.00, "surface": "socket", "cell": "A2", "effect": "assume_empty" },
    { "delay": 0.36, "surface": "socket", "cell": "C2", "effect": "forced_filled" },
    { "delay": 0.52, "surface": "socket", "cell": "B3", "effect": "forced_filled" }
  ]
}
```

### Whisper III

**Text:**

`That assumption leaves B3 with no possible source.`

**Visual chain:** `A2 empty → C2/B3 filled → A3/C3 empty → clue B3 contradiction`.

```json
{
  "id": "013-3",
  "kind": "chain",
  "access": "free",
  "text": "That assumption leaves B3 with no possible source.",
  "sequence": [
    { "delay": 0.00, "surface": "socket", "cell": "A2", "effect": "assume_empty" },
    { "delay": 0.24, "surface": "socket", "cell": "C2", "effect": "forced_filled" },
    { "delay": 0.34, "surface": "socket", "cell": "B3", "effect": "forced_filled" },
    { "delay": 0.56, "surface": "socket", "cell": "A3", "effect": "forced_empty" },
    { "delay": 0.66, "surface": "socket", "cell": "C3", "effect": "forced_empty" },
    { "delay": 0.92, "surface": "clue", "cell": "B3", "effect": "contradiction" }
  ]
}
```

Stage 013 is the first contradiction tutorial, so all whispers are free.

---

## 9. Rewarded-ad seam

WHISPER HINTS should be implemented so monetization can be attached later without changing stage content.

The stage data therefore uses:

- `access: "free"`
- `access: "deep"`

The hint runtime asks an access service whether a `deep` whisper is available. It does **not** know or care whether access came from:

- a rewarded ad;
- a paid ad-free/premium unlock;
- a promotional free unlock;
- a debug flag.

Suggested interface:

```gdscript
func can_use_whisper(stage_id: int, whisper_id: String, access: String) -> bool
func request_deep_whisper(stage_id: int, whisper_id: String) -> void
```

For v0.1.6 prototype, all authored whispers may temporarily resolve as available so the UX can be playtested before monetization is added.

---

## 10. Recommended monetization rule

Do **not** gate core teaching behind ads.

Always free:

- Stage 001–003 teaching;
- Stage 012 SUBSET introduction;
- Stage 013 contradiction introduction;
- Whisper I on every stage.

Possible rewarded-ad candidates later:

- Stage 014–018 Whisper III (`DEEP WHISPER`);
- optionally Stage 014–018 Whisper II after playtesting, but only if the free first whisper remains genuinely useful.

Recommended player-facing rewarded flow:

`HINT II` used

→ button becomes `DEEP WHISPER  ▷ AD`

→ player taps

→ small disclosure sheet:

**Deep Whisper**

`Watch one ad to unlock the final hint for this puzzle.`

Buttons:

`WATCH AD`

`NOT NOW`

If the ad completes successfully, unlock exactly that stage's Deep Whisper and show it immediately or enable the button.
If the ad is skipped/closed/fails, return to the puzzle with no penalty.

Avoid copy such as `Support the developer by watching an ad` in the reward prompt. The prompt should describe the transaction neutrally and accurately.

---

## 11. QA requirements

Automated `tools/hint_smoke.gd` should verify at minimum:

1. HINT button appears and starts at `HINT ◐`.
2. Stage 003 Hint I pulses clue C3 without changing `posts`.
3. Hint progression advances I → II → III.
4. Stage 012 counter emphasis / targets do not mutate puzzle state.
5. Stage 013 assumption/forced/contradiction overlays do not mutate puzzle state.
6. RESET cancels all hint visuals and resets hint index.
7. Stage change cancels old hint coroutines/tweens.
8. Solving disables HINT.
9. Hint usage is not persisted in KEEP THE LIGHT save data.
10. Existing Feel, Interaction, Magnetic, Flow, Progress, and Layout smoke tests remain green.

---

## 12. Definition of done for v0.1.6

- HINT button implemented in 405×900 and 720×900 layouts.
- Generic authored hint renderer supports `focus`, `assume`, and `chain` behaviors.
- Stage 003 / 012 / 013 whispers are in stage data and playable.
- No hint mutates authoritative puzzle state.
- All teaching-stage whispers are free.
- Data model contains the future `deep` access seam, but no ad SDK is required for v0.1.6.
- Godot 4.7 CI is green.
