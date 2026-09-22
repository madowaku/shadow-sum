# GR21–GR36 selection for human review

Draft only. Godot runtime/campaign wiring is unchanged.

Seed: `20260922`. Retained exact-unique, deduplicated candidates: **192**.
Bucket counts: `{"two": 48, "fog": 40, "three": 40, "dense": 40, "finale": 24}`. Independent exhaustive validation: **16/16 passed**.
Generation: **60.230s**; independent validation: **13.990s**; pipeline: **74.397s**.

These are reproducible search proxies, not a claim of measured human difficulty. Greedy witnesses are sufficient, not proven minimal; their evidence labels use the authored solution. Read the concrete eliminations below and playtest before integration.

## Reproduce

```text
python tools/generate_deep_calibration.py
python tools/validate_grant36_draft.py
```

## Scoring and selection

- **distributed_evidence**: 1.8 * min(greedy witness cells, 10) + 0.4 * (witness rows + columns).
- **causal_ambiguity**: 1.2 * log2(1 + distance<=2 states); no state-space-size reward.
- **overlap_quality**: 0.8 * min(overlap cells, 3) + 1.0 * overlap dependency.
- **negative_evidence_quality**: 1.2 * zero dependency + 1.2 * plate absence dependency.
- **mechanic_interaction**: 1.5 * intersecting object-footprint pairs + 0.7 * resolved uncertain families.
- **symmetry_penalty**: -3 if the full target is left/right symmetric.
- **edge_abuse_penalty**: -0.8 * off-board rays - 20 * max(0, off-board fraction - 0.15).
- **trivial_witness_penalty**: -3 * max(0, 4 - greedy witness cells).
- **long_witness_penalty**: -1.5 * max(0, greedy witness cells - 10); FOG additionally capped at 10 cells.
- **near_duplicate_penalty**: hard rejection: translated/reflected world, or <=2 common-visible differences within profile.
- **diversity_bonus**: selection only: +4 new family combination, +3 new reasoning signature, +2 changed first deduction.
- **selection_similarity_penalty**: -2 per previous selection of this physical profile.

All two/three-cause candidates have 3 objects; dense/finale have 4. Object position is a baseline variable, not an extra mechanic family. All positions are unrestricted and identical objects are unlabelled.

Quality gates: 6–17 nonzero cells before fog, at least one overlap, every object visible, <=25% lost rays, >=4 greedy witness cells; three/fog/dense/finale must include a 2–4-world intermediate deduction. FOG hides the strongest full-board first clue, increases first-step ambiguity, and retains exact uniqueness with 19–22 observed cells and at most 10 witness cells. Long witnesses lose score rather than earning unlimited difficulty credit.

Deduplication rejects translated or reflected solutions across the whole pool (including GR14–GR20 seeds), and targets differing in <=2 common observed cells within identical physical constraints (also across full/fog buckets), including reflection. Reflection here is an equivalence check, never a game mechanic.

Selection greedily maximizes the printed base + novelty - similarity score within fixed bucket quotas; equal scores use candidate ID. Adjacency cannot repeat family + reasoning signature. After selection, stages within each bucket are ordered by increasing distance<=2 competitors, retaining the adjacency constraint. Selection-round numbers preserve the original scoring history. This is not a guaranteed monotonic human difficulty curve.

## Profile census

| Profile | Legal worlds | Distinct full targets | Exact-unique full targets (peak) | Sampled | Scored | Retained | Seconds |
|---|---:|---:|---:|---:|---:|---:|---:|
| two_height_light | 41,400 | 34,609 | 29,508 | 31 | 8 | 8 | 0.083 |
| fog_height_light | 41,400 | 34,609 | 29,508 | 234 | 45 | 10 | 0.295 |
| two_plate_light | 55,200 | 37,448 | 26,292 | 41 | 8 | 8 | 0.078 |
| two_shutter_light | 46,000 | 22,103 | 12,417 | 31 | 8 | 8 | 0.054 |
| two_height_plate | 27,600 | 20,542 | 15,584 | 17 | 8 | 8 | 0.071 |
| two_height_shutter | 34,500 | 21,206 | 14,160 | 17 | 8 | 8 | 0.053 |
| two_plate_shutter | 69,000 | 31,022 | 15,754 | 24 | 8 | 8 | 0.086 |
| fog_plate_shutter | 69,000 | 31,022 | 15,754 | 161 | 47 | 10 | 0.406 |
| three_height_light_shutter | 138,000 | 67,253 | 38,200 | 48 | 13 | 10 | 0.224 |
| fog_height_light_shutter | 138,000 | 67,253 | 38,200 | 63 | 19 | 10 | 0.405 |
| three_height_plate_light | 110,400 | 81,340 | 61,272 | 31 | 12 | 10 | 0.203 |
| fog_height_plate_light | 110,400 | 81,340 | 61,272 | 117 | 43 | 10 | 1.123 |
| three_height_plate_shutter | 138,000 | 64,249 | 34,130 | 22 | 12 | 10 | 0.269 |
| three_plate_light_shutter | 276,000 | 62,884 | 15,938 | 148 | 10 | 10 | 0.523 |
| dense_height_plate_light | 1,214,400 | 872,962 | 646,672 | 37 | 21 | 20 | 6.624 |
| dense_height_plate_shutter | 1,518,000 | 845,322 | 501,945 | 37 | 22 | 20 | 8.804 |
| finale | 6,072,000 | 1,879,135 | 699,954 | 43 | 26 | 24 | 40.440 |

Repeated physical profiles reuse the in-memory reverse index; fog projection is checked against every world, including worlds with nonunique full targets. Per-profile time includes index construction only for its first use.

## GR36 compared with GR20

| Measure | GR20 | GR36 |
|---|---:|---:|
| object_count | 3 | 4 |
| legal_world_states | 552000 | 6072000 |
| greedy_witness_count | 8 | 10 |
| states_hamming_1 | 22 | 11 |
| states_hamming_le_2 | 86 | 92 |
| overlap_cell_count | 1 | 2 |
| edge_offboard_contributions | 0 | 0 |

The preferred finale profile succeeded: Normal ×2 + Tall ×1 + rotatable Plate ×1, exactly three lamps, one movable TOP shutter, fully visible. The selection gate requires more witness cells and distance<=2 competitors than GR20, at least as many overlaps, no additional off-board rays, and a 2–4-world intermediate step. This demonstrates deeper competing explanations by those explicit proxies; human readability remains a review judgment.

GR20 greedy trace: C2=2 (17,793 remain) → A1=1 (3,703 remain) → D4=1 (386 remain) → E1=1 (44 remain) → B4=1 (16 remain) → A2=1 (8 remain) → C5=0 (4 remain) → B3=0 (1 remain)

## Selected stages

| Stage | Candidate | Families | Reasoning | Witness | d≤2 | Score |
|---|---|---|---|---:|---:|---:|
| GR21 | two_height_shutter-001 | HEIGHT + SHUTTER | OVERLAP -> REACH -> ZERO -> TYPE -> SHADOW -> SHUTTER | 8 | 13 | 26.8830 |
| GR22 | two_plate_light-005 | PLATE + LIGHT | OVERLAP -> SHADOW -> LIGHT -> ZERO -> ORIENTATION | 7 | 51 | 27.5405 |
| GR23 | two_shutter_light-006 | LIGHT + SHUTTER | OVERLAP -> SHADOW -> LIGHT -> ZERO -> SHUTTER | 7 | 70 | 29.4797 |
| GR24 | two_plate_shutter-008 | PLATE + SHUTTER | OVERLAP -> SHADOW -> PLATE_ABSENCE -> ZERO -> SHUTTER -> ORIENTATION | 9 | 130 | 34.9401 |
| GR25 | three_height_light_shutter-009 | HEIGHT + LIGHT + SHUTTER | OVERLAP -> REACH -> SHADOW -> TYPE -> LIGHT -> ZERO -> SHUTTER | 8 | 11 | 27.5020 |
| GR26 | three_height_plate_shutter-002 | HEIGHT + PLATE + SHUTTER | OVERLAP -> SHADOW -> REACH -> TYPE -> ZERO -> SHUTTER -> ORIENTATION | 8 | 27 | 31.8688 |
| GR27 | three_height_plate_light-008 | HEIGHT + PLATE + LIGHT | OVERLAP -> SHADOW -> PLATE_ABSENCE -> REACH -> LIGHT -> TYPE -> ZERO -> ORIENTATION | 8 | 46 | 29.0655 |
| GR28 | three_plate_light_shutter-005 | PLATE + LIGHT + SHUTTER | OVERLAP -> SHADOW -> ZERO -> ORIENTATION -> LIGHT -> SHUTTER | 8 | 131 | 32.6533 |
| GR29 | fog_height_light_shutter-008 | HEIGHT + LIGHT + SHUTTER | REACH -> SHADOW -> LIGHT -> TYPE -> ZERO -> SHUTTER | 10 | 93 | 33.8655 |
| GR30 | fog_plate_shutter-010 | PLATE + SHUTTER | OVERLAP -> SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION | 8 | 128 | 35.4135 |
| GR31 | fog_height_light-007 | HEIGHT + LIGHT | SHADOW -> REACH -> ZERO -> LIGHT -> TYPE | 10 | 168 | 33.3811 |
| GR32 | fog_plate_shutter-002 | PLATE + SHUTTER | SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION | 9 | 264 | 35.8598 |
| GR33 | dense_height_plate_shutter-014 | HEIGHT + PLATE + SHUTTER | OVERLAP -> ZERO -> SHADOW -> SHUTTER -> REACH -> TYPE -> ORIENTATION | 10 | 30 | 34.8450 |
| GR34 | dense_height_plate_shutter-017 | HEIGHT + PLATE + SHUTTER | OVERLAP -> SHADOW -> ORIENTATION -> TYPE -> ZERO -> SHUTTER | 10 | 85 | 38.9115 |
| GR35 | dense_height_plate_light-020 | HEIGHT + PLATE + LIGHT | OVERLAP -> SHADOW -> REACH -> ZERO -> PLATE_ABSENCE -> LIGHT -> ORIENTATION -> TYPE | 10 | 92 | 35.1316 |
| GR36 | finale-015 | HEIGHT + PLATE + LIGHT + SHUTTER | OVERLAP -> SHADOW -> REACH -> LIGHT -> ORIENTATION -> TYPE -> SHUTTER | 10 | 92 | 38.2470 |

