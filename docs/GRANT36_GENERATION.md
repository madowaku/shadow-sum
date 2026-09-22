# GRANT36 draft generation and review

This milestone produces reviewable puzzle data, not a playable campaign. Start with
[`generated/grant36_selection_report.md`](../generated/grant36_selection_report.md).
It contains all sixteen target grids, solutions, exact witness traces, score
components, nearby selection alternatives, neighbor comparisons, and four legal
near-miss worlds per stage with every rejecting visible cell.

## Reproduce

Python 3.10+ and NumPy 2.x are required for generation. The checked run used Python
3.14.3 / NumPy 2.4.4 on Windows; the actual versions are saved in the candidate JSON.
The independent validator and existing validators use only the standard library.

```text
python -m pip install -r tools/requirements-grant36.txt
python tools/generate_deep_calibration.py
```

After dependency installation, the second command performs the entire milestone:
reverse indexing, candidate filtering, scoring, selection, draft export, independent
exhaustive validation, and report generation. Default seed: **20260922**.

```text
python tools/generate_deep_calibration.py --seed 20260922 --output-root <review-directory>
python tools/validate_grant36_draft.py
python tools/test_deep_calibration.py
python tools/validate_grant20_v03.py
python tools/validate_flat_plate.py
python tools/validate_light_height.py
python tools/validate_cause_light.py
```

`--output-root` redirects only outputs; the original GRANT20 data and validator
source remain rooted in this repository. Other seeds are exploratory: quality and
finale gates are not weakened to force a successful selection. A failed gate exits
with an error. Use a separate output directory when exploring other seeds.

## Artifacts

| File | Purpose |
|---|---|
| `tools/generate_deep_calibration.py` | Pipeline, feature extraction, scoring, selection, exports |
| `tools/deep_calibration_model.py` | Generator-only NumPy state enumerator and reverse index |
| `tools/validate_grant36_draft.py` | Independent exhaustive verification and report audit |
| `tools/test_deep_calibration.py` | Optical, enumeration, FOG, corruption and equivalence regressions |
| `generated/grant36_candidates.json` | All 192 retained exact-unique candidates, full metadata and profile census |
| `generated/grant36_ranked.csv` | Global base-score ranking, selected stage IDs, features and score components |
| `generated/grant36_selection_report.md` | Human review document |
| `generated/grant36_validation.json` | Per-stage independent state counts, witness counts, FOG checks and timings |
| `generated/grant36_verification.json` | Recorded development checks and reproducibility evidence |
| `data/grant36_v0_4_draft.json` | GR01–GR20 unchanged as parsed objects, followed by the selected sixteen |

The verification snapshot records development checks; the generator reproduces
all other generated artifacts. Timing fields vary by run. Candidate identities,
solutions, metrics, scores and selection are deterministic for the recorded seed
and environment. Raw file hashes are provenance for that checkout; Git LF/CRLF conversion can change them. Unchanged GR01–GR20 is checked by parsed JSON equality. No timestamps or random IDs affect candidate generation.

## Legal worlds and performance

The board is A1–E5, indexed row-major. TOP casts downward; LEFT casts rightward;
RIGHT casts leftward; BOTTOM casts upward. Objects never share an origin cell.
They do not occlude one another; contributions add even onto another object's cell.
A TOP shutter blocks every TOP ray from objects in its column. Plate orientation
is always unknown when a plate is movable in these profiles.

Each physical profile is enumerated once. Identical normal/tall copies use
combinations, not labelled permutations. Plate orientations use an explicit binary
choice. Lamp combinations and all five shutter columns are included, even when a
configuration makes the shutter ineffective. No states are removed because they
look unreasonable or do not use every object effectively.

For inventory `(n, t, p)`, the exact count is:

```text
choose(25,n) * choose(25-n,t) * choose(25-n-t,p) * 2^p
    * number_of_light_sets * number_of_shutter_states
```

