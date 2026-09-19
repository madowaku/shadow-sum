# SHADOW SUM — Grant submission 18

## Scope and honest readiness

This revision is a curated playable demonstration for the Draknek submission, not the 100-puzzle release. Thirteen puzzles were reworked; 001–003, 012 and 013 retain their original placements/clues because their teaching roles remain useful. Rules, exact Post-count solve condition, drag/magnetic semantics and 0.45-second solve breath are unchanged. The final three puzzles now have visible footholds and bounded hypothetical arguments rather than nested search.

Automated checks establish uniqueness, valid deduction traces, stable interaction and readable layouts. They do **not** establish human difficulty, solve times, fun, accessibility on a phone, or grant selection prospects. Independent first-time playtesting is still required before calling this submission-final.

## Rhythm

| Stages | Chapter | Purpose |
|---|---|---|
| 001–003 | INTRO | Projection → overlap → triple shadow |
| 004–006 | FOG | Unknown versus zero → exclusions → edges |
| 007–009 | LINKS | Connect deductions, then a lighter consolidation |
| 010–012 | BALANCE | One remaining Post → two → sparse reuse |
| 013–015 | DOUBT | A short contradiction, transfer, then a breather |
| 016–018 | AFTERGLOW | Combine the learned ideas and finish with three Posts |

## Per-puzzle review and walkthrough

The following is author/QA documentation, never shown as an automatic solution. `direct` means a saturated/empty source set; `subset` means subtracting one source-set equation from another (including the remaining Post count). `contradiction` tries one socket and propagates those same rules, never a nested hypothesis. The chosen trace favors short arguments that establish a Post. Trace length/order is not a human difficulty rating.

### 001 — FIRST LIGHT

Learn the three-direction projection with one central Post.

Posts: 1; fogged clues: 0; directly established Posts: 1; hypothetical steps: 0.

QA solution: C3.

Whispers:
1. Place one Post. Watch its three shadows.
2. Its shadow falls left, right, and below.
3. One socket can explain all three marks.

- direct: B3 establishes C3 occupied.

### 002 — OVERLAP

Two ordinary shadows add into a darker overlap.

Posts: 2; fogged clues: 0; directly established Posts: 2; hypothetical steps: 0.

QA solution: B2, C3.

Whispers:
1. Find the darker overlap.
2. Two Posts must cast into that glass.
3. Clear glass rules out one of those sources.

- direct: A2 establishes B2 occupied.
- direct: B3 establishes C3 occupied.

### 003 — BLACK CORE

A triple shadow needs all three possible sources.

Posts: 3; fogged clues: 0; directly established Posts: 3; hypothetical steps: 0.

QA solution: C2, B3, D3.

Whispers:
1. Start with the darkest shadow.
2. Which three sockets can reach it?
3. All three sources are needed.

- direct: C3 establishes C2, B3, D3 occupied.

### 004 — FIRST FROST

Fog is missing information, not zero. Only two Posts; the first fog actually hides a shadow, another hides clear glass.

Posts: 2; fogged clues: 4; directly established Posts: 2; hypothetical steps: 0.

QA solution: B2, D3.

Uses the existing three-beat UNKNOWN lesson. No WHISPER catalog entry or hidden-value reveal is added.

- direct: A2 establishes B2 occupied.
- direct: C3 establishes D3 occupied.

### 005 — CLEAR PATH

Use a clear cell to exclude sources, then use that absence to locate the third Post.

Posts: 3; fogged clues: 7; directly established Posts: 3; hypothetical steps: 0.

QA solution: B2, D2, C4.

Whispers:
1. Clear glass is evidence, too.
2. Which sources do these clear cells exclude?
3. Now the right-hand mark has only one source.

- direct: A2 establishes B2 occupied.
- direct: C2 establishes D2 occupied.
- direct: D4 establishes C4 occupied.

### 006 — AT THE EDGE