## GR21 — BLOCKED REACH

Candidate: `two_height_shutter-001`. Mechanics: **HEIGHT + SHUTTER**.

Solution: E2:normal, E4:normal, D3:tall; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=E.

Legal states: **34,500**; exact survivors: **1**; independent enumeration: 0.045s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 0 0 1 1
2   0 0 0 2 0
3   0 1 1 0 2
4   0 0 0 2 0
5   0 0 0 1 0
```

Reasoning signature: **OVERLAP -> REACH -> ZERO -> TYPE -> SHADOW -> SHUTTER**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| E3 = 2 | OVERLAP | 1,667 | — |
| D4 = 2 | OVERLAP | 336 | — |
| D2 = 2 | OVERLAP | 59 | — |
| D1 = 1 | REACH | 18 | — |
| E5 = 0 | ZERO | 9 | — |
| B2 = 0 | ZERO | 5 | TYPE |
| C3 = 1 | SHADOW | 2 | SHUTTER |
| C1 = 0 | ZERO | 1 | — |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, B1, C1, A2, B2, C2, E2, A3, D3, A4, B4, C4, E4, A5, B5, C5, E5 | 8 | True |
| overlap | D2, E3, D4 | 1 | False |
| tall_reach | D1, B3, D5 | 1 | False |
| plate_directional_absence | — | 1 | False |
| light_choice | — | 1 | False |
| shutter_choice | E3, D4, D5, E5 | 5 | True |

Score components:

- distributed_evidence: +18.0000
- causal_ambiguity: +4.5688
- overlap_quality: +2.4000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +4.4000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -3.6858
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 26.8830; diversity: +7; profile repetition: +0; selection total: **33.8830**.

Selection round 4: won among 45 eligible remaining candidates. Nearby alternatives at this decision:

- `two_height_shutter-003`: base 25.2883 + diversity 7 + repetition (0) = 32.2883; `OVERLAP -> SHADOW -> ZERO -> SHUTTER -> TYPE`. Winner margin 1.5947.
- `two_height_shutter-006`: base 24.3142 + diversity 7 + repetition (0) = 31.3142; `OVERLAP -> SHADOW -> ZERO -> TYPE -> SHUTTER`. Winner margin 2.5688.
- `two_height_plate-001`: base 23.5405 + diversity 7 + repetition (0) = 30.5405; `OVERLAP -> SHADOW -> REACH -> TYPE -> ORIENTATION -> PLATE_ABSENCE`. Winner margin 3.3425.

Neighbor comparison:

- GR22: PLATE + LIGHT; `OVERLAP -> SHADOW -> LIGHT -> ZERO -> ORIENTATION`; witness 7 vs 8, fog 0 vs 0, overlaps 1 vs 3.

Plausible legal near misses and ALL rejecting visible evidence:

- D1:normal, E4:normal, D3:tall; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=E. Distance 1. Rejected by **C1: expected 0, gets 1**.
- A1:normal, E2:normal, D3:tall; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 2. Rejected by **B1: expected 0, gets 1; D4: expected 2, gets 1**.
- D1:normal, E4:normal, D3:tall; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=B. Distance 2. Rejected by **C1: expected 0, gets 1; E5: expected 0, gets 1**.
- D1:normal, E4:normal, D3:tall; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=C. Distance 2. Rejected by **C1: expected 0, gets 1; E5: expected 0, gets 1**.

## GR22 — WHICH AXIS IS LIT

Candidate: `two_plate_light-005`. Mechanics: **PLATE + LIGHT**.

Solution: B2:normal, C3:normal, C4:plate_h; lights=LEFT+RIGHT+BOTTOM; shutter=none.

Legal states: **55,200**; exact survivors: **1**; independent enumeration: 0.066s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 1 0 0 0
2   1 0 2 0 0
3   0 1 1 1 0
4   0 0 0 0 0
5   0 0 0 0 0
```

Reasoning signature: **OVERLAP -> SHADOW -> LIGHT -> ZERO -> ORIENTATION**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| C2 = 2 | OVERLAP | 1,068 | — |
| C3 = 1 | SHADOW | 108 | — |
| A2 = 1 | SHADOW | 36 | — |
| D3 = 1 | SHADOW | 12 | — |
| B1 = 1 | SHADOW | 3 | LIGHT |
| A3 = 0 | ZERO | 2 | — |
| E3 = 0 | ZERO | 1 | ORIENTATION |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, C1, D1, E1, B2, D2, E2, A3, E3, A4, B4, C4, D4, E4, A5, B5, C5, D5, E5 | 3 | True |
| overlap | C2 | 1 | False |
| tall_reach | — | 1 | False |
| plate_directional_absence | B4, D4 | 1 | False |
| light_choice | B1, A2, C2, B3, C3, D3, C4, C5 | 249 | True |
| shutter_choice | — | 1 | False |

Score components:

- distributed_evidence: +15.8000
- causal_ambiguity: +6.8405
- overlap_quality: +0.8000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +2.9000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.0000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 27.5405; diversity: +7; profile repetition: +0; selection total: **34.5405**.

Selection round 3: won among 46 eligible remaining candidates. Nearby alternatives at this decision:

- `two_height_shutter-001`: base 26.8830 + diversity 7 + repetition (0) = 33.8830; `OVERLAP -> REACH -> ZERO -> TYPE -> SHADOW -> SHUTTER`. Winner margin 0.6575.
- `two_plate_light-006`: base 25.8169 + diversity 7 + repetition (0) = 32.8169; `OVERLAP -> SHADOW -> ZERO -> LIGHT -> PLATE_ABSENCE -> ORIENTATION`. Winner margin 1.7236.
- `two_plate_light-004`: base 25.4726 + diversity 7 + repetition (0) = 32.4726; `OVERLAP -> SHADOW -> ZERO -> LIGHT -> ORIENTATION`. Winner margin 2.0679.

Neighbor comparison:

- GR21: HEIGHT + SHUTTER; `OVERLAP -> REACH -> ZERO -> TYPE -> SHADOW -> SHUTTER`; witness 8 vs 7, fog 0 vs 0, overlaps 3 vs 1.
- GR23: LIGHT + SHUTTER; `OVERLAP -> SHADOW -> LIGHT -> ZERO -> SHUTTER`; witness 7 vs 7, fog 0 vs 0, overlaps 1 vs 1.

Plausible legal near misses and ALL rejecting visible evidence:

- A1:normal, C3:normal, B2:plate_v; lights=LEFT+RIGHT+BOTTOM; shutter=none. Distance 1. Rejected by **C3: expected 1, gets 0**.
- B2:normal, C3:normal, A1:plate_h; lights=LEFT+RIGHT+BOTTOM; shutter=none. Distance 1. Rejected by **C3: expected 1, gets 0**.
- B2:normal, C3:normal, B1:plate_h; lights=LEFT+RIGHT+BOTTOM; shutter=none. Distance 1. Rejected by **C3: expected 1, gets 0**.
- B2:normal, C3:normal, C1:plate_h; lights=LEFT+RIGHT+BOTTOM; shutter=none. Distance 1. Rejected by **C3: expected 1, gets 0**.

## GR23 — LOCAL OR GLOBAL

Candidate: `two_shutter_light-006`. Mechanics: **LIGHT + SHUTTER**.

Solution: B2:normal, D2:normal, A3:normal; lights=TOP+LEFT+BOTTOM; shutter=D.

