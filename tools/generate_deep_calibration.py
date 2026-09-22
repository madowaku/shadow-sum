"""Reproduce a review-only GR21-GR36 pool, selection, and independent validation.

Run: python tools/generate_deep_calibration.py
Requires NumPy; the independent exhaustive validator uses only the standard library.
"""
from __future__ import annotations

import argparse
import csv
import gc
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
import time
from collections import Counter

import numpy as np

from deep_calibration_model import (
    ALL_CELLS, LIGHTS, Profile, StateIndex, cell, code, greedy_witness, mask_for,
    profiles, rays, world_key,
)

ROOT = Path(__file__).resolve().parents[1]
QUOTAS = {"two": 8, "three": 10, "fog": 10, "dense": 20, "finale": 24}
SELECT = {"two": 4, "three": 4, "fog": 4, "dense": 3, "finale": 1}
TITLES = ["CROSSED REACH", "A QUIET AXIS", "LOCAL DARKNESS", "TWO EXPLANATIONS",
          "THREE THREADS", "THE MISSING CAUSE", "INTERLOCK", "CLOSE THE TRIANGLE",
          "BEYOND THE VEIL", "PARTIAL CROSS", "UNSEEN BUT KNOWN", "READ THE REMAINDER",
          "FOUR VOICES", "DENSE AGREEMENT", "THE LAST ALTERNATIVE", "DEEP CALIBRATION"]
SCORING = {
    "distributed_evidence": "1.8 * min(greedy witness cells, 10) + 0.4 * (witness rows + columns)",
    "causal_ambiguity": "1.2 * log2(1 + distance<=2 states); no state-space-size reward",
    "overlap_quality": "0.8 * min(overlap cells, 3) + 1.0 * overlap dependency",
    "negative_evidence_quality": "1.2 * zero dependency + 1.2 * plate absence dependency",
    "mechanic_interaction": "1.5 * intersecting object-footprint pairs + 0.7 * resolved uncertain families",
    "symmetry_penalty": "-3 if the full target is left/right symmetric",
    "edge_abuse_penalty": "-0.8 * off-board rays - 20 * max(0, off-board fraction - 0.15)",
    "trivial_witness_penalty": "-3 * max(0, 4 - greedy witness cells)",
    "long_witness_penalty": "-1.5 * max(0, greedy witness cells - 10); FOG additionally capped at 10 cells",
    "near_duplicate_penalty": "hard rejection: translated/reflected world, or <=2 common-visible differences within profile",
    "diversity_bonus": "selection only: +4 new family combination, +3 new reasoning signature, +2 changed first deduction",
    "selection_similarity_penalty": "-2 per previous selection of this physical profile",
}


def json_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def objects_of(world):
    return [(cell(o["cell"]), o["type"]) for o in world["objects"]]


def evidence_label(c, shadow, facts):
    if shadow[c] == 0:
        return "PLATE_ABSENCE" if c in facts["absence"] else "ZERO"
    if shadow[c] >= 2:
        return "OVERLAP"
    if c in facts["far"]:
        return "REACH"
    if c in facts["absence"]:
        return "PLATE_ABSENCE"
    return "SHADOW"


def describe_trace(index, masks, visible, shadow, facts):
    raw = greedy_witness(masks, visible)
    trace, signature = [], []
    unresolved = (["LIGHT"] if index.profile.light_count else []) + (
        ["SHUTTER"] if index.profile.shutter else []) + (
        ["ORIENTATION"] if index.profile.plate else []) + (["TYPE"] if index.profile.tall else [])
    for c, count, survivors in raw:
        label = evidence_label(c, shadow, facts)
        resolved = [f for f in unresolved if len(index.family_values(survivors, f)) == 1]
        for f in resolved:
            unresolved.remove(f)
        trace.append({"cell": code(c), "value": int(shadow[c]), "survivors": count,
                      "evidence": label, "resolves": resolved})
        for token in [label, *resolved]:
            if token not in signature:
                signature.append(token)
    return trace, " -> ".join(signature)