Boundary clipping is the same rule with fewer sources; read an edge mark backward.

Posts: 3; fogged clues: 11; directly established Posts: 3; hypothetical steps: 0.

QA solution: A1, E2, D4.

Whispers:
1. At an edge, some shadow directions fall away.
2. Use the clear glass to remove nearby sources.
3. The left mark can come from above or right.

- direct: A2 establishes A1 occupied.
- direct: E3 establishes E2 occupied.
- direct: C4 establishes D4 occupied.

### 007 — THREAD

Turn a clear cell into a two-source double-shadow deduction.

Posts: 4; fogged clues: 12; directly established Posts: 4; hypothetical steps: 0.

QA solution: C2, C3, D4, E4.

Whispers:
1. Trace the double shadow near the bottom.
2. Clear glass below rules out its left source.
3. Two sources remain for a double shadow.

- direct: B2 establishes C2 occupied.
- direct: C4 establishes C3, D4 occupied.
- direct: E5 establishes E4 occupied.

### 008 — CROSSCURRENT

Combine two double-shadow footholds and notice the shared middle shadow.

Posts: 4; fogged clues: 13; directly established Posts: 4; hypothetical steps: 0.

QA solution: B2, D2, C3, D4.

Whispers:
1. Two double shadows give two starting points.
2. Use clear glass to narrow each set of sources.
3. The middle double links those two pairs.

- direct: C2 establishes B2, D2 occupied.
- direct: C4 establishes C3, D4 occupied.

### 009 — STILL WATER

A lighter three-Post problem lets the player consolidate the rule before global reasoning.

Posts: 3; fogged clues: 12; directly established Posts: 3; hypothetical steps: 0.

QA solution: B2, D3, B4.

Whispers:
1. Follow the single marks from the left.
2. Clear glass removes competing sources.
3. The lower-right mark points upward.

- direct: A2 establishes B2 occupied.
- direct: C4 establishes B4 occupied.
- direct: D4 establishes D3 occupied.

### 010 — ONE LEFT

After two certainties, one Post must satisfy two single shadows: compare their source sets.

Posts: 3; fogged clues: 14; directly established Posts: 2; hypothetical steps: 0.

QA solution: E1, B3, C4.

Whispers:
1. Find the top and bottom certainties first.
2. Then one Post remains. Where must it go?
3. The two single marks must share that Post.

- direct: D1 establishes E1 occupied.
- direct: C5 establishes C4 occupied.
- subset: A3, COUNT establishes A1, C2, A3, C3, E5 empty.
- direct: C3 establishes B3 occupied.

### 011 — TWO LEFT

Two remaining Posts are reserved for a double shadow. Outside sources must be empty.

Posts: 4; fogged clues: 14; directly established Posts: 2; hypothetical steps: 0.

QA solution: B2, D2, B4, D4.

Whispers:
1. The upper double accounts for two Posts.
2. The lower double needs the two remaining.
3. No Posts remain for sources outside that set.

- direct: C2 establishes B2, D2 occupied.
- subset: C4, COUNT establishes B1, A3, D3, E3, E4, A5, C5, E5 empty.
- direct: A4 establishes B4 occupied.
- direct: E4 establishes D4 occupied.

### 012 — DIFFERENCE

Reuse the count idea in a sparser composition after resolving lower double shadows.

Posts: 4; fogged clues: 15; directly established Posts: 3; hypothetical steps: 0.

QA solution: E1, B3, C4, D5.

Whispers:
1. Resolve the two lower double shadows.
2. Then one Post is reserved for the top mark.
3. What can still cast into the right edge?

- direct: B4 establishes B3, C4 occupied.
- direct: C5 establishes D5 occupied.
- subset: D1, COUNT establishes A1, B2, D2, A3, C3, E3, B4, E4, A5 empty.
- direct: E2 establishes E1 occupied.

### 013 — FALSE SHADOW