Legal states: **46,000**; exact survivors: **1**; independent enumeration: 0.052s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 1 0 1 0
2   1 0 1 0 1
3   0 2 0 0 0
4   1 0 0 0 0
5   0 0 0 0 0
```

Reasoning signature: **OVERLAP -> SHADOW -> LIGHT -> ZERO -> SHUTTER**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| B3 = 2 | OVERLAP | 1,191 | — |
| E2 = 1 | SHADOW | 112 | — |
| B1 = 1 | SHADOW | 36 | — |
| D1 = 1 | SHADOW | 14 | — |
| A4 = 1 | SHADOW | 6 | — |
| C2 = 1 | SHADOW | 3 | LIGHT |
| D3 = 0 | ZERO | 1 | SHUTTER |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, C1, E1, B2, D2, A3, C3, D3, E3, B4, C4, D4, E4, A5, B5, C5, D5, E5 | 3 | True |
| overlap | B3 | 3 | True |
| tall_reach | — | 1 | False |
| plate_directional_absence | — | 1 | False |
| light_choice | B1, D1, A2, C2, E2, B3, A4 | 375 | True |
| shutter_choice | B3, D3, A4 | 28 | True |

Score components:

- distributed_evidence: +16.2000
- causal_ambiguity: +7.3797
- overlap_quality: +1.8000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +2.9000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.0000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 29.4797; diversity: +7; profile repetition: +0; selection total: **36.4797**.

Selection round 2: won among 46 eligible remaining candidates. Nearby alternatives at this decision:

- `two_plate_light-005`: base 27.5405 + diversity 7 + repetition (0) = 34.5405; `OVERLAP -> SHADOW -> LIGHT -> ZERO -> ORIENTATION`. Winner margin 1.9392.
- `two_height_shutter-001`: base 26.8830 + diversity 7 + repetition (0) = 33.8830; `OVERLAP -> REACH -> ZERO -> TYPE -> SHADOW -> SHUTTER`. Winner margin 2.5967.
- `two_plate_light-006`: base 25.8169 + diversity 7 + repetition (0) = 32.8169; `OVERLAP -> SHADOW -> ZERO -> LIGHT -> PLATE_ABSENCE -> ORIENTATION`. Winner margin 3.6628.

Neighbor comparison:

- GR22: PLATE + LIGHT; `OVERLAP -> SHADOW -> LIGHT -> ZERO -> ORIENTATION`; witness 7 vs 7, fog 0 vs 0, overlaps 1 vs 1.
- GR24: PLATE + SHUTTER; `OVERLAP -> SHADOW -> PLATE_ABSENCE -> ZERO -> SHUTTER -> ORIENTATION`; witness 9 vs 7, fog 0 vs 0, overlaps 1 vs 1.

Plausible legal near misses and ALL rejecting visible evidence:

- C1:normal, B2:normal, A3:normal; lights=TOP+LEFT+RIGHT; shutter=C. Distance 1. Rejected by **E2: expected 1, gets 0**.
- E1:normal, B2:normal, A3:normal; lights=TOP+LEFT+RIGHT; shutter=C. Distance 1. Rejected by **B1: expected 1, gets 0**.
- E1:normal, B2:normal, A3:normal; lights=TOP+LEFT+RIGHT; shutter=D. Distance 1. Rejected by **B1: expected 1, gets 0**.
- C1:normal, B2:normal, A3:normal; lights=TOP+LEFT+BOTTOM; shutter=C. Distance 1. Rejected by **E2: expected 1, gets 0**.

## GR24 — THE SILENT CROSS

Candidate: `two_plate_shutter-008`. Mechanics: **PLATE + SHUTTER**.

Solution: B2:normal, B4:normal, C1:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=B.

Legal states: **69,000**; exact survivors: **1**; independent enumeration: 0.082s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 1 0 0 0
2   1 0 2 0 0
3   0 1 0 0 0
4   1 0 1 0 0
5   0 0 0 0 0
```

Reasoning signature: **OVERLAP -> SHADOW -> PLATE_ABSENCE -> ZERO -> SHUTTER -> ORIENTATION**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| C2 = 2 | OVERLAP | 2,331 | — |
| A4 = 1 | SHADOW | 225 | — |
| D1 = 0 | PLATE_ABSENCE | 92 | — |
| B3 = 1 | SHADOW | 34 | — |
| B5 = 0 | ZERO | 9 | SHUTTER |
| A2 = 1 | SHADOW | 5 | — |
| D3 = 0 | ZERO | 3 | — |
| E2 = 0 | ZERO | 2 | ORIENTATION |
| C4 = 1 | SHADOW | 1 | — |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, C1, D1, E1, B2, D2, E2, A3, C3, D3, E3, B4, D4, E4, A5, B5, C5, D5, E5 | 20 | True |
| overlap | C2 | 5 | True |
| tall_reach | — | 1 | False |
| plate_directional_absence | B1, D1 | 8 | True |
| light_choice | — | 1 | False |
| shutter_choice | C2, B3, B5 | 57 | True |

Score components:

- distributed_evidence: +20.2000
- causal_ambiguity: +8.4401
- overlap_quality: +1.8000
- negative_evidence_quality: +2.4000
- mechanic_interaction: +2.9000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.8000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 34.9401; diversity: +7; profile repetition: +0; selection total: **41.9401**.

Selection round 1: won among 48 eligible remaining candidates. Nearby alternatives at this decision:

- `two_shutter_light-006`: base 29.4797 + diversity 7 + repetition (0) = 36.4797; `OVERLAP -> SHADOW -> LIGHT -> ZERO -> SHUTTER`. Winner margin 5.4604.
- `two_plate_shutter-001`: base 27.8059 + diversity 7 + repetition (0) = 34.8059; `OVERLAP -> SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`. Winner margin 7.1342.
- `two_plate_light-005`: base 27.5405 + diversity 7 + repetition (0) = 34.5405; `OVERLAP -> SHADOW -> LIGHT -> ZERO -> ORIENTATION`. Winner margin 7.3996.

Neighbor comparison:

- GR23: LIGHT + SHUTTER; `OVERLAP -> SHADOW -> LIGHT -> ZERO -> SHUTTER`; witness 7 vs 9, fog 0 vs 0, overlaps 1 vs 1.
- GR25: HEIGHT + LIGHT + SHUTTER; `OVERLAP -> REACH -> SHADOW -> TYPE -> LIGHT -> ZERO -> SHUTTER`; witness 8 vs 9, fog 0 vs 0, overlaps 1 vs 1.

Plausible legal near misses and ALL rejecting visible evidence:

- A1:normal, A3:normal, B4:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **C2: expected 2, gets 0**.
- B2:normal, A5:normal, C3:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **B5: expected 0, gets 1**.
- A1:normal, B4:normal, B1:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=B. Distance 1. Rejected by **C2: expected 2, gets 0**.
- A1:normal, B4:normal, C1:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=B. Distance 1. Rejected by **C2: expected 2, gets 1**.

## GR25 — THE MISSING LONG SHADOW

Candidate: `three_height_light_shutter-009`. Mechanics: **HEIGHT + LIGHT + SHUTTER**.

Solution: A3:normal, A4:normal, B3:tall; lights=TOP+LEFT+BOTTOM; shutter=A.

Legal states: **138,000**; exact survivors: **1**; independent enumeration: 0.136s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 1 0 0 0
2   1 1 0 0 0
3   1 1 1 1 0
4   0 2 0 0 0
5   0 1 0 0 0
```

Reasoning signature: **OVERLAP -> REACH -> SHADOW -> TYPE -> LIGHT -> ZERO -> SHUTTER**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| B4 = 2 | OVERLAP | 5,159 | — |
| B5 = 1 | REACH | 991 | — |
| A2 = 1 | SHADOW | 147 | — |
| D3 = 1 | REACH | 28 | TYPE |
| B1 = 1 | REACH | 14 | — |
| B2 = 1 | SHADOW | 8 | LIGHT |
| A4 = 0 | ZERO | 2 | SHUTTER |
| A3 = 1 | SHADOW | 1 | — |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, C1, D1, E1, C2, D2, E2, E3, A4, C4, D4, E4, A5, C5, D5, E5 | 4 | True |
| overlap | B4 | 1 | False |
| tall_reach | B1, D3, B5 | 2 | False |
| plate_directional_absence | — | 1 | False |
| light_choice | B1, A2, B2, A3, B3, C3, D3, B4, B5 | 115 | True |
| shutter_choice | A4, B4, A5, B5 | 10 | True |

Score components:

- distributed_evidence: +17.6000
- causal_ambiguity: +4.3020
- overlap_quality: +0.8000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +3.6000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.0000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 27.5020; diversity: +7; profile repetition: +0; selection total: **34.5020**.

Selection round 8: won among 37 eligible remaining candidates. Nearby alternatives at this decision:

- `three_height_light_shutter-001`: base 26.6283 + diversity 7 + repetition (0) = 33.6283; `OVERLAP -> SHADOW -> ZERO -> LIGHT -> REACH -> SHUTTER -> TYPE`. Winner margin 0.8737.
- `three_height_light_shutter-002`: base 26.3675 + diversity 7 + repetition (0) = 33.3675; `OVERLAP -> SHADOW -> REACH -> ZERO -> LIGHT -> TYPE -> SHUTTER`. Winner margin 1.1345.
- `three_plate_light_shutter-009`: base 32.3425 + diversity 3 + repetition (-2) = 33.3425; `OVERLAP -> SHADOW -> ORIENTATION -> LIGHT -> ZERO -> SHUTTER`. Winner margin 1.1595.

Neighbor comparison:

- GR24: PLATE + SHUTTER; `OVERLAP -> SHADOW -> PLATE_ABSENCE -> ZERO -> SHUTTER -> ORIENTATION`; witness 9 vs 8, fog 0 vs 0, overlaps 1 vs 1.
- GR26: HEIGHT + PLATE + SHUTTER; `OVERLAP -> SHADOW -> REACH -> TYPE -> ZERO -> SHUTTER -> ORIENTATION`; witness 8 vs 8, fog 0 vs 0, overlaps 2 vs 1.

Plausible legal near misses and ALL rejecting visible evidence:

- A3:normal, B5:normal, B3:tall; lights=TOP+LEFT+BOTTOM; shutter=A. Distance 2. Rejected by **A3: expected 1, gets 0; C5: expected 0, gets 1**.
- A3:normal, A4:normal, B3:tall; lights=TOP+LEFT+BOTTOM; shutter=C. Distance 2. Rejected by **A4: expected 0, gets 1; A5: expected 0, gets 1**.
- A3:normal, A4:normal, B3:tall; lights=TOP+LEFT+BOTTOM; shutter=D. Distance 2. Rejected by **A4: expected 0, gets 1; A5: expected 0, gets 1**.
- A3:normal, A4:normal, B3:tall; lights=TOP+LEFT+BOTTOM; shutter=E. Distance 2. Rejected by **A4: expected 0, gets 1; A5: expected 0, gets 1**.

## GR26 — BEYOND THE BLOCKED AXIS

Candidate: `three_height_plate_shutter-002`. Mechanics: **HEIGHT + PLATE + SHUTTER**.

Solution: D3:normal, C3:tall, A3:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=C.

Legal states: **138,000**; exact survivors: **1**; independent enumeration: 0.148s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 0 1 0 0
2   0 0 1 1 0
3   1 2 1 1 2
4   0 0 0 1 0
5   0 0 0 0 0
```