The finale has `300 * 23 * 22 * 2 * 4 * 5 = 6,072,000` worlds.
Atomic 25-byte shadow vectors are precomputed, then NumPy adds contributions into
one matrix. Byte signatures are reverse-indexed using `numpy.unique`, keeping
signature multiplicities and representative world IDs. A multiplicity of exactly
one proves full-board uniqueness; it does not rely on a sampled solver.

FOG starts with these full-unique worlds, then projects **all** worlds through a
visibility mask, including worlds whose complete signatures are nonunique. Exactly
one surviving world is required. Full and FOG variants of the same physical
profile reuse the in-memory index. Only one physical profile's matrix is retained
at a time. There is no opaque disk cache to invalidate. The report's full-unique
counts are the peak available candidate counts before sampling/quality/deduplication.

Per-profile seeded permutations sample viable signatures until explicit quotas
are filled: two-cause 48, three-cause 40, FOG 40, dense 40, finale 24. This is a
reproducible sample of the exact-unique space, not a claim to rank every possible
puzzle. Rejection counts and the number of sampled/scored worlds are saved.

## Quality, diversity and ordering

HEIGHT means uncertainty about the placement of Tall objects among the inventory;
PLATE includes position and orientation; LIGHT is uncertain lamp choice; SHUTTER
is an uncertain column. Ordinary object position is a shared baseline variable,
not a fifth major family. Two- and three-cause profiles use three objects to avoid
merely translating the older two-object GR14–GR18 problems. Dense/finale use four.

Hard candidate quality gates require 6–17 nonzero cells before fog, at least one
overlap, a visible contribution from every object, at most 25% off-board rays,
and at least four greedy witness cells. Three-cause, FOG, dense and finale candidates
must include an intermediate witness step with 2–4 surviving worlds.

FOG hides 3–6 cells, including the strongest full-board first clue and at least one
nonzero cell. Its best first visible clue leaves more worlds than the original
best first clue, and the witness does not become shorter. Its witness is capped
at ten cells: hiding information is not rewarded without bound. There is no
information-starvation claim based solely on visibility count.

Canonical solution keys include object material, relative positions, lights and
relative shutter column, across translation and horizontal reflection. LEFT/RIGHT
lamps swap under reflection; vertical/horizontal plate orientation does not change.
This conservatively excludes translated arrangements even when clipping would
change their targets. It also excludes arrangements already used in GR14–GR20.
Within identical physical profiles (including across full/FOG buckets), reject
pairs differing in at most two common visible target cells, including reflections.
Reflection is only a duplicate check; no optical mirror mechanic is introduced.

The report prints every score component and formula. Witness reward saturates at
ten cells, with a penalty for longer witnesses. No component rewards raw legal
state count. The selector uses fixed bucket quotas plus explicit mechanic,
reasoning and first-evidence novelty bonuses; it penalizes repeated profiles.
It records three nearby alternatives, selection scores and winning margins at each
selection round. Then it orders stages within each bucket by increasing count of
Hamming-distance <=2 competitors, keeping adjacent mechanic+signature pairs distinct.
Selection-round numbers refer to the original diversity selection, not stage order.

## Feature definitions

All target-based features and Hamming distances use only observed cells. Off-board
rays, inventory and total legal states remain physical-profile features.

- **Hamming 1 / <=2:** number of legal competing worlds differing in exactly one,
  or one/two, observed cell intensities. The authored world is excluded. Intensities
  are compared for equality, not absolute magnitude.
- **Greedy witness:** repeatedly choose the observed cell leaving the fewest current
  survivors; break ties in row-major order. Save the actual remaining world count
  after every clue. The result is sufficient, not proven minimum or irreducible.
- **REACH:** a witnessed cell reached by an authored Tall object's second step.
- **PLATE_ABSENCE:** a cell a normal object would affect in a direction the authored
  plate ignores, with the current lights/shutter. It can have nonzero intensity
  from a different object; the absence concerns a contribution, not the total.
