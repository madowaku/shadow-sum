# SHADOW SUM v0.1.5 — KEEP THE LIGHT Progress Pass

## Goal

Turn the 18-stage prototype into a small campaign that remembers achievement without putting a menu wall between the player and the next puzzle.

## Persistence contract

Save file:

`user://shadow_sum_progress_v0_1.json`

Stored data is intentionally minimal:

```json
{
  "version": 1,
  "completed": [1, 2, 3]
}
```

Only first-time stage clears are persisted.

We deliberately do **not** persist:

- current Post placement,
- drag preview state,
- animation state,
- solve-breath timers,
- partially solved boards.

On restart, the player receives a clean board at the first unsolved stage.

## Resume behavior

- Fresh save → Stage 001.
- Stages 001–003 cleared → Stage 004.
- All 18 cleared → Stage 018, with the full campaign marked complete.
- Invalid, unreadable, or version-mismatched data falls back safely to a fresh campaign.

## Difficulty-band unlocks

The campaign remains linear in v0.1.5.

| Band | Stages | Unlock condition |
|---|---:|---|
| INTRO | 001–003 | available at start |
| EASY | 004–006 | clear Stage 003 |
| MEDIUM | 007–009 | clear Stage 006 |
| HARD | 010–012 | clear Stage 009 |
| ECLIPSE | 013–015 | clear Stage 012 |
| UMBRA | 016–018 | clear Stage 015 |

When a boundary stage is cleared, the newly available band is announced with a small `<TIER> LIGHT UNLOCKED` beat. It should not interrupt the existing full-shadow solve payoff.

## Replay navigation

A compact `‹ BACK` button is added to the existing footer.

Rules:

- BACK may move only to earlier stages.
- Cleared stages can be replayed from a fresh board.
- While replaying a cleared stage, NEXT may advance through already-cleared history.
- Navigation may never skip beyond the first currently unsolved stage.
- Solving a replayed stage does not rewrite or duplicate progress.

## In-play progress display

The existing Post counter gains a quiet campaign indicator:

`POSTS  2 / 4   ·   LIGHT  7 / 18`

No separate stage-select screen is required for v0.1.5.

## QA contract

`tools/progress_smoke.gd` verifies:

1. fresh profile starts at Stage 001,
2. Stage 001 clear is written to disk,
3. a new game instance resumes at Stage 002,
4. BACK exposes cleared history,
5. clearing the Intro trio unlocks EASY,
6. another new instance resumes at Stage 004,
7. NEXT can return from replayed history to the first unsolved puzzle.

All CI smoke tests use isolated progress files so one test cannot contaminate another.