Reasoning signature: **OVERLAP -> SHADOW -> REACH -> TYPE -> ZERO -> SHUTTER -> ORIENTATION**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| E3 = 2 | OVERLAP | 4,852 | — |
| B3 = 2 | OVERLAP | 146 | — |
| D4 = 1 | SHADOW | 66 | — |
| C1 = 1 | REACH | 25 | TYPE |
| C4 = 0 | ZERO | 6 | SHUTTER |
| D2 = 1 | SHADOW | 3 | — |
| B1 = 0 | ZERO | 2 | — |
| B5 = 0 | ZERO | 1 | ORIENTATION |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, B1, D1, E1, A2, B2, E2, A4, B4, C4, E4, A5, B5, C5, D5, E5 | 11 | True |
| overlap | B3, E3 | 2 | True |
| tall_reach | C1, A3, E3 | 1 | False |
| plate_directional_absence | A2, A4 | 1 | False |
| light_choice | — | 1 | False |
| shutter_choice | C4, D4, C5 | 6 | True |

Score components:

- distributed_evidence: +18.0000
- causal_ambiguity: +5.7688
- overlap_quality: +2.6000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +5.1000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.8000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 31.8688; diversity: +7; profile repetition: +0; selection total: **38.8688**.

Selection round 6: won among 39 eligible remaining candidates. Nearby alternatives at this decision:

- `three_height_plate_shutter-001`: base 30.5965 + diversity 7 + repetition (0) = 37.5965; `OVERLAP -> SHADOW -> PLATE_ABSENCE -> ORIENTATION -> TYPE -> ZERO -> SHUTTER`. Winner margin 1.2723.
- `three_height_plate_shutter-010`: base 30.1841 + diversity 7 + repetition (0) = 37.1841; `OVERLAP -> REACH -> SHADOW -> TYPE -> ZERO -> SHUTTER -> ORIENTATION`. Winner margin 1.6847.
- `three_height_plate_light-008`: base 29.0655 + diversity 7 + repetition (0) = 36.0655; `OVERLAP -> SHADOW -> PLATE_ABSENCE -> REACH -> LIGHT -> TYPE -> ZERO -> ORIENTATION`. Winner margin 2.8033.

Neighbor comparison:

- GR25: HEIGHT + LIGHT + SHUTTER; `OVERLAP -> REACH -> SHADOW -> TYPE -> LIGHT -> ZERO -> SHUTTER`; witness 8 vs 8, fog 0 vs 0, overlaps 1 vs 2.
- GR27: HEIGHT + PLATE + LIGHT; `OVERLAP -> SHADOW -> PLATE_ABSENCE -> REACH -> LIGHT -> TYPE -> ZERO -> ORIENTATION`; witness 8 vs 8, fog 0 vs 0, overlaps 1 vs 2.

Plausible legal near misses and ALL rejecting visible evidence:

- D3:normal, C3:tall, C1:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=C. Distance 1. Rejected by **B3: expected 2, gets 1**.
- D3:normal, C3:tall, B2:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=C. Distance 1. Rejected by **B1: expected 0, gets 1**.
- D3:normal, C3:tall, B4:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=C. Distance 1. Rejected by **B5: expected 0, gets 1**.
- D3:normal, C3:tall, A3:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 2. Rejected by **C4: expected 0, gets 1; C5: expected 0, gets 1**.

## GR27 — TURN TOWARD THE LIGHT

Candidate: `three_height_plate_light-008`. Mechanics: **HEIGHT + PLATE + LIGHT**.

Solution: D4:normal, C4:tall, D3:plate_v; lights=TOP+LEFT+BOTTOM; shutter=none.

Legal states: **110,400**; exact survivors: **1**; independent enumeration: 0.130s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 0 0 0 0
2   0 0 1 0 0
3   0 0 1 1 1
4   0 0 0 1 2
5   0 0 1 1 0
```

Reasoning signature: **OVERLAP -> SHADOW -> PLATE_ABSENCE -> REACH -> LIGHT -> TYPE -> ZERO -> ORIENTATION**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| E4 = 2 | OVERLAP | 1,992 | — |
| C5 = 1 | SHADOW | 569 | — |
| E3 = 1 | SHADOW | 196 | — |
| D4 = 1 | PLATE_ABSENCE | 38 | — |
| D3 = 1 | SHADOW | 11 | — |
| C2 = 1 | REACH | 3 | LIGHT, TYPE |
| E1 = 0 | ZERO | 2 | — |
| E5 = 0 | ZERO | 1 | ORIENTATION |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, B1, C1, D1, E1, A2, B2, D2, E2, A3, B3, A4, B4, C4, A5, B5, E5 | 3 | True |
| overlap | E4 | 1 | False |
| tall_reach | C2, E4 | 4 | True |
| plate_directional_absence | D2, D4 | 1 | False |
| light_choice | C2, C3, D3, E3, A4, B4, C4, D4, E4, C5, D5 | 700 | True |
| shutter_choice | — | 1 | False |

Score components:

- distributed_evidence: +17.6000
- causal_ambiguity: +6.6655
- overlap_quality: +0.8000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +3.6000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.8000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 29.0655; diversity: +7; profile repetition: +0; selection total: **36.0655**.

Selection round 7: won among 37 eligible remaining candidates. Nearby alternatives at this decision:

- `three_height_light_shutter-009`: base 27.5020 + diversity 7 + repetition (0) = 34.5020; `OVERLAP -> REACH -> SHADOW -> TYPE -> LIGHT -> ZERO -> SHUTTER`. Winner margin 1.5635.
- `three_height_light_shutter-001`: base 26.6283 + diversity 7 + repetition (0) = 33.6283; `OVERLAP -> SHADOW -> ZERO -> LIGHT -> REACH -> SHUTTER -> TYPE`. Winner margin 2.4372.
- `three_height_light_shutter-002`: base 26.3675 + diversity 7 + repetition (0) = 33.3675; `OVERLAP -> SHADOW -> REACH -> ZERO -> LIGHT -> TYPE -> SHUTTER`. Winner margin 2.6980.

Neighbor comparison:

- GR26: HEIGHT + PLATE + SHUTTER; `OVERLAP -> SHADOW -> REACH -> TYPE -> ZERO -> SHUTTER -> ORIENTATION`; witness 8 vs 8, fog 0 vs 0, overlaps 2 vs 1.
- GR28: PLATE + LIGHT + SHUTTER; `OVERLAP -> SHADOW -> ZERO -> ORIENTATION -> LIGHT -> SHUTTER`; witness 8 vs 8, fog 0 vs 0, overlaps 1 vs 1.

Plausible legal near misses and ALL rejecting visible evidence:

- D4:normal, C4:tall, E1:plate_v; lights=TOP+LEFT+BOTTOM; shutter=none. Distance 1. Rejected by **E3: expected 1, gets 0**.
- D4:normal, C4:tall, E2:plate_v; lights=TOP+LEFT+BOTTOM; shutter=none. Distance 1. Rejected by **E3: expected 1, gets 0**.
- D4:normal, C4:tall, E2:plate_h; lights=TOP+LEFT+BOTTOM; shutter=none. Distance 1. Rejected by **E1: expected 0, gets 1**.
- D4:normal, C4:tall, E3:plate_v; lights=TOP+LEFT+BOTTOM; shutter=none. Distance 1. Rejected by **E3: expected 1, gets 0**.

## GR28 — THREE KINDS OF ABSENCE

Candidate: `three_plate_light_shutter-005`. Mechanics: **PLATE + LIGHT + SHUTTER**.

Solution: D2:normal, E3:normal, C2:plate_h; lights=TOP+RIGHT+BOTTOM; shutter=E.

Legal states: **276,000**; exact survivors: **1**; independent enumeration: 0.258s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 0 1 1 0
2   0 0 1 0 1
3   0 0 1 2 0
4   0 0 0 0 0
5   0 0 0 0 0
```