def metrics(index, world_id, shadow, facts, masks, visible):
    world = index.world(world_id)
    visible_mask = mask_for(visible)
    differences = masks & visible_mask
    assert np.count_nonzero(differences == 0) == 1
    distance = np.bitwise_count(differences)
    trace, signature = describe_trace(index, masks, visible, shadow, facts)

    def ablate(cells, family=None):
        removed = mask_for(set(cells) & set(visible))
        survivors = np.flatnonzero((differences & (ALL_CELLS ^ removed)) == 0)
        return {"removed_cells": [code(c) for c in visible if removed & (1 << c)],
                "survivors": len(survivors),
                "depends": bool(len(survivors) > 1 and (
                    family is None or len(index.family_values(survivors, family)) > 1))}

    light_cells, shutter_cells = set(), set()
    for lights, shutter in index.configs:
        if shutter == world["shutter"] and list(lights) != world["lights"]:
            alternative = rays(objects_of(world), lights, shutter)[0]
            light_cells.update(c for c in visible if alternative[c] != shadow[c])
        if list(lights) == world["lights"] and shutter != world["shutter"]:
            alternative = rays(objects_of(world), lights, shutter)[0]
            shutter_cells.update(c for c in visible if alternative[c] != shadow[c])
    dependence = {
        "zero": ablate([c for c in visible if shadow[c] == 0]),
        "overlap": ablate([c for c in visible if shadow[c] >= 2]),
        "tall_reach": ablate(facts["far"], "TYPE"),
        "plate_directional_absence": ablate(facts["absence"], "ORIENTATION"),
        "light_choice": ablate(light_cells, "LIGHT"),
        "shutter_choice": ablate(shutter_cells, "SHUTTER"),
    }
    # Keep actual legal near-miss worlds; prefer differing settings/material placements.
    near = []
    identities = set()
    for dist in range(1, 26):
        for candidate_id in np.flatnonzero(distance == dist)[:256]:
            if len(near) == 4:
                break
            other = index.world(candidate_id)
            identity = (tuple(other["lights"]), other["shutter"],
                        tuple(o["type"] + o["cell"] for o in other["objects"] if o["type"] != "normal"))
            if identity in identities and len(near) >= 2:
                continue
            identities.add(identity)
            other_shadow = index.shadows[candidate_id]
            near.append({"world": other, "visible_hamming_distance": dist,
                         "rejected_by": [{"cell": code(c), "target": int(shadow[c]),
                                          "actual": int(other_shadow[c])}
                                         for c in visible if shadow[c] != other_shadow[c]]})
        if len(near) == 4:
            break
    result = {
        "mechanic_families": index.profile.families,
        "object_counts": {"normal": index.profile.normal, "tall": index.profile.tall, "plate": index.profile.plate},
        "object_count": sum((index.profile.normal, index.profile.tall, index.profile.plate)),
        "active_light_uncertainty": len({lights for lights, _ in index.configs}),
        "shutter_uncertainty": 5 if index.profile.shutter else 1,
        "plate_orientation_uncertainty": 2 ** index.profile.plate,
        "fog_count": 25 - len(visible),
        "nonzero_target_cells": sum(shadow[c] > 0 for c in visible),
        "zero_target_cells": sum(shadow[c] == 0 for c in visible),
        "max_shadow_intensity": max(shadow[c] for c in visible),
        "overlap_cell_count": sum(shadow[c] >= 2 for c in visible),
        "tall_far_cell_count": len(set(visible) & facts["far"]),
        "edge_offboard_contributions": facts["offboard"],
        "offboard_fraction": round(facts["offboard"] / max(1, facts["attempts"]), 5),
        "interaction_edges": facts["interaction_edges"],
        "legal_world_states": index.profile.states,
        "states_hamming_1": int(np.count_nonzero(distance == 1)),
        "states_hamming_le_2": int(np.count_nonzero((distance > 0) & (distance <= 2))),
        "greedy_witness_count": len(trace),
        "witness_trace": trace,
        "dependency_tests": dependence,
        "has_two_to_four_state_step": any(2 <= step["survivors"] <= 4 for step in trace),
    }
    return result, signature, near


