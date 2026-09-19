# Release direction and player comfort

## Content plan (working hypothesis)

Target the first release at 100 curated puzzles, arranged as five chapters of
roughly 20. Prototype the first 15–20 as the free experience; decide the final
boundary from first-time playtests, not a fixed content quota. Chapter purchase
or a clearly scoped full unlock fits the quiet product better than forced ads.
No monetization or storefront commitment is implemented by this document.

Ship later chapters when ready (20–30 puzzles is a useful working batch), with
100-puzzle packs reserved for major updates. Do not promise a recurring quantity
before observing completion and purchase demand. Avoid rotation/mirror padding.
Every puzzle needs uniqueness verification, an intended deduction and human
playtesting. Existing Stage001–018 stay unchanged in this pass.

Priority after comfort: bridge the reasoning transitions around Stage012 and
Stage017, then observe 5–8 first-time Android players before authoring the rest.
Track mis-taps, understanding of unknown versus zero, deductions, stuck points
and voluntary continuation. Small playtests diagnose usability, not popularity.

## Comfort implementation

`comfort_main.gd` extends `unknown_main.gd`. The existing rule, magnetic/drag,
hint catalog, clear progress schema and solve-breath owners are unchanged.

- UNDO reverses one accepted placement, removal or drag move. Preview/cancel,
  no-op and rejected placement do not add history. Reset of an unfinished board
  is also one undoable action. A clear closes history; completed rewards are not
  rolled back. History is session-local (latest 100 actions) and clears on stage
  navigation. Undo cancels old presentation/hint callbacks, keeping hint usage.
- A separate `<progress_path>.session.json` stores the current unfinished board
  after committed changes, reset and stage navigation, plus app pause/focus loss.
  This is a current-puzzle checkpoint, not a per-stage archive. Navigation keeps
  its existing fresh-board behavior; restarting restores the current board.
- Restore validates version, clear signature, unlocked stage ID, puzzle
  fingerprint, dimensions, boolean values and Post count. It rejects a solved
  snapshot rather than awarding progress. Malformed/stale saves safely fall back
  to the existing first-unfinished-stage behavior. Writes use a temporary file
  and rename so the previous checkpoint survives interrupted writes.
- Only canonical Posts are saved, including during a drag. No previews, Tween
  state, or onboarding/hint state are persisted. Restored glass appears directly.
- Five footer controls retain the instrument style, with 44 logical-pixel
  height and responsive widths. Board hit targets and drag timing are unchanged.