- **ZERO / OVERLAP / SHADOW:** target intensity 0, >=2, or ordinary positive evidence.
  Label precedence is zero/plate absence, overlap, reach, plate absence, shadow.
- **TYPE resolution:** all remaining worlds agree on the Tall position assignment.
  **ORIENTATION resolution:** all remaining worlds agree on plate orientation.
  **LIGHT / SHUTTER resolution:** all remaining worlds agree on that setting.
- **Reasoning signature:** first occurrence of each evidence/resolution label in
  the greedy trace. The full trace preserves repeated clues. These retrospective
  labels are inspectable solving-path proxies, not a human solver model.
- **Zero / overlap dependency:** remove all observed zero / overlap constraints;
  uniqueness depends on that group if more than one world survives. This does not
  assert that an individual cell in the group is necessary.
- **Tall reach dependency:** remove the authored far-cell group; report true when
  competing Tall assignments survive. **Plate directional absence dependency:**
  remove the potential forbidden-direction cells; report true when competing
  orientations survive. The report includes all removed cells and survivor counts.
- **Light / shutter dependency:** change only that setting in the authored world;
  take the union of affected visible cells over every alternative setting. Remove
  that evidence group and test whether different settings now survive. This is an
  explicit intervention-based proxy, not merely a flag that the control exists.
- **Interaction:** count pairs of objects with intersecting shadow footprints.
  Off-board counts include allowed, unblocked attempted rays that leave the board;
  plate-suppressed and shutter-blocked rays are not counted as off-board.

GR36 must improve over GR20 on witness length and distance<=2 competitors, have at
least as many overlap cells, no additional off-board rays, and contain a 2–4-world
intermediate step. The chosen preferred-profile finale has 10 witness cells versus
8, 92 close competitors versus 86, two overlap cells versus one, and zero lost rays each.
Those are concrete differences; perceived difficulty and discoverability still
need human review. Greedy first clues often prefer overlap because it is rare;
the pipeline does not relabel clues to pretend every first deduction differs.

## Independent validation boundary

The validator imports only the pre-existing `validate_grant20_v03.py` legal-state
and optical reference, never the generator/model/ranking code or reverse index.
It re-enumerates every GR21–GR36 world independently. A separate ray precomputation
packs intensities into 4-bit lanes; at most four objects can contribute to a cell,
so addition cannot carry into the next cell. A regression test compares packed
addition with direct ray casting on 500 four-object worlds.

The validator checks exact state count, authored legality, unique visible match,
all solution metadata, profile/draft consistency, unchanged GR01–GR20, all bucket
quotas and translated/mirrored duplicates. It also independently counts every
witness-prefix survivor set and verifies each near miss and all its rejection
cells. Every FOG stage includes a hidden nonzero value: explicitly treating missing
cells as zero would reject the valid authored world, and that distinction is tested.
Pool uniqueness comes from the generator's exact complete reverse index/projection;
the separate exhaustive validator proves uniqueness again for the selected sixteen.

Development checks also cover every atomic ray across 25 cells, 4 materials,
15 nonempty lamp subsets and 6 shutter settings (9,000 cases), all 9,000 worlds in
a small unlabelled profile, mirror/lamp/shutter equivalence, corruption rejection,
and ambiguous targets. The four pre-existing validators are required to remain green.

## Godot integration is intentionally deferred

No source under `src/`, scenes, campaign registration, save paths, or original
GRANT20 data is changed. New stages use one observation and only existing optics.
`review_only: true` marks the draft. Target dictionaries explicitly include every
visible zero and omit fog cells; `fog_cells` exists only on FOG stages. Complete
shadow and exact solution metadata are retained separately for review.

Before making this playable, the target matcher must skip explicit fog cells,
the target surface must render unknown cells, and interaction/save/smoke tests must
cover those changes. Today's `ExperimentOptics.matches` defaults omitted cells to
zero, so the FOG draft must not be wired directly into the current runtime.