Assume A2 empty after finding C1. This forces C2 and B3; only one Post remains, but D3 still needs two.

Posts: 4; fogged clues: 15; directly established Posts: 1; hypothetical steps: 1.

QA solution: C1, A2, C3, E3.

Whispers:
1. Settle the top Post before testing a theory.
2. Suppose this socket were empty.
3. Only one Post left, but this glass needs two.

- direct: B1 establishes C1 occupied.
- Test A2 empty; 3 propagation steps contradict D3. This forces it occupied.
- subset: D3, COUNT establishes E2, A3, A4, B4, D4, A5, B5, C5, D5, E5 empty.
- direct: B3 establishes C3 occupied.
- direct: E4 establishes E3 occupied.

### 014 — TWO DOORS

After the central pair, assume E3 empty. D4 would be occupied, leaving one Post for two disjoint source sets.

Posts: 4; fogged clues: 13; directly established Posts: 2; hypothetical steps: 1.

QA solution: C1, C2, D3, E3.

Whispers:
1. Begin with the central double.
2. Could this right-edge socket stay empty?
3. Then the top and middle still need two Posts.

- direct: C3 establishes C2, D3 occupied.
- Test E3 empty; 2 propagation steps contradict D3. This forces it occupied.
- subset: B1, COUNT establishes D1, E1, B2, A4, E5 empty.
- direct: D1 establishes C1 occupied.

### 015 — EXHALE

A breather: double-shadow deductions and one remaining-Post comparison, with no hypothesis needed.

Posts: 4; fogged clues: 13; directly established Posts: 3; hypothetical steps: 0.

QA solution: B1, C2, D3, B4.

Whispers:
1. The upper double is a familiar foothold.
2. Clear glass below narrows the right-hand mark.
3. The last Post must serve both lower marks.

- direct: B2 establishes B1, C2 occupied.
- direct: D4 establishes D3 occupied.
- subset: A4, COUNT establishes C1, E1, A5 empty.
- direct: B5 establishes B4 occupied.

### 016 — AFTERGLOW

Combine earlier certainties with a short C2-empty contradiction using two disjoint single-shadow demands.

Posts: 5; fogged clues: 13; directly established Posts: 3; hypothetical steps: 1.

QA solution: B2, C2, E3, B4, E4.

Whispers:
1. Find the left pair and the bottom-right Post.
2. Try leaving this upper socket empty.
3. One Post cannot reach both of these marks.

- direct: A2 establishes B2 occupied.
- direct: A4 establishes B4 occupied.
- direct: E5 establishes E4 occupied.
- Test C2 empty; 2 propagation steps contradict D3. This forces it occupied.
- subset: D3, COUNT establishes E1, A2, A4, D4, A5, C5, E5 empty.
- direct: E4 establishes E3 occupied.

### 017 — A SMALL DOUBT

Transfer that reasoning to the edge: D3 empty would leave one Post for disjoint demands.

Posts: 4; fogged clues: 14; directly established Posts: 2; hypothetical steps: 1.

QA solution: A1, D3, E3, C5.

Whispers:
1. Start with the top-left and right-hand marks.
2. Could the middle-right socket stay empty?
3. One Post cannot serve both distant marks.

- direct: B1 establishes A1 occupied.
- direct: E4 establishes E3 occupied.
- Test D3 empty; 2 propagation steps contradict B5. This forces it occupied.
- subset: B5, COUNT establishes D1, B3, A4, B5, D5, E5 empty.
- direct: D5 establishes C5 occupied.

### 018 — AFTERIMAGE

A three-Post finale. After C2, leaving C4 empty consumes both remaining Posts at the sides and leaves the bottom dark marks unexplained. Then share the final Post between the bottom pair.

Posts: 3; fogged clues: 16; directly established Posts: 1; hypothetical steps: 1.

QA solution: C2, C4, C5.

