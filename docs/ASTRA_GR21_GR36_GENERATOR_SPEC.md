# Astra Task: GR21–GR36 Deep Calibration Generator v0.1

## Goal

Extend SHADOW SUM beyond the current GRANT20 v0.3 tutorial/synthesis arc.

The current player feedback is that GR01–GR20 can be cleared in about five minutes, with GR20 being the first stage that feels like a real puzzle. Build a generator/solver pipeline that produces **100–200 viable late-game candidates**, then automatically selects **16 meaningfully different puzzles** for a draft GR21–GR36 set.

This task is about **depth from existing rules**, not adding another gimmick.

Do not add Reflection/Mirrors or Observation switching.

## Work branch

Start from:

```text
feature/grant20-v0.3
```

Create your own working branch, for example:

```text
feature/grant36-generator
```

Do not merge to main.

## Existing optical model

Authoritative runtime model:

```text
src/experiment_optics.gd
```

Rules already available:

- Normal Post: casts 1 cell along every active light direction.
- Tall Post: casts 2 cells along every active light direction.
- Flat Plate vertical (`plate_v`): responds only to LEFT / RIGHT.
- Flat Plate horizontal (`plate_h`): responds only to TOP / BOTTOM.
- Lights: TOP / LEFT / RIGHT / BOTTOM.
- Shutter: blocks TOP contribution for all objects in one column.
- Multiple contributions add shadow intensity.
- Wrong states are valid physical experiments.
- One board only. No Observation A/B switching.

Use the coordinate and direction conventions already implemented in `src/experiment_optics.gd` and `tools/validate_grant20_v03.py`.

## FOG semantics

FOG is allowed for late-game candidates.

FOG means **unobserved target cell**, never zero.

A fogged TARGET cell imposes no equality constraint on the candidate state.

For generated FOG candidates:

- hide only 3–6 cells,
- keep at least 19 of 25 target cells observed,
- the authored world must still be unique under all visible cells,
- avoid hiding cells merely to inflate difficulty,
- prefer hiding cells that remove an obvious shortcut while leaving a clean multi-step deduction,
- FOG is an observation constraint, not a new optical rule.

The generator may represent fog internally as a visibility mask. Do not silently reuse the old Grant18 clue format unless it cleanly fits the new experiment campaign.

Runtime/UI integration of FOG is secondary to generator quality. If integration would balloon the task, output draft stage data with an explicit `fog_cells` field and document the required runtime change rather than forcing a fragile implementation.

## Candidate families

Generate candidates across these buckets.

### GR21–GR24: two-cause puzzles

Use exactly two major unknown-cause families per puzzle.

Examples:

- HEIGHT + LIGHT
- PLATE + LIGHT
- SHUTTER + LIGHT
- HEIGHT + PLATE
- HEIGHT + SHUTTER
- PLATE + SHUTTER

Avoid simply reproducing GR14–GR19 with translated coordinates.

### GR25–GR28: three-cause puzzles

Use three interacting families.

Examples:

- Normal/Tall + Light + Shutter
- Tall + Plate + Light
- Tall + Plate + Shutter
- Plate + Light + Shutter

The desired feel is:
one deduction leaves 2–4 plausible states, a second deduction collapses that ambiguity, and a final zero/overlap/reach clue confirms the answer.

### GR29–GR32: FOG puzzles

Use 3–6 fogged target cells.

At least two of these should combine FOG with nontrivial object properties such as Tall or Flat Plate.

At least one should combine FOG with Light or Shutter uncertainty.

Do not produce “information-starved” brute-force boards.

### GR33–GR35: dense synthesis

No new rule.

Use 3–4 objects and 3–4 existing cause families.

These should be harder because several familiar explanations compete, not because every control is unknown.

### GR36: final calibration

Search for a finale stronger than GR20 while still readable.

Preferred profile to explore first:

- 4 objects total
- Normal x2
- Tall x1
- Flat Plate x1
- Flat Plate orientation unknown
- exactly 3 of 4 lights active
- one movable TOP shutter
- no FOG unless a fully visible finale is clearly too easy

A 4-object finale is allowed to have a state space in the low millions if the implementation is optimized.

If that profile does not produce a clean puzzle, report why and choose the best nearby profile rather than forcing it.

## Generation strategy

Do not validate 200 candidates by naïvely re-running a complete nested exhaustive search from scratch for each board.

Prefer **profile-based reverse indexing**:

1. Define a mechanic/profile, such as:
   `normal=1, tall=1, plate=1, lights=choose3of4, shutter=movable`.
2. Enumerate every legal world state for that profile once.
3. Compute its complete 25-cell shadow signature.
4. Build a reverse index:
   `shadow_signature -> list[world_state]`.
5. A fully visible signature with exactly one state is automatically a unique puzzle.
6. For FOG, project signatures through a visibility mask and require exactly one surviving state.
7. Cache/profile results so candidate scoring is cheap.

Use deterministic seeds and make the run reproducible.

Suggested default seed:

```text
20260922
```

## Candidate pool target

Produce:

- at least **150 raw unique candidates** after exact uniqueness filtering,
- ideally 180–250 if runtime remains reasonable,
- at least 20 candidates per major bucket before final selection,
- mirrored/near-duplicate boards deduplicated.

Left/right mirror equivalents should normally count as duplicates. Account for LEFT/RIGHT lamp swapping and shutter-column reflection when canonicalizing.

## “Different solving path” metrics

Do not rank by state-space size alone. That is not human difficulty.

For each candidate compute a feature/signature record containing at least:

- mechanic families present,
- number and type of objects,
- active-light uncertainty,
- shutter uncertainty,
- plate orientation uncertainty,
- fog count,
- number of nonzero target cells,
- number of zero target cells,
- max shadow intensity,
- overlap cell count,
- Tall far-cell count,
- edge/off-board contribution count,
- total legal world states in the profile,
- count of states at shadow Hamming distance 1,
- count of states at shadow Hamming distance <= 2,
- minimum or greedy witness-cell count needed to distinguish the authored world,
- whether uniqueness depends on at least one zero cell,
- whether uniqueness depends on at least one overlap cell,
- whether uniqueness depends on Tall reach,
- whether uniqueness depends on Plate directional absence,
- whether uniqueness depends on Light choice,
- whether uniqueness depends on Shutter choice.

For FOG candidates compute these metrics over visible cells.

Also derive a compact **reasoning signature**, for example:

```text
REACH -> LIGHT -> ZERO
PLATE_ABSENCE -> SHUTTER -> OVERLAP
OVERLAP -> TYPE -> LIGHT
ZERO -> REACH -> ORIENTATION
```

The exact implementation can differ, but the final sixteen should not all share the same signature.

## Selection requirements

Select 16 from the candidate pool with a diversity-aware algorithm.

Hard requirements:

- GR21–24: 4 two-cause puzzles
- GR25–28: 4 three-cause puzzles
- GR29–32: 4 FOG puzzles
- GR33–35: 3 dense synthesis puzzles
- GR36: 1 finale
- no duplicate or mirror-equivalent solutions
- no two adjacent stages with effectively identical mechanic + reasoning signatures
- every selected stage exact-unique under the complete legal state space
- every selected stage solvable without Observation switching
- no Reflection/Mirror mechanic

Soft preference:

- gradual rise in candidate ambiguity,
- different first deductions across adjacent puzzles,
- mix of positive evidence (shadow/reach/overlap) and negative evidence (zero/absence),
- avoid excessive edge exploitation,
- avoid stages whose only practical solution is toggling every combination until clear.

## Scoring

Create an explicit scoring function and print its components.

A reasonable shape is:

```text
interestingness =
    diversity_bonus
  + distributed_evidence
  + causal_ambiguity
  + overlap_quality
  + negative_evidence_quality
  + mechanic_interaction
  - symmetry_penalty
  - edge_abuse_penalty
  - trivial_witness_penalty
  - near_duplicate_penalty
```

Do not hide selection judgment inside opaque constants. Document the weights and print why each selected puzzle beat nearby alternatives.

## Deliverables

Add:

```text
tools/generate_deep_calibration.py
tools/validate_grant36_draft.py
generated/grant36_candidates.json
generated/grant36_ranked.csv
generated/grant36_selection_report.md
data/grant36_v0_4_draft.json
docs/GRANT36_GENERATION.md
```

If a helper module materially improves clarity, add it under `tools/`.

The candidate JSON should preserve enough data to reproduce each puzzle:

- seed
- profile
- solution object positions/types
- active lights
- shutter
- complete shadow
- visible/fog mask
- metrics
- reasoning signature
- score

The ranked CSV should make it easy to inspect candidates without opening JSON.

The selection report must contain, for each chosen GR21–GR36:

- stage title,
- solution state,
- visible target,
- fog cells if any,
- exact search-space size,
- exact surviving solution count,
- main mechanic combination,
- reasoning signature,
- score breakdown,
- why it differs from its neighbors,
- 2–4 plausible near-miss worlds and exactly which evidence rejects them.

## Draft campaign data

`data/grant36_v0_4_draft.json` should contain:

- GR01–GR20 copied unchanged from `data/grant20_v0_3.json`,
- selected GR21–GR36 appended,
- no hand-wavy placeholders,
- exact solution metadata for all new stages,
- `expected_states`,
- `fog_cells` only where used.

Hints are optional for GR21–GR36 in this task. Prefer no hints over low-quality hints.

## Validation

`tools/validate_grant36_draft.py` must independently re-enumerate every GR21–GR36 legal state and assert:

- authored solution is legal,
- authored solution matches every visible target cell,
- exactly one legal state matches all visible evidence,
- solution metadata matches the unique state,
- expected state count is exact,
- fog cells are treated as unobserved rather than zero.

The validator must not reuse generator ranking logic to establish uniqueness.

Also keep the existing suite green:

```text
python tools/validate_grant20_v03.py
python tools/validate_flat_plate.py
python tools/validate_light_height.py
python tools/validate_cause_light.py
```

Do not break GRANT20 runtime.

## Performance

Astra may optimize aggressively inside generator/validator tooling.

Suggested techniques:

- tuple/int encoded shadows,
- precomputed per-object/per-light contribution vectors,
- cached profile world lists,
- reverse signature maps,
- bit masks for visibility,
- multiprocessing only if deterministic output remains easy to reproduce.

Record total generation time and peak candidate counts by profile in the report.

## Stop conditions

Do not automatically wire GR21–GR36 into the playable Godot campaign unless the selected sixteen have been generated, independently validated, and the selection report is convincing.

The first milestone is:

> generator + 150+ viable candidates + exact validator + diverse selected sixteen + draft data + readable report

Then stop and report results for human review.

## Definition of done

The task is complete when:

1. one command reproduces the pool and selection,
2. at least 150 exact-unique candidates are produced,
3. exactly 16 are selected into GR21–GR36,
4. all 16 pass an independent exhaustive validator,
5. FOG candidates treat hidden cells as unknown, not zero,
6. the sixteen demonstrate visibly different reasoning signatures,
7. GR36 is materially deeper than GR20 without introducing a new rule,
8. existing GRANT20 tests remain green,
9. the report makes it possible to judge the puzzles before integrating them into Godot.

Do not optimize for “largest state count.” Optimize for **distinct, legible chains of deduction**.