Reasoning signature: **OVERLAP -> SHADOW -> ZERO -> ORIENTATION -> LIGHT -> SHUTTER**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| D3 = 2 | OVERLAP | 4,815 | — |
| C1 = 1 | SHADOW | 369 | — |
| C3 = 1 | SHADOW | 60 | — |
| D5 = 0 | ZERO | 24 | — |
| C2 = 1 | SHADOW | 14 | — |
| E2 = 1 | SHADOW | 6 | ORIENTATION |
| C4 = 0 | ZERO | 3 | LIGHT |
| E4 = 0 | ZERO | 1 | SHUTTER |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, B1, E1, A2, B2, D2, A3, B3, E3, A4, B4, C4, D4, E4, A5, B5, C5, D5, E5 | 6 | True |
| overlap | D3 | 5 | True |
| tall_reach | — | 1 | False |
| plate_directional_absence | B2 | 1 | False |
| light_choice | C1, D1, C2, E2, C3, D3 | 650 | True |
| shutter_choice | C3, D3, E4 | 35 | True |

Score components:

- distributed_evidence: +17.6000
- causal_ambiguity: +8.4533
- overlap_quality: +1.8000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +3.6000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.0000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 32.6533; diversity: +7; profile repetition: +0; selection total: **39.6533**.

Selection round 5: won among 40 eligible remaining candidates. Nearby alternatives at this decision:

- `three_plate_light_shutter-009`: base 32.3425 + diversity 7 + repetition (0) = 39.3425; `OVERLAP -> SHADOW -> ORIENTATION -> LIGHT -> ZERO -> SHUTTER`. Winner margin 0.3108.
- `three_plate_light_shutter-006`: base 32.3115 + diversity 7 + repetition (0) = 39.3115; `OVERLAP -> SHADOW -> LIGHT -> PLATE_ABSENCE -> ZERO -> SHUTTER -> ORIENTATION`. Winner margin 0.3418.
- `three_plate_light_shutter-010`: base 31.9465 + diversity 7 + repetition (0) = 38.9465; `OVERLAP -> SHADOW -> ORIENTATION -> ZERO -> LIGHT -> SHUTTER`. Winner margin 0.7068.

Neighbor comparison:

- GR27: HEIGHT + PLATE + LIGHT; `OVERLAP -> SHADOW -> PLATE_ABSENCE -> REACH -> LIGHT -> TYPE -> ZERO -> ORIENTATION`; witness 8 vs 8, fog 0 vs 0, overlaps 1 vs 1.
- GR29: HEIGHT + LIGHT + SHUTTER; `REACH -> SHADOW -> LIGHT -> TYPE -> ZERO -> SHUTTER`; witness 10 vs 8, fog 3 vs 0, overlaps 0 vs 1.

Plausible legal near misses and ALL rejecting visible evidence:

- C1:normal, E1:normal, C2:plate_h; lights=TOP+LEFT+BOTTOM; shutter=A. Distance 1. Rejected by **D3: expected 2, gets 0**.
- D2:normal, C3:normal, C2:plate_h; lights=TOP+LEFT+BOTTOM; shutter=A. Distance 1. Rejected by **C4: expected 0, gets 1**.
- C1:normal, E1:normal, C2:plate_h; lights=TOP+LEFT+BOTTOM; shutter=B. Distance 1. Rejected by **D3: expected 2, gets 0**.
- D2:normal, C3:normal, B1:plate_v; lights=TOP+LEFT+BOTTOM; shutter=C. Distance 1. Rejected by **C3: expected 1, gets 0**.

## GR29 — BEYOND THE VEIL

Candidate: `fog_height_light_shutter-008`. Mechanics: **HEIGHT + LIGHT + SHUTTER**.

Solution: C2:normal, A4:normal, D3:tall; lights=TOP+LEFT+BOTTOM; shutter=A.

Legal states: **138,000**; exact survivors: **1**; independent enumeration: 0.140s.

FOG: B1, D2, A3. `?` is unobserved, never zero.

```text
    A B C D E
1   0 ? 1 1 0
2   0 0 0 ? 0
3   ? 0 1 0 1
4   0 1 0 1 0
5   0 0 0 1 0
```

Reasoning signature: **REACH -> SHADOW -> LIGHT -> TYPE -> ZERO -> SHUTTER**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| D5 = 1 | REACH | 35,996 | — |
| C1 = 1 | SHADOW | 8,403 | — |
| D4 = 1 | SHADOW | 1,697 | — |
| B4 = 1 | SHADOW | 390 | — |
| D1 = 1 | REACH | 92 | — |
| E3 = 1 | SHADOW | 33 | — |
| C3 = 1 | SHADOW | 10 | LIGHT, TYPE |
| B2 = 0 | ZERO | 6 | — |
| C5 = 0 | ZERO | 3 | — |
| A5 = 0 | ZERO | 1 | SHUTTER |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, E1, A2, B2, C2, E2, B3, D3, A4, C4, E4, A5, B5, C5, E5 | 10 | True |
| overlap | — | 1 | False |
| tall_reach | D1, D5 | 2 | True |
| plate_directional_absence | — | 1 | False |
| light_choice | C1, D1, B2, B3, C3, E3, B4, D4, D5 | 741 | True |
| shutter_choice | C3, D4, A5, D5 | 30 | True |

FOG removes the full-board best first clue `D2`. Best first-clue survivors rise from 5,305 to 35,996; witness cells 7 → 10. Hidden nonzero cells: D2, A3.

Score components:

- distributed_evidence: +22.0000
- causal_ambiguity: +7.8655
- overlap_quality: +0.0000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +3.6000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.8000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 33.8655; diversity: +5; profile repetition: +0; selection total: **38.8655**.

Selection round 11: won among 38 eligible remaining candidates. Nearby alternatives at this decision:

- `fog_plate_shutter-002`: base 35.8598 + diversity 5 + repetition (-2) = 38.8598; `SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`. Winner margin 0.0057.
- `fog_height_plate_light-010`: base 33.2837 + diversity 5 + repetition (0) = 38.2837; `SHADOW -> ZERO -> REACH -> PLATE_ABSENCE -> ORIENTATION -> LIGHT -> TYPE`. Winner margin 0.5818.
- `fog_plate_shutter-005`: base 34.7513 + diversity 5 + repetition (-2) = 37.7513; `SHADOW -> ZERO -> SHUTTER -> PLATE_ABSENCE -> ORIENTATION`. Winner margin 1.1142.

Neighbor comparison:

- GR28: PLATE + LIGHT + SHUTTER; `OVERLAP -> SHADOW -> ZERO -> ORIENTATION -> LIGHT -> SHUTTER`; witness 8 vs 10, fog 0 vs 3, overlaps 1 vs 0.
- GR30: PLATE + SHUTTER; `OVERLAP -> SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`; witness 8 vs 10, fog 3 vs 3, overlaps 1 vs 0.

Plausible legal near misses and ALL rejecting visible evidence:

- D3:normal, E5:normal, E1:tall; lights=TOP+LEFT+RIGHT; shutter=E. Distance 1. Rejected by **B4: expected 1, gets 0**.
- A1:normal, C2:normal, D3:tall; lights=TOP+LEFT+BOTTOM; shutter=A. Distance 1. Rejected by **B4: expected 1, gets 0**.
- C2:normal, A4:normal, D3:tall; lights=TOP+LEFT+BOTTOM; shutter=B. Distance 1. Rejected by **A5: expected 0, gets 1**.
- B1:normal, B3:normal, D3:tall; lights=TOP+LEFT+BOTTOM; shutter=C. Distance 1. Rejected by **B2: expected 0, gets 2**.

## GR30 — PARTIAL CROSS

Candidate: `fog_plate_shutter-010`. Mechanics: **PLATE + SHUTTER**.

Solution: D3:normal, D5:normal, C4:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=D.

Legal states: **69,000**; exact survivors: **1**; independent enumeration: 0.079s.

FOG: A1, C5, D5. `?` is unobserved, never zero.

```text
    A B C D E
1   ? 0 0 0 0
2   0 0 0 1 0
3   0 0 2 0 1
4   0 0 0 1 0
5   0 0 ? ? 1
```

Reasoning signature: **OVERLAP -> SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| C3 = 2 | OVERLAP | 2,331 | — |
| E5 = 1 | SHADOW | 144 | — |
| B2 = 0 | ZERO | 59 | — |
| D4 = 1 | PLATE_ABSENCE | 8 | SHUTTER |
| E3 = 1 | SHADOW | 4 | — |
| C1 = 0 | ZERO | 3 | — |
| A3 = 0 | ZERO | 2 | — |
| B4 = 0 | PLATE_ABSENCE | 1 | ORIENTATION |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | B1, C1, D1, E1, A2, B2, C2, E2, A3, B3, D3, A4, B4, C4, E4, A5, B5 | 21 | True |
| overlap | C3 | 3 | True |
| tall_reach | — | 1 | False |
| plate_directional_absence | B4, D4 | 10 | True |
| light_choice | — | 1 | False |
| shutter_choice | D4 | 5 | True |