Whispers:
1. Find the certain Post above the middle mark.
2. If the middle gap stays empty, try both sides.
3. That uses every Post. The bottom still needs one.

- direct: C3 establishes C2 occupied.
- Test C4 empty; 3 propagation steps contradict B5. This forces it occupied.
- subset: B5, COUNT establishes A1, B1, C1, E1, B2, A3, D4, B5, D5, E5 empty.
- direct: D5 establishes C5 occupied.

## Hint and input polish

51 short authored whispers cover all stages except the dedicated notation lesson at 004. Hints highlight observations/source sets; hypothetical statements are signaled as such. No hint places a Post or reveals a hidden value. All are free. The Stage013 reasoning copy now states the valid remaining-count contradiction instead of an unsupported intermediate forced-empty chain.

Hint Tween references previously cleared without killing running Tweens. Reset/load/new hint/solve now kill them, and placement/drag cancels hint callbacks without refunding hint usage. A late whisper cannot overwrite input feedback. The final FINISH action thanks the player.

## Save compatibility

The grant demo uses `user://shadow_sum_grant18_progress_v1.json`; the older `shadow_sum_progress_v0_1.json` is left untouched. This is intentional: the same numeric IDs now name different puzzles, so old clears must not silently skip new content. Test/path overrides remain supported. The separate current-puzzle checkpoint inherits this path and its existing puzzle fingerprint validation.

## Reproducible checks

```text
python tools/validate_stages.py
python tools/validate_grant_campaign.py
python -m unittest discover -s tools -p test_stage_analysis.py
python tools/analyze_stages.py
bash tools/godot_checked.sh --headless --fixed-fps 120 --path . --script res://tools/grant_campaign_smoke.gd
```

Exhaustive validation enumerates every placement with the specified Post count, independently of the deduction analyzer. The editorial gate verifies intended rule bands, an initial Post foothold, a single non-nested contradiction of at most three propagation steps in the hypothesis puzzles, hint coordinates and visibility, and the actual contradiction behind every authored assumption. Godot independently verifies all 18 solutions, 51 whispers, clear progress, reveal/breath, full NEXT traversal, cancellation and 405/676/720 × 900 layouts. Existing smokes remain in CI.

## First-time playtest before submission

Use a fresh profile. Start with 5–8 people, including people who do not regularly play deduction games. Give no spoken explanation of the shadow rule. Ask for thinking aloud rather than coaching. Record:

- First placement and first solve: did they predict a shadow or randomly compare?
- Stage004: ask what fog means after the short lesson; do not supply the answer.
- Stage010/011: can they identify what the remaining Posts must serve?
- Stage013: can they explain why the assumption fails after using a hint?
- Stage018: can they explain the shared-source conclusion?
- Record mis-taps, hints used, stuck points, Undo/reset use, and voluntary NEXT presses.

Do not publish target completion times as measured results. If a player stalls, record the reason and the hint that helped. Use that evidence to tune clues rather than increasing hidden-cell counts. All participants should know the session is a playtest; no telemetry or data upload is added in this revision.

## Verification record

Local Godot 4.7 stable: all existing and new checked smokes pass. Actual OpenGL
playthroughs solved all 18 puzzles at all three sizes and produced screenshots
for visual review. Static validation loads all 33 resources without errors; 32
pre-existing style warnings remain (the new campaign smoke adds none). The
interaction smoke now stops its short audio tones before teardown to avoid
the previous intermittent ObjectDB exit warning.

## AI assistance record for the application

This revision used Codex to inspect the existing game, propose a teaching order,
search clue masks for selected Post arrangements with deterministic offline
scripts, review deduction traces, draft hint text and documentation, and
implement/test the associated code. It is not accurate to describe this revision
as entirely human-authored level design. The developer should review the actual
puzzles and adapt the application's AI-use answer to the complete project
history, including any tools used outside this session. No runtime generative AI,
generated 3D assets, or AI service dependency is added to the game.
