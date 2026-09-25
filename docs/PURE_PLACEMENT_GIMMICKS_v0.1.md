# NOXSUM PURE PLACEMENT GIMMICKS v0.1

Status: playable experiment target

## Goal

Test four mechanic families without changing the core player verb.

> The player only places NOX traces into sockets.

No walking controller, Sokoban movement, jump timing, or free object manipulation is introduced here. The board may become richer, but the input grammar stays placement-first.

## Experiment set

| IDs | Family | Core question |
| --- | --- | --- |
| PP01–PP03 | FIXED NOX | Can an already-known trace become useful evidence rather than a solved answer? |
| PP04–PP06 | SWITCH | Can placement itself reconfigure the light state without adding a separate switch action? |
| PP07–PP09 | BLOCKER | Can fixed furniture/machinery make the same socket see a different subset of lights? |
| PP10–PP12 | MIRROR | Can fixed mirrors bend illumination while the player still only places NOX? |

Each family follows **teach → combine → characteristic puzzle**.

## Shared rules

- Shadow Screen remains 5×5.
- Only NOX placement is directly controlled by the player.
- Apparatus cells occupied by BLOCKER or MIRROR are not legal NOX sockets.
- SWITCH cells remain legal sockets.
- Existing NOX pose/type rules remain available, but v0.1 intentionally uses SIT-only movable traces so the new optical rule is isolated during playtest.
- Existing campaigns keep their current optical model. New beam tracing is activated only for stages that contain `blockers` or `mirrors`.

## FIXED NOX

Schema:

```json
{
  "fixed_posts": ["C3"],
  "fixed_post_types": {"C3": "normal"}
}
```

A fixed trace contributes shadows normally, occupies its socket, cannot be moved, and counts toward exact inventory. The player places only the missing trace(s).

## Placement SWITCH

Schema:

```json
{
  "placement_switches": [
    {"cell": "B2", "on": ["BOTTOM"]},
    {"cell": "D4", "off": ["LEFT"], "on": ["RIGHT"]}
  ]
}
```

A switch is evaluated from the current placement state.

- If its cell is occupied by NOX, apply `off` first, then `on`.
- If it is empty, it has no effect.
- Lamp state updates live after placement.
- No separate switch button exists.

This is deliberately a **dual-purpose placement**: the trace both casts a shadow and changes the illumination.

## BLOCKER

Schema:

```json
{"blockers": ["C2", "B4"]}
```

A blocker occupies a board cell and stops a beam before it reaches traces behind it. It does not add a mark to the Shadow Screen by itself.

For a TOP beam, a blocker above a trace can remove that trace's downward contribution. The same trace may still be illuminated from LEFT/RIGHT/BOTTOM.

## MIRROR

Schema:

```json
{"mirrors": {"B2": "\\", "D2": "/"}}
```

Mirrors occupy board cells and redirect a beam by 90°.

`/`:
- down → left
- right → up
- up → right
- left → down

`\\`:
- down → right
- right → down
- up → left
- left → up

Parallel rays from one lamp are traced independently. Therefore one lamp can reach the same NOX trace through multiple paths. PP11 is built specifically to test whether that feels like a satisfying discovery rather than a rule-explanation burden.

## Stage intent

- **PP01**: one fixed trace, place one missing trace.
- **PP02**: fixed trace at a less-central location; read its contribution as baseline evidence.
- **PP03**: two fixed traces surround one missing cause.
- **PP04**: first switch. Correct placement turns on RIGHT.
- **PP05**: a switch trace turns on BOTTOM and also participates in the target.
- **PP06**: two switch cells alter different lamps; both are part of the unique three-trace solution.
- **PP07**: one blocker removes TOP contribution from the intended trace.
- **PP08**: two blockers make illumination position-dependent.
- **PP09**: four lamps exist, but machinery creates local light subsets.
- **PP10**: one mirror bends one TOP ray so D2 is hit from above and from the left.
- **PP11**: two mirrors make one TOP lamp reach C2 from three directions.
- **PP12**: keep the mirror insight, then solve a two-trace reconstruction.

## Playtest metrics

For each family record:

- READ: mechanism understood from the board before hints
- AHA: clear moment feels explanatory
- DEPTH: family appears capable of 10+ good puzzles
- NOXSUM: still feels like NOXSUM rather than a different puzzle game
- brute-force placements before realization
- whether a player tries to click/rotate apparatus despite it being fixed

Rate READ / AHA / DEPTH / NOXSUM from 1–5, but keep the comments and first spontaneous sentence after clear. The verbal reaction is often more diagnostic than the score.

## Keep gate

A family advances when:

1. the board communicates the apparatus without text-heavy teaching,
2. the player still thinks primarily about **where to place NOX**,
3. the apparatus changes deduction, not just presentation,
4. the characteristic third puzzle is more interesting than the teach puzzle,
5. the rule combines naturally with SIT / STAND / SLEEP / WARK and board shapes later.

v0.1 intentionally does **not** combine these four new families with each other. First find out which branch has teeth.