FOG removes the full-board best first clue `C5`. Best first-clue survivors rise from 1,160 to 2,331; witness cells 5 → 8. Hidden nonzero cells: C5.

Score components:

- distributed_evidence: +18.4000
- causal_ambiguity: +8.4135
- overlap_quality: +1.8000
- negative_evidence_quality: +2.4000
- mechanic_interaction: +4.4000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.0000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 35.4135; diversity: +5; profile repetition: +0; selection total: **40.4135**.

Selection round 10: won among 34 eligible remaining candidates. Nearby alternatives at this decision:

- `fog_height_light_shutter-008`: base 33.8655 + diversity 5 + repetition (0) = 38.8655; `REACH -> SHADOW -> LIGHT -> TYPE -> ZERO -> SHUTTER`. Winner margin 1.5480.
- `fog_plate_shutter-002`: base 35.8598 + diversity 3 + repetition (0) = 38.8598; `SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`. Winner margin 1.5537.
- `fog_plate_shutter-005`: base 34.7513 + diversity 3 + repetition (0) = 37.7513; `SHADOW -> ZERO -> SHUTTER -> PLATE_ABSENCE -> ORIENTATION`. Winner margin 2.6622.

Neighbor comparison:

- GR29: HEIGHT + LIGHT + SHUTTER; `REACH -> SHADOW -> LIGHT -> TYPE -> ZERO -> SHUTTER`; witness 10 vs 8, fog 3 vs 3, overlaps 0 vs 1.
- GR31: HEIGHT + LIGHT; `SHADOW -> REACH -> ZERO -> LIGHT -> TYPE`; witness 10 vs 8, fog 5 vs 3, overlaps 0 vs 1.

Plausible legal near misses and ALL rejecting visible evidence:

- D3:normal, D5:normal, C4:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **D4: expected 1, gets 2**.
- D3:normal, D5:normal, C4:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=B. Distance 1. Rejected by **D4: expected 1, gets 2**.
- D3:normal, D5:normal, C4:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=C. Distance 1. Rejected by **D4: expected 1, gets 2**.
- D3:normal, C4:normal, D5:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=D. Distance 1. Rejected by **B4: expected 0, gets 1**.

## GR31 — UNSEEN BUT KNOWN

Candidate: `fog_height_light-007`. Mechanics: **HEIGHT + LIGHT**.

Solution: D1:normal, C5:normal, D5:tall; lights=RIGHT+BOTTOM; shutter=none.

Legal states: **41,400**; exact survivors: **1**; independent enumeration: 0.053s.

FOG: E1, A2, E3, E4, B5. `?` is unobserved, never zero.

```text
    A B C D E
1   0 0 1 0 ?
2   ? 0 0 0 0
3   0 0 0 1 ?
4   0 0 1 1 ?
5   0 ? 1 0 0
```

Reasoning signature: **SHADOW -> REACH -> ZERO -> LIGHT -> TYPE**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| C1 = 1 | SHADOW | 8,850 | — |
| C5 = 1 | SHADOW | 1,535 | — |
| D3 = 1 | REACH | 284 | — |
| D4 = 1 | SHADOW | 76 | — |
| C4 = 1 | SHADOW | 16 | — |
| B2 = 0 | ZERO | 10 | — |
| C2 = 0 | ZERO | 5 | — |
| B1 = 0 | ZERO | 3 | LIGHT |
| D1 = 0 | ZERO | 2 | — |
| D2 = 0 | ZERO | 1 | TYPE |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, B1, D1, B2, C2, D2, E2, A3, B3, C3, A4, B4, A5, D5, E5 | 16 | True |
| overlap | — | 1 | False |
| tall_reach | D3 | 2 | False |
| plate_directional_absence | — | 1 | False |
| light_choice | C1, D2, D3, C4, D4, C5, D5, E5 | 1,842 | True |
| shutter_choice | — | 1 | False |

FOG removes the full-board best first clue `B5`. Best first-clue survivors rise from 425 to 8,850; witness cells 4 → 10. Hidden nonzero cells: B5.

Score components:

- distributed_evidence: +21.2000
- causal_ambiguity: +8.8811
- overlap_quality: +0.0000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +2.9000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.8000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 33.3811; diversity: +9; profile repetition: +0; selection total: **42.3811**.

Selection round 9: won among 40 eligible remaining candidates. Nearby alternatives at this decision:

- `fog_height_light-003`: base 32.7444 + diversity 9 + repetition (0) = 41.7444; `SHADOW -> REACH -> ZERO -> LIGHT -> TYPE`. Winner margin 0.6367.
- `fog_height_light-009`: base 32.2377 + diversity 9 + repetition (0) = 41.2377; `SHADOW -> REACH -> ZERO -> LIGHT -> TYPE`. Winner margin 1.1434.
- `fog_plate_shutter-002`: base 35.8598 + diversity 5 + repetition (0) = 40.8598; `SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`. Winner margin 1.5213.

Neighbor comparison:

- GR30: PLATE + SHUTTER; `OVERLAP -> SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`; witness 8 vs 10, fog 3 vs 5, overlaps 1 vs 0.
- GR32: PLATE + SHUTTER; `SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`; witness 9 vs 10, fog 3 vs 5, overlaps 0 vs 0.

Plausible legal near misses and ALL rejecting visible evidence:

- B1:normal, C3:normal, C4:tall; lights=TOP+LEFT; shutter=none. Distance 1. Rejected by **B2: expected 0, gets 1**.
- B1:normal, D3:normal, C3:tall; lights=TOP+LEFT; shutter=none. Distance 1. Rejected by **B2: expected 0, gets 1**.
- C3:normal, D3:normal, A5:tall; lights=TOP+LEFT; shutter=none. Distance 1. Rejected by **C1: expected 1, gets 0**.
- C3:normal, C4:normal, E2:tall; lights=TOP+LEFT; shutter=none. Distance 1. Rejected by **C1: expected 1, gets 0**.

## GR32 — READ THE REMAINDER

Candidate: `fog_plate_shutter-002`. Mechanics: **PLATE + SHUTTER**.

Solution: A4:normal, C4:normal, D3:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A.

Legal states: **69,000**; exact survivors: **1**; independent enumeration: 0.081s.

FOG: E2, C3, B4. `?` is unobserved, never zero.

```text
    A B C D E
1   0 0 0 0 0
2   0 0 0 0 ?
3   1 0 ? 0 1
4   0 ? 0 1 0
5   0 0 1 0 0
```

Reasoning signature: **SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| A3 = 1 | SHADOW | 16,964 | — |
| E3 = 1 | SHADOW | 3,156 | — |
| C5 = 1 | SHADOW | 324 | — |
| A5 = 0 | ZERO | 150 | — |
| E5 = 0 | ZERO | 48 | — |
| B2 = 0 | ZERO | 20 | — |
| D2 = 0 | PLATE_ABSENCE | 4 | — |
| D4 = 1 | PLATE_ABSENCE | 2 | SHUTTER |
| E1 = 0 | ZERO | 1 | ORIENTATION |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, B1, C1, D1, E1, A2, B2, C2, D2, B3, D3, A4, C4, E4, A5, B5, D5, E5 | 188 | True |
| overlap | — | 1 | False |
| tall_reach | — | 1 | False |
| plate_directional_absence | D2, D4 | 8 | True |
| light_choice | — | 1 | False |
| shutter_choice | A5, C5 | 13 | True |

FOG removes the full-board best first clue `C3`. Best first-clue survivors rise from 2,331 to 16,964; witness cells 6 → 9. Hidden nonzero cells: C3, B4.

Score components:

- distributed_evidence: +20.2000
- causal_ambiguity: +9.6598
- overlap_quality: +0.0000
- negative_evidence_quality: +2.4000
- mechanic_interaction: +4.4000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.8000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 35.8598; diversity: +5; profile repetition: -2; selection total: **38.8598**.

Selection round 12: won among 37 eligible remaining candidates. Nearby alternatives at this decision:

- `fog_height_plate_light-010`: base 33.2837 + diversity 5 + repetition (0) = 38.2837; `SHADOW -> ZERO -> REACH -> PLATE_ABSENCE -> ORIENTATION -> LIGHT -> TYPE`. Winner margin 0.5761.
- `fog_plate_shutter-005`: base 34.7513 + diversity 5 + repetition (-2) = 37.7513; `SHADOW -> ZERO -> SHUTTER -> PLATE_ABSENCE -> ORIENTATION`. Winner margin 1.1085.
- `fog_height_plate_light-004`: base 32.3797 + diversity 5 + repetition (0) = 37.3797; `SHADOW -> REACH -> ZERO -> LIGHT -> ORIENTATION -> TYPE`. Winner margin 1.4801.

Neighbor comparison:

- GR31: HEIGHT + LIGHT; `SHADOW -> REACH -> ZERO -> LIGHT -> TYPE`; witness 10 vs 9, fog 5 vs 3, overlaps 0 vs 0.
- GR33: HEIGHT + PLATE + SHUTTER; `OVERLAP -> ZERO -> SHADOW -> SHUTTER -> REACH -> TYPE -> ORIENTATION`; witness 10 vs 9, fog 0 vs 3, overlaps 2 vs 0.

Plausible legal near misses and ALL rejecting visible evidence:

- B3:normal, C4:normal, D3:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **B2: expected 0, gets 1**.
- D3:normal, A4:normal, C4:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **D2: expected 0, gets 1**.
- A4:normal, C4:normal, A1:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **E3: expected 1, gets 0**.
- A4:normal, C4:normal, E1:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **E3: expected 1, gets 0**.

## GR33 — FOUR VOICES

Candidate: `dense_height_plate_shutter-014`. Mechanics: **HEIGHT + PLATE + SHUTTER**.

Solution: A4:normal, A5:normal, C3:tall, D4:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A.

Legal states: **1,518,000**; exact survivors: **1**; independent enumeration: 1.834s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 0 1 0 0
2   0 0 1 0 0
3   2 1 0 1 1
4   1 1 2 0 1
5   0 1 1 0 0
```

Reasoning signature: **OVERLAP -> ZERO -> SHADOW -> SHUTTER -> REACH -> TYPE -> ORIENTATION**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| A3 = 2 | OVERLAP | 96,026 | — |
| C4 = 2 | OVERLAP | 6,442 | — |
| B2 = 0 | ZERO | 2,061 | — |
| A5 = 0 | ZERO | 700 | — |
| B4 = 1 | SHADOW | 240 | — |
| A4 = 1 | SHADOW | 81 | — |
| E4 = 1 | SHADOW | 13 | SHUTTER |
| C1 = 1 | REACH | 6 | TYPE |
| B5 = 1 | SHADOW | 3 | — |
| B3 = 1 | SHADOW | 1 | ORIENTATION |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, B1, D1, E1, A2, B2, D2, E2, C3, D4, A5, D5, E5 | 7 | True |
| overlap | A3, C4 | 2 | True |
| tall_reach | C1, A3, E3, C5 | 2 | True |
| plate_directional_absence | D3, D5 | 1 | False |
| light_choice | — | 1 | False |
| shutter_choice | C4, A5, C5 | 10 | True |

Score components:

- distributed_evidence: +21.6000
- causal_ambiguity: +5.9450
- overlap_quality: +2.6000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +5.1000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -1.6000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 34.8450; diversity: +3; profile repetition: -2; selection total: **35.8450**.

Selection round 15: won among 38 eligible remaining candidates. Nearby alternatives at this decision:

- `dense_height_plate_shutter-008`: base 34.4875 + diversity 3 + repetition (-2) = 35.4875; `OVERLAP -> SHADOW -> ZERO -> TYPE -> SHUTTER -> ORIENTATION`. Winner margin 0.3575.
- `dense_height_plate_shutter-013`: base 33.8450 + diversity 3 + repetition (-2) = 34.8450; `OVERLAP -> ZERO -> SHADOW -> REACH -> SHUTTER -> TYPE -> ORIENTATION`. Winner margin 1.0000.
- `dense_height_plate_light-005`: base 33.6883 + diversity 3 + repetition (-2) = 34.6883; `OVERLAP -> REACH -> ZERO -> SHADOW -> LIGHT -> TYPE -> PLATE_ABSENCE -> ORIENTATION`. Winner margin 1.1567.

Neighbor comparison:

- GR32: PLATE + SHUTTER; `SHADOW -> ZERO -> PLATE_ABSENCE -> SHUTTER -> ORIENTATION`; witness 9 vs 10, fog 3 vs 0, overlaps 0 vs 2.
- GR34: HEIGHT + PLATE + SHUTTER; `OVERLAP -> SHADOW -> ORIENTATION -> TYPE -> ZERO -> SHUTTER`; witness 10 vs 10, fog 0 vs 0, overlaps 4 vs 2.

Plausible legal near misses and ALL rejecting visible evidence:

- A4:normal, B4:normal, C3:tall, E5:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **B3: expected 1, gets 2**.
- A4:normal, A5:normal, C3:tall, C5:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **E4: expected 1, gets 0**.
- A4:normal, A5:normal, C3:tall, D4:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=B. Distance 1. Rejected by **A5: expected 0, gets 1**.
- A4:normal, A5:normal, C3:tall, D4:plate_v; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=D. Distance 1. Rejected by **A5: expected 0, gets 1**.

## GR34 — DENSE AGREEMENT

Candidate: `dense_height_plate_shutter-017`. Mechanics: **HEIGHT + PLATE + SHUTTER**.

Solution: C1:normal, C4:normal, D3:tall, E4:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=E.

Legal states: **1,518,000**; exact survivors: **1**; independent enumeration: 1.997s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 1 0 2 0
2   0 0 1 1 0
3   0 1 2 0 2
4   0 1 0 2 0
5   0 0 1 1 0
```

Reasoning signature: **OVERLAP -> SHADOW -> ORIENTATION -> TYPE -> ZERO -> SHUTTER**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| D1 = 2 | OVERLAP | 93,570 | — |
| E3 = 2 | OVERLAP | 4,722 | — |
| C3 = 2 | OVERLAP | 333 | — |
| C5 = 1 | SHADOW | 81 | — |
| B1 = 1 | SHADOW | 30 | — |
| D4 = 2 | OVERLAP | 13 | — |
| C2 = 1 | SHADOW | 8 | ORIENTATION, TYPE |
| E5 = 0 | ZERO | 4 | — |
| E1 = 0 | ZERO | 2 | SHUTTER |
| B4 = 1 | SHADOW | 1 | — |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, C1, E1, A2, B2, E2, A3, D3, A4, C4, E4, A5, B5, E5 | 5 | True |
| overlap | D1, C3, E3, D4 | 15 | True |
| tall_reach | D1, B3, D5 | 1 | False |
| plate_directional_absence | D4 | 1 | False |
| light_choice | — | 1 | False |
| shutter_choice | C2, D4, C5, D5, E5 | 10 | True |

Score components:

- distributed_evidence: +21.6000
- causal_ambiguity: +7.7115
- overlap_quality: +3.4000
- negative_evidence_quality: +1.2000
- mechanic_interaction: +6.6000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -1.6000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 38.9115; diversity: +5; profile repetition: +0; selection total: **43.9115**.

Selection round 13: won among 40 eligible remaining candidates. Nearby alternatives at this decision:

- `dense_height_plate_light-020`: base 35.1316 + diversity 5 + repetition (0) = 40.1316; `OVERLAP -> SHADOW -> REACH -> ZERO -> PLATE_ABSENCE -> LIGHT -> ORIENTATION -> TYPE`. Winner margin 3.7799.
- `dense_height_plate_shutter-014`: base 34.8450 + diversity 5 + repetition (0) = 39.8450; `OVERLAP -> ZERO -> SHADOW -> SHUTTER -> REACH -> TYPE -> ORIENTATION`. Winner margin 4.0665.
- `dense_height_plate_shutter-008`: base 34.4875 + diversity 5 + repetition (0) = 39.4875; `OVERLAP -> SHADOW -> ZERO -> TYPE -> SHUTTER -> ORIENTATION`. Winner margin 4.4240.

Neighbor comparison:

- GR33: HEIGHT + PLATE + SHUTTER; `OVERLAP -> ZERO -> SHADOW -> SHUTTER -> REACH -> TYPE -> ORIENTATION`; witness 10 vs 10, fog 0 vs 0, overlaps 2 vs 4.
- GR35: HEIGHT + PLATE + LIGHT; `OVERLAP -> SHADOW -> REACH -> ZERO -> PLATE_ABSENCE -> LIGHT -> ORIENTATION -> TYPE`; witness 10 vs 10, fog 0 vs 0, overlaps 2 vs 4.

Plausible legal near misses and ALL rejecting visible evidence:

- C1:normal, C4:normal, D3:tall, A1:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **E3: expected 2, gets 1**.
- C1:normal, C4:normal, D3:tall, E2:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **E1: expected 0, gets 1**.
- C1:normal, C4:normal, D3:tall, E4:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=A. Distance 1. Rejected by **E5: expected 0, gets 1**.
- C1:normal, C4:normal, D3:tall, B1:plate_h; lights=TOP+LEFT+RIGHT+BOTTOM; shutter=B. Distance 1. Rejected by **E3: expected 2, gets 1**.

## GR35 — THE LAST ALTERNATIVE

Candidate: `dense_height_plate_light-020`. Mechanics: **HEIGHT + PLATE + LIGHT**.

Solution: C3:normal, E3:normal, D2:tall, D1:plate_v; lights=TOP+LEFT+BOTTOM; shutter=none.