def score_candidate(m, shadow):
    trace = m["witness_trace"]
    rows = {cell(t["cell"]) // 5 for t in trace}
    cols = {cell(t["cell"]) % 5 for t in trace}
    dep = m["dependency_tests"]
    components = {
        "distributed_evidence": 1.8 * min(len(trace), 10) + .4 * (len(rows) + len(cols)),
        "causal_ambiguity": 1.2 * math.log2(1 + m["states_hamming_le_2"]),
        "overlap_quality": .8 * min(m["overlap_cell_count"], 3) + dep["overlap"]["depends"],
        "negative_evidence_quality": 1.2 * (dep["zero"]["depends"] + dep["plate_directional_absence"]["depends"]),
        "mechanic_interaction": 1.5 * m["interaction_edges"] + .7 * sum(len(t["resolves"]) for t in trace),
        "symmetry_penalty": -3.0 if shadow == [shadow[(c // 5) * 5 + 4 - c % 5] for c in range(25)] else 0.0,
        "edge_abuse_penalty": -.8 * m["edge_offboard_contributions"] - 20 * max(0, m["offboard_fraction"] - .15),
        "trivial_witness_penalty": -3 * max(0, 4 - len(trace)),
        "long_witness_penalty": -1.5 * max(0, len(trace) - 10),
        "near_duplicate_penalty": 0.0,
    }
    components = {k: round(float(v), 4) for k, v in components.items()}
    return {"total": round(sum(components.values()), 4), "components": components}


def close_target(candidate, prior):
    # Compare visible evidence in either horizontal orientation for identical constraints.
    for other in prior:
        keys = ("normal", "tall", "plate", "light_count", "shutter", "fixed_lights")
        if any(candidate["profile"][key] != other["profile"][key] for key in keys):
            continue
        a, b = candidate["complete_shadow"], other["complete_shadow"]
        av, bv = candidate["visible_mask"], other["visible_mask"]
        for mirror in (False, True):
            mapping = [5 * (c // 5) + 4 - c % 5 if mirror else c for c in range(25)]
            common = [c for c in range(25) if av[c] and bv[mapping[c]]]
            if sum(a[c] != b[mapping[c]] for c in common) <= 2:
                return True
    return False


def fog_mask(index, masks, shadow, rng):
    baseline = greedy_witness(masks, list(range(25)))
    first = baseline[0][0]
    # Remove a demonstrated best shortcut, never merely random blank cells.
    for attempt in range(24):
        count = 3 + attempt % 4
        rest = [c for c in range(25) if c != first]
        fog = sorted([first, *map(int, rng.choice(rest, count - 1, replace=False))])
        if not any(shadow[c] > 0 for c in fog):
            continue
        visible = [c for c in range(25) if c not in fog]
        if np.count_nonzero((masks & mask_for(visible)) == 0) != 1:
            continue
        trace = greedy_witness(masks, visible)
        if len(trace) >= len(baseline) and trace[0][1] > baseline[0][1]:
            return visible, {"hidden_shortcut": code(first), "full_witness_count": len(baseline),
                             "full_first_clue_survivors": baseline[0][1],
                             "visible_first_clue_survivors": trace[0][1],
                             "hidden_nonzero_cells": [code(c) for c in fog if shadow[c] > 0]}
    return None, None


def sample_pool(index, profile, quota, rng, used, prior):
    accepted, considered, expensive = [], 0, 0
    rejected = Counter()
    for world_id in rng.permutation(index.unique_ids):
        considered += 1
        world = index.world(world_id)
        key = world_key(world)
        if key in used:
            rejected["translated_or_reflected_world"] += 1
            continue
        shadow, facts = rays(objects_of(world), world["lights"], world["shutter"])
        if (not 6 <= sum(v > 0 for v in shadow) <= 17 or not any(v >= 2 for v in shadow)
                or facts["offboard"] / max(1, facts["attempts"]) > .25
                or any(not footprint for footprint in facts["footprints"])
                or (profile.tall and not facts["far"])):
            rejected["physical_quality"] += 1
            continue
        masks = index.difference_masks(shadow)
        expensive += 1
        visible, fog_evidence = list(range(25)), None
        if profile.bucket == "fog":
            visible, fog_evidence = fog_mask(index, masks, shadow, rng)
            if visible is None:
                rejected["fog_shortcut_or_uniqueness"] += 1
                continue
        m, reasoning, near = metrics(index, world_id, shadow, facts, masks, visible)
        if m["greedy_witness_count"] < 4 or len(near) < 2:
            rejected["short_witness"] += 1
            continue
        if profile.bucket == "fog" and m["greedy_witness_count"] > 10:
            rejected["fog_excessive_witness"] += 1
            continue
        if profile.bucket in ("three", "fog", "dense", "finale") and not m["has_two_to_four_state_step"]:
            rejected["no_small_ambiguity_step"] += 1
            continue
        candidate = {"id": f"{profile.name}-{len(accepted) + 1:03}", "profile": profile.record(),
                     "world_id": int(world_id), "solution": world, "complete_shadow": shadow,
                     "visible_mask": [c in visible for c in range(25)],
                     "fog_cells": [code(c) for c in range(25) if c not in visible],
                     "unique_solution_count": 1, "metrics": m, "reasoning_signature": reasoning,
                     "score": score_candidate(m, shadow), "near_miss_worlds": near}
        if fog_evidence:
            candidate["fog_shortcut_evidence"] = fog_evidence
        if close_target(candidate, [*prior, *accepted]):
            rejected["near_duplicate_target"] += 1
            continue
        accepted.append(candidate)
        used.add(key)
        if len(accepted) == quota:
            break
    if len(accepted) != quota:
        raise RuntimeError(f"{profile.name}: only {len(accepted)}/{quota} candidates; {rejected}")
    return accepted, {"sampled_unique_worlds": considered, "fully_scored_worlds": expensive,
                      "rejected": dict(rejected), "retained_candidates": len(accepted)}


def physical_key(profile):
    return (profile.normal, profile.tall, profile.plate, profile.light_count, profile.shutter, profile.fixed_lights)


def deeper_than_baseline(candidate, baseline):
    m, b = candidate["metrics"], baseline["metrics"]
    return (m["greedy_witness_count"] > b["greedy_witness_count"]
            and m["states_hamming_le_2"] > b["states_hamming_le_2"]
            and m["overlap_cell_count"] >= b["overlap_cell_count"]
            and m["edge_offboard_contributions"] <= b["edge_offboard_contributions"]
            and m["has_two_to_four_state_step"])


def select(pool, baseline):
    selected, decisions = [], []
    for bucket, count in SELECT.items():
        remaining = [c for c in pool if c["profile"]["bucket"] == bucket]
        for _ in range(count):
            scored = []
            for c in remaining:
                if bucket == "finale" and not deeper_than_baseline(c, baseline):
                    continue
                combo = tuple(c["profile"]["families"])
                sig = c["reasoning_signature"]
                if selected and (combo, sig) == (tuple(selected[-1]["profile"]["families"]), selected[-1]["reasoning_signature"]):
                    continue
                novelty = (4 * all(combo != tuple(s["profile"]["families"]) for s in selected)
                           + 3 * all(sig != s["reasoning_signature"] for s in selected)
                           + 2 * bool(selected and sig.split(" -> ")[0] != selected[-1]["reasoning_signature"].split(" -> ")[0]))
                similarity = -2 * sum(c["profile"]["name"] == s["profile"]["name"] for s in selected)
                scored.append((round(c["score"]["total"] + novelty + similarity, 4), c["id"], novelty, similarity, c))
            if not scored:
                raise RuntimeError(f"No eligible selection for {bucket}; inspect pool/baseline")
            scored.sort(key=lambda entry: (-entry[0], entry[1]))
            winner = scored[0]
            selected.append(winner[4])
            decisions.append({"candidate_id": winner[1], "selection_score": winner[0],
                              "diversity_bonus": winner[2], "selection_similarity_penalty": winner[3],
                              "eligible_count": len(scored),
                              "nearby_alternatives": [{"id": e[1], "selection_score": e[0], "base_score": e[4]["score"]["total"],
                                                        "diversity_bonus": e[2], "similarity_penalty": e[3],
                                                        "reasoning_signature": e[4]["reasoning_signature"]} for e in scored[1:4]]})
            remaining = [c for c in remaining if c["id"] != winner[1]]
    # Keep the diversity selection history, then order each campaign bucket by
    # close-competitor ambiguity. This avoids simply shipping descending scores.
    for round_number, decision in enumerate(decisions, 1):
        decision["selection_round"] = round_number
    ordered, ordered_decisions = [], []
    for bucket in SELECT:
        pending = [(c, d) for c, d in zip(selected, decisions) if c["profile"]["bucket"] == bucket]
        pending.sort(key=lambda pair: (pair[0]["metrics"]["states_hamming_le_2"],
                                       pair[0]["metrics"]["greedy_witness_count"], pair[0]["id"]))
        while pending:
            eligible = [i for i, (c, _) in enumerate(pending) if not ordered or
                        (c["profile"]["families"], c["reasoning_signature"]) !=
                        (ordered[-1]["profile"]["families"], ordered[-1]["reasoning_signature"])]
            if not eligible:
                raise RuntimeError("Cannot order selected bucket without a repeated adjacent signature")
            c, decision = pending.pop(eligible[0])
            ordered.append(c)
            ordered_decisions.append(decision)
    return ordered, ordered_decisions


def stage_from(candidate, number):
    p, world = candidate["profile"], candidate["solution"]
    titles = {
        "two_height_light": "CROSSED REACH", "two_plate_light": "WHICH AXIS IS LIT",
        "two_shutter_light": "LOCAL OR GLOBAL", "two_height_plate": "LONG AND NARROW",
        "two_height_shutter": "BLOCKED REACH", "two_plate_shutter": "THE SILENT CROSS",
        "three_height_light_shutter": "THE MISSING LONG SHADOW",
        "three_height_plate_light": "TURN TOWARD THE LIGHT",
        "three_height_plate_shutter": "BEYOND THE BLOCKED AXIS",
        "three_plate_light_shutter": "THREE KINDS OF ABSENCE",
    }
    stage = {"id": f"GR{number}", "title": titles.get(p["name"], TITLES[number - 21]), "posts": sum(p[k] for k in ("normal", "tall", "plate")),
             "normal_posts": p["normal"], "tall_posts": p["tall"], "plate_posts": p["plate"],
             "installed_lights": list(LIGHTS) if p["light_count"] else p["fixed_lights"],
             "solution": [o["cell"] for o in world["objects"]],
             "solution_post_types": {o["cell"]: o["type"] for o in world["objects"]},
             "observations": [{"id": "A", "active_lights": [] if p["light_count"] else p["fixed_lights"],
                               "target": {code(c): v for c, v in enumerate(candidate["complete_shadow"])
                                          if candidate["visible_mask"][c]}}],
             "expected_states": p["expected_states"], "expected_solutions": 1,
             "generator_candidate_id": candidate["id"], "generator_profile": p,
             "reasoning_signature": candidate["reasoning_signature"],
             "solution_complete_shadow": candidate["complete_shadow"], "review_only": True}
    if p["tall"]:
        stage["solution_tall"] = [o["cell"] for o in world["objects"] if o["type"] == "tall"]
    if p["plate"]:
        stage["rotatable_plate"] = True
    if p["light_count"]:
        stage.update(free_light_selection=True, active_light_count=p["light_count"], initial_lights=[], solution_lights=world["lights"])
    if p["shutter"]:
        stage.update(movable_shutter=True, solution_shutter=world["shutter"])
    if candidate["fog_cells"]:
        stage["fog_cells"] = candidate["fog_cells"]
    return stage


def readable_world(world):
    return (", ".join(o["cell"] + ":" + o["type"] for o in world["objects"]) +
            "; lights=" + "+".join(world["lights"]) + "; shutter=" + ("none" if world["shutter"] is None else chr(65 + world["shutter"])))


def render_report(pool_data, selected, decisions, validation, stages):
    lines = ["# GR21–GR36 selection for human review", "", "Review-only selection. Opt-in Godot playtest: `--campaign grant36-draft`; see `docs/GRANT36_PLAYTEST.md`. Default startup remains GRANT20.", "",
             f"Seed: `{pool_data['seed']}`. Retained exact-unique, deduplicated candidates: **{len(pool_data['candidates'])}**.",
             f"Bucket counts: `{json.dumps(pool_data['bucket_counts'])}`. Independent exhaustive validation: **16/16 passed**.",
             f"Generation: **{pool_data['generation_seconds']:.3f}s**; independent validation: **{validation['total_seconds']:.3f}s**; "
             f"pipeline: **{pool_data['pipeline_seconds']:.3f}s**.", "",
             "These are reproducible search proxies, not a claim of measured human difficulty. Greedy witnesses are sufficient, not proven minimal; their evidence labels use the authored solution. Read the concrete eliminations below and playtest before integration.", "",
             "## Reproduce", "", "```text", "python tools/generate_deep_calibration.py", "python tools/validate_grant36_draft.py", "```", "",
             "## Scoring and selection", ""]
    lines += [f"- **{k}**: {v}." for k, v in SCORING.items()]
    lines += ["", "All two/three-cause candidates have 3 objects; dense/finale have 4. Object position is a baseline variable, not an extra mechanic family. All positions are unrestricted and identical objects are unlabelled.", "",
              "Quality gates: 6–17 nonzero cells before fog, at least one overlap, every object visible, <=25% lost rays, >=4 greedy witness cells; three/fog/dense/finale must include a 2–4-world intermediate deduction. FOG hides the strongest full-board first clue, increases first-step ambiguity, and retains exact uniqueness with 19–22 observed cells and at most 10 witness cells. Long witnesses lose score rather than earning unlimited difficulty credit.", "",
              "Deduplication rejects translated or reflected solutions across the whole pool (including GR14–GR20 seeds), and targets differing in <=2 common observed cells within identical physical constraints (also across full/fog buckets), including reflection. Reflection here is an equivalence check, never a game mechanic.", "",
              "Selection greedily maximizes the printed base + novelty - similarity score within fixed bucket quotas; equal scores use candidate ID. Adjacency cannot repeat family + reasoning signature. After selection, stages within each bucket are ordered by increasing distance<=2 competitors, retaining the adjacency constraint. Selection-round numbers preserve the original scoring history. This is not a guaranteed monotonic human difficulty curve.", "",
              "## Profile census", "", "| Profile | Legal worlds | Distinct full targets | Exact-unique full targets (peak) | Sampled | Scored | Retained | Seconds |", "|---|---:|---:|---:|---:|---:|---:|---:|"]
    for p in pool_data["profile_stats"]:
        lines.append(f"| {p['name']} | {p['legal_states']:,} | {p['signature_count']:,} | {p['full_unique_count']:,} | {p['sampled_unique_worlds']} | {p['fully_scored_worlds']} | {p['retained_candidates']} | {p['seconds']:.3f} |")
    lines += ["", "Repeated physical profiles reuse the in-memory reverse index; fog projection is checked against every world, including worlds with nonunique full targets. Per-profile time includes index construction only for its first use.", "",
              "## GR36 compared with GR20", "", "| Measure | GR20 | GR36 |", "|---|---:|---:|"]
    base, final = pool_data["gr20_baseline"]["metrics"], selected[-1]["metrics"]
    for key in ["object_count", "legal_world_states", "greedy_witness_count", "states_hamming_1", "states_hamming_le_2", "overlap_cell_count", "edge_offboard_contributions"]:
        lines.append(f"| {key} | {base[key]} | {final[key]} |")
    lines += ["", "The preferred finale profile succeeded: Normal ×2 + Tall ×1 + rotatable Plate ×1, exactly three lamps, one movable TOP shutter, fully visible. The selection gate requires more witness cells and distance<=2 competitors than GR20, at least as many overlaps, no additional off-board rays, and a 2–4-world intermediate step. This demonstrates deeper competing explanations by those explicit proxies; human readability remains a review judgment.", "",
              "GR20 greedy trace: " + " → ".join(f"{t['cell']}={t['value']} ({t['survivors']:,} remain)" for t in base["witness_trace"]), "",
              "## Selected stages", "", "| Stage | Candidate | Families | Reasoning | Witness | d≤2 | Score |", "|---|---|---|---|---:|---:|---:|"]
    for s, c in zip(stages, selected):
        lines.append(f"| {s['id']} | {c['id']} | {' + '.join(c['profile']['families'])} | {c['reasoning_signature']} | {c['metrics']['greedy_witness_count']} | {c['metrics']['states_hamming_le_2']} | {c['score']['total']:.4f} |")
    for i, (stage, c, decision, validated) in enumerate(zip(stages, selected, decisions, validation["stages"])):
        m = c["metrics"]
        lines += ["", f"## {stage['id']} — {stage['title']}", "", f"Candidate: `{c['id']}`. Mechanics: **{' + '.join(c['profile']['families'])}**.", "",
                  "Solution: " + readable_world(c["solution"]) + ".", "",
                  f"Legal states: **{m['legal_world_states']:,}**; exact survivors: **{validated['solution_count']}**; independent enumeration: {validated['seconds']:.3f}s.", "",
                  "FOG: " + (", ".join(c["fog_cells"]) if c["fog_cells"] else "none") + ". `?` is unobserved, never zero.", "", "```text", "    A B C D E"]
        for row in range(5):
            lines.append(f"{row+1}   " + " ".join(str(c["complete_shadow"][5*row+col]) if c["visible_mask"][5*row+col] else "?" for col in range(5)))
        lines += ["```", "", f"Reasoning signature: **{c['reasoning_signature']}**", "", "| Evidence | Kind | Worlds remaining | Newly resolved assignment |", "|---|---|---:|---|"]
        for step in m["witness_trace"]:
            lines.append(f"| {step['cell']} = {step['value']} | {step['evidence']} | {step['survivors']:,} | {', '.join(step['resolves']) or '—'} |")
        lines += ["", "Evidence ablation (remove the entire named cell group, retain all other visible cells):", "", "| Group | Removed cells | Survivors | Depends on group |", "|---|---|---:|---|"]
        for name, dep in m["dependency_tests"].items():
            lines.append(f"| {name} | {', '.join(dep['removed_cells']) or '—'} | {dep['survivors']:,} | {dep['depends']} |")
        if "fog_shortcut_evidence" in c:
            f = c["fog_shortcut_evidence"]
            lines += ["", f"FOG removes the full-board best first clue `{f['hidden_shortcut']}`. Best first-clue survivors rise from {f['full_first_clue_survivors']:,} to {f['visible_first_clue_survivors']:,}; witness cells {f['full_witness_count']} → {m['greedy_witness_count']}. Hidden nonzero cells: {', '.join(f['hidden_nonzero_cells'])}."]
        lines += ["", "Score components:", ""]
        lines += [f"- {k}: {v:+.4f}" for k, v in c["score"]["components"].items()]
        lines += [f"- Base: {c['score']['total']:.4f}; diversity: {decision['diversity_bonus']:+}; profile repetition: {decision['selection_similarity_penalty']:+}; selection total: **{decision['selection_score']:.4f}**.", "",
                  f"Selection round {decision['selection_round']}: won among {decision['eligible_count']} eligible remaining candidates. Nearby alternatives at this decision:", ""]
        for alt in decision["nearby_alternatives"]:
            lines.append(f"- `{alt['id']}`: base {alt['base_score']:.4f} + diversity {alt['diversity_bonus']} + repetition ({alt['similarity_penalty']}) = {alt['selection_score']:.4f}; `{alt['reasoning_signature']}`. Winner margin {decision['selection_score'] - alt['selection_score']:.4f}.")
        lines += ["", "Neighbor comparison:", ""]
        for neighbor in [n for n in (i-1, i+1) if 0 <= n < len(selected)]:
            other = selected[neighbor]
            lines.append(f"- GR{21+neighbor}: {' + '.join(other['profile']['families'])}; `{other['reasoning_signature']}`; witness {other['metrics']['greedy_witness_count']} vs {m['greedy_witness_count']}, fog {len(other['fog_cells'])} vs {len(c['fog_cells'])}, overlaps {other['metrics']['overlap_cell_count']} vs {m['overlap_cell_count']}.")
        lines += ["", "Plausible legal near misses and ALL rejecting visible evidence:", ""]
        for near in c["near_miss_worlds"]:
            rejection = "; ".join(f"{e['cell']}: expected {e['target']}, gets {e['actual']}" for e in near["rejected_by"])
            lines.append(f"- {readable_world(near['world'])}. Distance {near['visible_hamming_distance']}. Rejected by **{rejection}**.")
    lines += ["", "## Review / integration boundary", "", "The generator preserves parsed GR01–GR20 objects exactly. The review-only draft can now be tested through the explicit `grant36-draft` mode or `scenes/grant36_draft.tscn`, with isolated progress. Its matcher skips explicit fog cells and its target display marks them with `?`. Default startup remains GRANT20; see `docs/GRANT36_PLAYTEST.md` for runtime checks.", "",
              "Review the evidence chains, especially whether the authored-solution labels translate into discoverable deductions. The sequence has no repeated adjacent mechanic+reasoning signature, but its automatic scores are not playtest timings. See `docs/GRANT36_GENERATION.md` for metric definitions, dependencies, and validation boundaries.", ""]
    return "\n".join(lines)


def baseline_record(stage):
    p = Profile("gr20_baseline", "baseline", 1, 1, 1, 3, True)
    index = StateIndex(p)
    world = {"objects": [{"cell": name, "type": kind} for name, kind in stage["solution_post_types"].items()],
             "lights": stage["solution_lights"], "shutter": stage["solution_shutter"]}
    shadow, facts = rays(objects_of(world), world["lights"], world["shutter"])
    masks = index.difference_masks(shadow)
    ids = np.flatnonzero(masks == 0)
    assert len(ids) == 1
    m, reasoning, _ = metrics(index, ids[0], shadow, facts, masks, list(range(25)))
    return {"solution": world, "metrics": m, "reasoning_signature": reasoning}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=20260922)
    parser.add_argument("--output-root", type=Path, default=ROOT)
    args = parser.parse_args()
    start = time.perf_counter()
    source = ROOT / "data/grant20_v0_3.json"
    old = json.loads(source.read_text(encoding="utf-8"))
    baseline = baseline_record(old[-1])
    print(f"GR20: witness={baseline['metrics']['greedy_witness_count']}, d<=2={baseline['metrics']['states_hamming_le_2']}", flush=True)
    used = set()
    for stage in old[13:]:
        used.add(world_key({"objects": [{"cell": name, "type": stage.get("solution_post_types", {}).get(name, "normal")} for name in stage["solution"]],
                            "lights": stage.get("solution_lights", stage["observations"][0]["active_lights"]), "shutter": stage.get("solution_shutter")}))
    groups = {}
    for number, p in enumerate(profiles()):
        groups.setdefault(physical_key(p), []).append((number, p))
    pool, stats = [], []
    for group in groups.values():
        index_start = time.perf_counter()
        index = StateIndex(group[0][1])
        construction = time.perf_counter() - index_start
        for number, p in group:
            profile_start = time.perf_counter()
            index.profile = p  # Identical physical constraints; only the bucket/name differs.
            candidates, stat = sample_pool(index, p, QUOTAS[p.bucket], np.random.default_rng(args.seed + number), used, pool)
            pool.extend(candidates)
            stat.update(name=p.name, legal_states=p.states, signature_count=index.signature_count,
                        full_unique_count=index.full_unique_count, seconds=round(time.perf_counter() - profile_start + construction, 3))
            stats.append(stat)
            construction = 0
            print(f"{p.name}: {p.states:,} worlds, {index.full_unique_count:,} full unique, {len(candidates)} retained, {stat['seconds']:.3f}s", flush=True)
        del index
        gc.collect()
    for c in pool:
        c["seed"] = args.seed
    selected, decisions = select(pool, baseline)
    stages = [stage_from(c, number) for number, c in enumerate(selected, 21)]
    output = args.output_root.resolve()
    draft = output / "data/grant36_v0_4_draft.json"
    json_write(draft, old + stages)
    selected_ids = {c["id"]: f"GR{i}" for i, c in enumerate(selected, 21)}
    ranked = output / "generated/grant36_ranked.csv"
    ranked.parent.mkdir(parents=True, exist_ok=True)
    with ranked.open("w", encoding="utf-8", newline="") as handle:
        fields = ["rank", "candidate", "selected", "bucket", "families", "reasoning_signature", "score", "states", "witness", "hamming_1", "hamming_le_2", "fog", "overlaps", "edge_rays", "zero_depends", "reach_depends", "plate_depends"] + list(pool[0]["score"]["components"])
        writer = csv.DictWriter(handle, fields)
        writer.writeheader()
        for rank, c in enumerate(sorted(pool, key=lambda x: (-x["score"]["total"], x["id"])), 1):
            m = c["metrics"]
            writer.writerow(dict(rank=rank, candidate=c["id"], selected=selected_ids.get(c["id"], ""), bucket=c["profile"]["bucket"],
                                 families="+".join(c["profile"]["families"]), reasoning_signature=c["reasoning_signature"], score=c["score"]["total"],
                                 states=m["legal_world_states"], witness=m["greedy_witness_count"], hamming_1=m["states_hamming_1"], hamming_le_2=m["states_hamming_le_2"],
                                 fog=m["fog_count"], overlaps=m["overlap_cell_count"], edge_rays=m["edge_offboard_contributions"],
                                 zero_depends=m["dependency_tests"]["zero"]["depends"], reach_depends=m["dependency_tests"]["tall_reach"]["depends"],
                                 plate_depends=m["dependency_tests"]["plate_directional_absence"]["depends"], **c["score"]["components"]))
    pool_data = {"schema_version": 1, "seed": args.seed,
                 "run_environment": {"python": sys.version.split()[0], "numpy": np.__version__, "platform": sys.platform},
                 "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                 "bucket_counts": dict(Counter(c["profile"]["bucket"] for c in pool)), "profile_stats": stats,
                 "scoring": SCORING, "gr20_baseline": baseline, "selection": decisions, "candidates": pool,
                 "generation_seconds": round(time.perf_counter() - start, 3)}
    candidates_path = output / "generated/grant36_candidates.json"
    json_write(candidates_path, pool_data)
    validation_path = output / "generated/grant36_validation.json"
    subprocess.run([sys.executable, str(ROOT / "tools/validate_grant36_draft.py"), "--draft", str(draft),
                    "--pool", str(candidates_path), "--report", str(validation_path)], check=True)
    validation = json.loads(validation_path.read_text(encoding="utf-8"))
    pool_data["pipeline_seconds"] = round(time.perf_counter() - start, 3)
    json_write(candidates_path, pool_data)
    report = render_report(pool_data, selected, decisions, validation, stages)
    (output / "generated/grant36_selection_report.md").write_text(report, encoding="utf-8")
    print(f"DONE: {len(pool)} candidates, 16 selected and independently validated; {pool_data['pipeline_seconds']:.3f}s", flush=True)


if __name__ == "__main__":
    main()
