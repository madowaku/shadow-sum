# Jev flagged shortlist review: GR28 / GR30 / GR31 / GR34 / GR36

This is a **human-review shortlist**, not an automatic rewrite of `grant36_v0_4_draft.json`.

The exact validator remains authoritative for correctness. This pass compares the five slots most worth inspecting after Jev's second review and the generator metrics.

## Summary

| Slot | Current | Best comparison target | Action before Godot integration |
|---|---|---|---|
| GR28 | `three_plate_light_shutter-005` | `three_plate_light_shutter-006` | **A/B, lean replacement** |
| GR30 | `fog_plate_shutter-010` | `fog_plate_shutter-005` | **Keep current; no pre-playtest replacement** |
| GR31 | `fog_height_light-007` | `fog_height_light-006` (diversity wildcard), `-003` (cleaner same idea) | **A/B before lock** |
| GR34 | `dense_height_plate_shutter-017` | `dense_height_plate_shutter-004` | **A/B; broaden beyond Jev's same-texture alternatives** |
| GR36 | `finale-015` | `finale-010` | **A/B, lean finale-010** |

## GR28

Current:
`three_plate_light_shutter-005`

- score 32.6533
- witness 8
- d<=2 131
- overlap 1
- reasoning: `OVERLAP -> SHADOW -> ZERO -> ORIENTATION -> LIGHT -> SHUTTER`
- Jev distinctness: 1.57
- Jev Choice preferred `three_plate_light_shutter-006`

Comparison:
`three_plate_light_shutter-006`

- score 32.3115
- witness 8
- d<=2 85
- overlap 1
- reasoning: `OVERLAP -> SHADOW -> LIGHT -> PLATE_ABSENCE -> ZERO -> SHUTTER -> ORIENTATION`

Why test the alternate:
the candidate has the same mechanic family and witness length, but the reasoning trace explicitly routes through Light and Plate absence before the final orientation. That is a more legible causal decomposition than the current candidate's more generic ZERO/ORIENTATION chain.

**Lean: replace -005 with -006 if the A/B playtest confirms the trace feels cleaner.**

## GR30

Current:
`fog_plate_shutter-010`

- score 35.4135
- witness 8
- d<=2 128
- FOG 3
- overlap 1
- edge rays 0
- zero dependency true
- plate-direction dependency true
- reasoning: `OVERLAP -> SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`

Jev's Choice still preferred the current candidate even though keep probability was only 0.50.

The strongest nearby same-family candidates either:
- are already selected elsewhere (`fog_plate_shutter-002` is GR32), or
- lose the overlap opening and need a longer witness (`-005`), or
- do not depend on Plate directional absence (`-009`).

**Lean: keep GR30 unchanged for the first human playtest.**

## GR31

Current:
`fog_height_light-007`

- score 33.3811
- witness 10
- d<=2 168
- FOG 5
- reasoning: `SHADOW -> REACH -> ZERO -> LIGHT -> TYPE`
- reach-dependency flag: false
- Jev distinctness: 1.80

Cleaner same-idea alternative:
`fog_height_light-003`

- score 32.7444
- witness 10
- d<=2 116
- FOG 3
- same reasoning signature
- reach dependency true

Diversity wildcard:
`fog_height_light-006`

- score 31.1401
- witness 9
- d<=2 130
- FOG 3
- reach dependency true
- reasoning: `REACH -> SHADOW -> ZERO -> TYPE -> LIGHT`

The current candidate is valid, but it uses five fogged cells and its uniqueness does not actually depend on the Tall-reach evidence even though REACH appears in the greedy trace.

**Lean: A/B current -007 against -006.**
If -006 is too obvious, use -003 as the conservative replacement.

## GR34

Current:
`dense_height_plate_shutter-017`

- score 38.9115
- witness 10
- d<=2 85
- overlaps 4
- reasoning: `OVERLAP -> SHADOW -> ORIENTATION -> TYPE -> ZERO -> SHUTTER`
- Jev distinctness 1.84
- Jev deduction 2.49
- Jev global pass marked GR34 the weakest dense slot.

The Jev-listed strongest alternate `dense_height_plate_shutter-014` is already GR33, so it cannot fix sequence redundancy without reshuffling GR33 too.

A broader wildcard is:
`dense_height_plate_shutter-004`

- score 31.8756
- witness 8
- d<=2 33
- overlaps 4
- reasoning: `OVERLAP -> TYPE -> SHADOW -> SHUTTER -> ORIENTATION`
- zero dependency false
- mechanic-interaction component 8.1

It scores lower under the generator, but it changes the solve texture substantially: TYPE is promoted early and ZERO is not required.

**Lean: do not auto-replace GR34, but A/B -017 versus -004.**
This is exactly the kind of case where human feel matters more than generator rank.

## GR36

Current:
`finale-015`

- score 38.2470
- witness 10
- d<=2 92
- overlaps 2
- edge rays 0
- zero dependency false
- Tall-reach dependency false
- Plate-direction dependency false
- reasoning: `OVERLAP -> SHADOW -> REACH -> LIGHT -> ORIENTATION -> TYPE -> SHUTTER`
- Jev finale strength 2.40

Strong finale comparison:
`finale-010`

- score 37.7708
- witness 10
- d<=2 167
- overlap 1
- edge rays 0
- Tall-reach dependency true
- Plate-direction dependency true
- reasoning: `OVERLAP -> SHADOW -> REACH -> PLATE_ABSENCE -> TYPE -> ZERO -> LIGHT -> ORIENTATION -> SHUTTER`

The current finale has a higher base score and Jev preferred it in the four-way Choice, but the dependency tests reveal an important design difference: `finale-010` more clearly requires the learned HEIGHT and PLATE evidence to establish uniqueness.

`finale-002` is also deep (d<=2 217, Plate/zero dependencies true) but pays a substantial edge-abuse penalty, so it is less attractive as the clean final statement.

**Lean: A/B finale-015 versus finale-010, with a design preference toward finale-010 if it remains readable in play.**

## Proposed human A/B set

Only five focused comparisons are needed:

1. GR28: `-005` vs `-006`
2. GR30: current `-010` only, unless it feels weak in play
3. GR31: `-007` vs `-006`; keep `-003` as fallback
4. GR34: `-017` vs `-004`
5. GR36: `-015` vs `-010`

Do not modify the canonical draft until these are playable side-by-side or sequentially in a review campaign.