Legal states: **1,214,400**; exact survivors: **1**; independent enumeration: 1.609s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   0 0 0 1 1
2   0 0 1 0 2
3   0 0 0 2 0
4   0 0 1 1 1
5   0 0 0 0 0
```

Reasoning signature: **OVERLAP -> SHADOW -> REACH -> ZERO -> PLATE_ABSENCE -> LIGHT -> ORIENTATION -> TYPE**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| E2 = 2 | OVERLAP | 41,440 | — |
| D3 = 2 | OVERLAP | 4,026 | — |
| E1 = 1 | SHADOW | 827 | — |
| D4 = 1 | REACH | 124 | — |
| C4 = 1 | SHADOW | 34 | — |
| E3 = 0 | ZERO | 19 | — |
| C3 = 0 | ZERO | 9 | — |
| D2 = 0 | PLATE_ABSENCE | 5 | — |
| E4 = 1 | SHADOW | 3 | LIGHT |
| E5 = 0 | ZERO | 1 | ORIENTATION, TYPE |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | A1, B1, C1, A2, B2, D2, A3, B3, C3, E3, A4, B4, A5, B5, C5, D5, E5 | 11 | True |
| overlap | E2, D3 | 2 | True |
| tall_reach | D4 | 1 | False |
| plate_directional_absence | D2 | 2 | True |
| light_choice | C1, D1, E1, B2, C2, E2, B3, D3, C4, D4, E4 | 1,046 | True |
| shutter_choice | — | 1 | False |

Score components:

- distributed_evidence: +21.2000
- causal_ambiguity: +7.8470
- overlap_quality: +2.6000
- negative_evidence_quality: +2.4000
- mechanic_interaction: +5.1000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -4.0154
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 35.1316; diversity: +3; profile repetition: +0; selection total: **38.1316**.

Selection round 14: won among 39 eligible remaining candidates. Nearby alternatives at this decision:

- `dense_height_plate_light-005`: base 33.6883 + diversity 3 + repetition (0) = 36.6883; `OVERLAP -> REACH -> ZERO -> SHADOW -> LIGHT -> TYPE -> PLATE_ABSENCE -> ORIENTATION`. Winner margin 1.4433.
- `dense_height_plate_shutter-014`: base 34.8450 + diversity 3 + repetition (-2) = 35.8450; `OVERLAP -> ZERO -> SHADOW -> SHUTTER -> REACH -> TYPE -> ORIENTATION`. Winner margin 2.2866.
- `dense_height_plate_shutter-008`: base 34.4875 + diversity 3 + repetition (-2) = 35.4875; `OVERLAP -> SHADOW -> ZERO -> TYPE -> SHUTTER -> ORIENTATION`. Winner margin 2.6441.

Neighbor comparison:

- GR34: HEIGHT + PLATE + SHUTTER; `OVERLAP -> SHADOW -> ORIENTATION -> TYPE -> ZERO -> SHUTTER`; witness 10 vs 10, fog 0 vs 0, overlaps 4 vs 2.
- GR36: HEIGHT + PLATE + LIGHT + SHUTTER; `OVERLAP -> SHADOW -> REACH -> LIGHT -> ORIENTATION -> TYPE -> SHUTTER`; witness 10 vs 10, fog 0 vs 0, overlaps 2 vs 2.

Plausible legal near misses and ALL rejecting visible evidence:

- D1:normal, C3:normal, D2:tall, E3:plate_h; lights=TOP+LEFT+BOTTOM; shutter=none. Distance 1. Rejected by **D2: expected 0, gets 1**.
- E1:normal, C3:normal, D2:tall, D1:plate_v; lights=TOP+LEFT+BOTTOM; shutter=none. Distance 1. Rejected by **E4: expected 1, gets 0**.
- E1:normal, C3:normal, D2:tall, D4:plate_v; lights=TOP+LEFT+BOTTOM; shutter=none. Distance 1. Rejected by **E1: expected 1, gets 0**.
- E1:normal, C3:normal, D2:tall, E5:plate_h; lights=TOP+LEFT+BOTTOM; shutter=none. Distance 1. Rejected by **E1: expected 1, gets 0**.

## GR36 — DEEP CALIBRATION

Candidate: `finale-015`. Mechanics: **HEIGHT + PLATE + LIGHT + SHUTTER**.

Solution: A2:normal, C4:normal, B3:tall, E4:plate_h; lights=TOP+LEFT+BOTTOM; shutter=D.

Legal states: **6,072,000**; exact survivors: **1**; independent enumeration: 7.247s.

FOG: none. `?` is unobserved, never zero.

```text
    A B C D E
1   1 1 0 0 0
2   0 2 0 0 0
3   1 0 2 1 1
4   0 1 0 1 0
5   0 1 1 0 1
```

Reasoning signature: **OVERLAP -> SHADOW -> REACH -> LIGHT -> ORIENTATION -> TYPE -> SHUTTER**

| Evidence | Kind | Worlds remaining | Newly resolved assignment |
|---|---|---:|---|
| B2 = 2 | OVERLAP | 316,696 | — |
| C3 = 2 | OVERLAP | 25,563 | — |
| E5 = 1 | SHADOW | 2,930 | — |
| B1 = 1 | REACH | 326 | — |
| E3 = 1 | SHADOW | 88 | — |
| A1 = 1 | SHADOW | 32 | — |
| B5 = 1 | REACH | 10 | LIGHT, ORIENTATION, TYPE |
| D4 = 1 | SHADOW | 3 | — |
| A3 = 1 | SHADOW | 2 | — |
| C5 = 1 | SHADOW | 1 | SHUTTER |

Evidence ablation (remove the entire named cell group, retain all other visible cells):

| Group | Removed cells | Survivors | Depends on group |
|---|---|---:|---|
| zero | C1, D1, E1, A2, C2, D2, E2, B3, A4, C4, E4, A5, D5 | 1 | False |
| overlap | B2, C3 | 2 | True |
| tall_reach | B1, D3, B5 | 1 | False |
| plate_directional_absence | — | 1 | False |
| light_choice | A1, B1, B2, A3, C3, D3, E3, B4, D4, B5, C5, E5 | 15,150 | True |
| shutter_choice | A3, B4, B5, C5, E5 | 25 | True |

Score components:

- distributed_evidence: +22.0000
- causal_ambiguity: +7.8470
- overlap_quality: +2.6000
- negative_evidence_quality: +0.0000
- mechanic_interaction: +5.8000
- symmetry_penalty: +0.0000
- edge_abuse_penalty: -0.0000
- trivial_witness_penalty: +0.0000
- long_witness_penalty: -0.0000
- near_duplicate_penalty: +0.0000
- Base: 38.2470; diversity: +7; profile repetition: +0; selection total: **45.2470**.

Selection round 16: won among 5 eligible remaining candidates. Nearby alternatives at this decision:

- `finale-019`: base 38.2115 + diversity 7 + repetition (0) = 45.2115; `OVERLAP -> SHADOW -> ZERO -> ORIENTATION -> LIGHT -> SHUTTER -> TYPE`. Winner margin 0.0355.
- `finale-010`: base 37.7708 + diversity 7 + repetition (0) = 44.7708; `OVERLAP -> SHADOW -> REACH -> PLATE_ABSENCE -> TYPE -> ZERO -> LIGHT -> ORIENTATION -> SHUTTER`. Winner margin 0.4762.
- `finale-016`: base 34.6589 + diversity 7 + repetition (0) = 41.6589; `OVERLAP -> SHADOW -> REACH -> ZERO -> LIGHT -> TYPE -> SHUTTER -> ORIENTATION -> PLATE_ABSENCE`. Winner margin 3.5881.

Neighbor comparison:

- GR35: HEIGHT + PLATE + LIGHT; `OVERLAP -> SHADOW -> REACH -> ZERO -> PLATE_ABSENCE -> LIGHT -> ORIENTATION -> TYPE`; witness 10 vs 10, fog 0 vs 0, overlaps 2 vs 2.

Plausible legal near misses and ALL rejecting visible evidence:

- A2:normal, C4:normal, B3:tall, E4:plate_h; lights=TOP+LEFT+BOTTOM; shutter=A. Distance 1. Rejected by **A3: expected 1, gets 0**.
- A2:normal, C4:normal, B3:tall, E4:plate_h; lights=TOP+LEFT+BOTTOM; shutter=C. Distance 1. Rejected by **C5: expected 1, gets 0**.
- A2:normal, C4:normal, B3:tall, D3:plate_v; lights=TOP+LEFT+BOTTOM; shutter=D. Distance 1. Rejected by **E5: expected 1, gets 0**.
- A2:normal, C4:normal, B3:tall, D5:plate_v; lights=TOP+LEFT+BOTTOM; shutter=D. Distance 1. Rejected by **E3: expected 1, gets 0**.

## Review / integration boundary

No Godot code, playable campaign registration, saves, or existing stage data were changed. The draft preserves parsed GR01–GR20 objects exactly. FOG integration later needs an explicit visibility check in `ExperimentOptics.matches`, unknown target rendering, and UI tests. Loading this draft through today's zero-default target matcher would be incorrect; it is marked review-only.

Review the evidence chains, especially whether the authored-solution labels translate into discoverable deductions. The sequence has no repeated adjacent mechanic+reasoning signature, but its automatic scores are not playtest timings. See `docs/GRANT36_GENERATION.md` for metric definitions, dependencies, and validation boundaries.
