#!/usr/bin/env python3
"""Qualitative Jev second review for GR21-GR36.

Exact uniqueness is already established elsewhere. This runner asks Jev only
about likely human puzzle quality and sequence fit.
"""
from __future__ import annotations

import argparse
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POOL = ROOT / "generated/grant36_candidates.json"
DRAFT = ROOT / "data/grant36_v0_4_draft.json"
OUT_JSON = ROOT / "generated/jev_second_review.json"
OUT_MD = ROOT / "generated/jev_second_review.md"
ENDPOINT = "https://api.typesafe.ai/v1/systemone"

LEVELS = {
    "clarity": [
        "Opaque; players are likely to poke controls without a causal hypothesis.",
        "Some readable clues, but the main solve path is muddled.",
        "A workable causal path exists, though experimentation may lead it.",
        "Mostly readable and supports deliberate hypothesis testing.",
        "A clean, satisfying chain of causal deductions is strongly supported.",
    ],
    "distinct": [
        "Substantially redundant with neighboring stages.",
        "Mostly cosmetic variation.",
        "Some distinct reasoning but much shared solve texture.",
        "Clearly different solve texture from adjacent stages.",
        "Strongly distinctive use of already-known rules.",
    ],
    "deduction": [
        "Trial-and-error is likely to dominate.",
        "Brute-force temptation is high.",
        "Deduction and experimentation are both plausible.",
        "Deduction is clearly favored.",
        "Strong specific deductions can be made before acting.",
    ],
    "fog": [
        "FOG mainly withholds information and feels arbitrary.",
        "FOG creates more friction than inference.",
        "FOG is acceptable but not especially meaningful.",
        "FOG removes a shortcut while keeping a fair logical path.",
        "FOG meaningfully deepens inference and feels intentional.",
    ],
    "finale": [
        "Not finale-worthy.",
        "Larger but not meaningfully more culminating.",
        "A competent final exercise.",
        "A strong culmination with readable structure.",
        "A true final calibration: deep, coherent, demanding, satisfying.",
    ],
}


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def normalized_pool(raw):
    return raw if isinstance(raw, dict) else {"candidates": raw, "selection": []}


def grid(candidate):
    shadow = candidate.get("complete_shadow", [0] * 25)
    visible = candidate.get("visible_mask", [True] * 25)
    return [
        " ".join(str(shadow[r * 5 + c]) if visible[r * 5 + c] else "?" for c in range(5))
        for r in range(5)
    ]


def deps(metrics):
    tests = metrics.get("dependency_tests", {})
    return {
        name: bool(tests.get(name, {}).get("depends", False))
        for name in (
            "zero", "overlap", "tall_reach", "plate_directional_absence",
            "light_choice", "shutter_choice"
        )
    }


def card(candidate):
    m = candidate.get("metrics", {})
    p = candidate.get("profile", {})
    return {
        "id": candidate["id"],
        "families": p.get("families", []),
        "reasoning_signature": candidate.get("reasoning_signature", ""),
        "visible_target_grid": grid(candidate),
        "fog_cells": candidate.get("fog_cells", []),
        "witness_cells": m.get("greedy_witness_count"),
        "hamming_1_competitors": m.get("states_hamming_1"),
        "hamming_le_2_competitors": m.get("states_hamming_le_2"),
        "overlap_cells": m.get("overlap_cell_count"),
        "offboard_rays": m.get("edge_offboard_contributions"),
        "dependencies": deps(m),
        "generator_score": candidate.get("score", {}).get("total"),
    }


def selected_ids(draft):
    return {
        s["id"]: s["generator_candidate_id"]
        for s in draft
        if isinstance(s, dict) and s.get("generator_candidate_id")
    }


def decisions_by_winner(pool):
    out = {}
    for decision in pool.get("selection", []):
        cid = decision.get("candidate_id")
        if cid:
            out[cid] = decision
    return out


def fallback_alts(winner, candidates):
    bucket = winner.get("profile", {}).get("bucket")
    families = tuple(winner.get("profile", {}).get("families", []))
    choices = [
        c for c in candidates
        if c["id"] != winner["id"] and c.get("profile", {}).get("bucket") == bucket
    ]
    choices.sort(key=lambda c: (
        tuple(c.get("profile", {}).get("families", [])) != families,
        -float(c.get("score", {}).get("total", 0.0)),
        c["id"],
    ))
    return [c["id"] for c in choices[:3]]


def alt_ids(winner, decisions, candidates):
    ids = []
    for item in decisions.get(winner["id"], {}).get("alternatives", []):
        cid = item.get("candidate_id") or item.get("id")
        if cid and cid not in ids:
            ids.append(cid)
    for cid in fallback_alts(winner, candidates):
        if cid not in ids:
            ids.append(cid)
        if len(ids) == 3:
            break
    return ids[:3]


def compact(stage, candidate):
    c = card(candidate)
    return {
        "stage": stage,
        "candidate": candidate["id"],
        "families": c["families"],
        "reasoning_signature": c["reasoning_signature"],
        "witness": c["witness_cells"],
        "d_le_2": c["hamming_le_2_competitors"],
        "fog": len(c["fog_cells"]),
        "overlaps": c["overlap_cells"],
    }


def questions(stage, winner, alternatives):
    options = {}
    for c in [winner, *alternatives]:
        x = card(c)
        options[c["id"]] = (
            "families=" + "+".join(x["families"]) +
            "; reasoning=" + x["reasoning_signature"] +
            f"; witness={x['witness_cells']}; d<=2={x['hamming_le_2_competitors']}" +
            f"; fog={len(x['fog_cells'])}; overlaps={x['overlap_cells']}"
        )

    prefix = (
        f"For slot {stage}, judge the CURRENT SELECTED candidate in the state. "
        "All shown candidates are mathematically valid and exact-unique. "
        "Judge human puzzle quality, not correctness."
    )
    q = {
        "best_candidate": {
            "type": "choice",
            "instructions": (
                f"For slot {stage}, which shown candidate best fits the sequence? "
                "Prioritize distinctive causal deduction relative to neighbors, readable evidence, "
                "satisfying inference, and low temptation to sweep controls by trial-and-error."
            ),
            "criteria": options,
        },
        "causal_clarity": {
            "type": "score",
            "instructions": prefix + " How clear and causally legible is the likely solve path?",
            "criteria": LEVELS["clarity"],
        },
        "sequence_distinctness": {
            "type": "score",
            "instructions": prefix + " How distinct is its solve texture from immediate neighbors?",
            "criteria": LEVELS["distinct"],
        },
        "deduction_strength": {
            "type": "score",
            "instructions": prefix + " How strongly does it reward deduction over blind experimentation?",
            "criteria": LEVELS["deduction"],
        },
        "keep_selected": {
            "type": "noul",
            "instructions": (
                f"For slot {stage}, should the current selected candidate be kept rather than replaced "
                "by one of the shown comparison candidates, based on human puzzle quality and sequence fit?"
            ),
            "criteria": {
                "true": "Keep the current selected candidate.",
                "false": "A shown comparison candidate is materially better.",
            },
        },
    }
    bucket = winner.get("profile", {}).get("bucket")
    if bucket == "fog":
        q["fog_fairness"] = {
            "type": "score",
            "instructions": prefix + " Does FOG remove a shortcut while preserving meaningful fair inference?",
            "criteria": LEVELS["fog"],
        }
    if bucket == "finale":
        q["finale_strength"] = {
            "type": "score",
            "instructions": prefix + " How strongly does it work as the final calibration after GR21-GR35?",
            "criteria": LEVELS["finale"],
        }
    return q


def call_jev(endpoint, key, model, state, questions):
    payload = json.dumps(
        {"model": model, "state": state, "questions": questions},
        ensure_ascii=False,
    ).encode("utf-8")
    req = urllib.request.Request(
        endpoint,
        data=payload,
        headers={
            "Authorization": "Bearer " + key,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    last = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                body = json.loads(response.read().decode("utf-8"))
            answers = body.get("answers")
            if answers is None and isinstance(body.get("result"), dict):
                answers = body["result"].get("answers")
            if not isinstance(answers, dict):
                raise RuntimeError("Jev response did not contain an answers map")
            return body, answers
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as exc:
            last = exc
            if attempt < 2:
                time.sleep(1.5 * (attempt + 1))
    raise last


def answer(answers, name, field):
    value = answers.get(name, {})
    return value.get(field) if isinstance(value, dict) else None


def score(answers, name):
    value = answer(answers, name, "score")
    return None if value is None else float(value)


def noul(answers, name):
    value = answer(answers, name, "noul")
    if value is None:
        value = answer(answers, name, "probability")
    return None if value is None else float(value)


def global_questions(stage_ids):
    groups = {
        "weakest_two_cause": [s for s in stage_ids if 21 <= int(s[2:]) <= 24],
        "weakest_three_cause": [s for s in stage_ids if 25 <= int(s[2:]) <= 28],
        "weakest_fog": [s for s in stage_ids if 29 <= int(s[2:]) <= 32],
        "weakest_dense": [s for s in stage_ids if 33 <= int(s[2:]) <= 35],
    }
    q = {
        "sequence_quality": {
            "type": "score",
            "instructions": (
                "Judge GR21-GR36 as a human puzzle sequence. Are solve textures varied, "
                "difficulty plausibly progressive, and evidence chains causally legible?"
            ),
            "criteria": [
                "Major reselection needed.",
                "Several stages are redundant or trial-and-error heavy.",
                "Workable but targeted replacements are likely needed.",
                "Strong; only minor playtest adjustments are likely.",
                "Exceptionally coherent, varied, and ready for direct playtesting.",
            ],
        },
        "needs_reselection": {
            "type": "noul",
            "instructions": (
                "Before Godot playtesting, is there strong evidence in these summaries that one or more "
                "selected stages should be replaced now for redundancy, weak causal readability, or poor sequence fit?"
            ),
            "criteria": {
                "true": "At least one replacement is strongly justified now.",
                "false": "Keep all sixteen for human playtesting first.",
            },
        },
    }
    for qid, ids in groups.items():
        q[qid] = {
            "type": "choice",
            "instructions": "Which listed stage is the weakest fit in this bucket and deserves the closest human scrutiny?",
            "criteria": {sid: "Review " + sid + " as the weakest current fit." for sid in ids},
        }
    return q


def render_md(result):
    lines = [
        "# Jev second review: GR21-GR36",
        "",
        "Jev is a qualitative reviewer only. Exact uniqueness remains the validator's job.",
        "",
        "| Stage | Selected | Jev choice | Keep P | Clarity | Distinct | Deduction | FOG | Finale | Flags |",
        "|---|---|---|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in result["stages"]:
        a = row["answers"]
        selected = row["selected_candidate"]
        best = answer(a, "best_candidate", "choice") or "?"
        keep = noul(a, "keep_selected")
        clarity = score(a, "causal_clarity")
        distinct = score(a, "sequence_distinctness")
        deduction = score(a, "deduction_strength")
        fog = score(a, "fog_fairness")
        finale = score(a, "finale_strength")
        flags = []
        if best != selected:
            flags.append("ALT")
        if keep is not None and keep < 0.65:
            flags.append("KEEP<.65")
        for label, value in (("CLARITY", clarity), ("DISTINCT", distinct), ("DEDUCT", deduction)):
            if value is not None and value < 2.5:
                flags.append(label)
        if fog is not None and fog < 2.5:
            flags.append("FOG")
        if finale is not None and finale < 2.5:
            flags.append("FINALE")
        fmt = lambda v: "" if v is None else f"{v:.2f}"
        lines.append(
            f"| {row['stage']} | {selected} | {best} | {fmt(keep)} | {fmt(clarity)} | "
            f"{fmt(distinct)} | {fmt(deduction)} | {fmt(fog)} | {fmt(finale)} | {', '.join(flags)} |"
        )

    g = result.get("global_answers", {})
    lines += ["", "## Global pass", ""]
    sq = score(g, "sequence_quality")
    nr = noul(g, "needs_reselection")
    lines.append("- Sequence quality: " + ("?" if sq is None else f"{sq:.2f} / 4"))
    lines.append("- P(reselection before playtest): " + ("?" if nr is None else f"{nr:.3f}"))
    for name in ("weakest_two_cause", "weakest_three_cause", "weakest_fog", "weakest_dense"):
        lines.append("- " + name + ": " + str(answer(g, name, "choice") or "?"))
    lines += [
        "",
        "ALT and low-score flags are prompts for human review, never automatic replacements.",
        "",
    ]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pool", type=Path, default=POOL)
    ap.add_argument("--draft", type=Path, default=DRAFT)
    ap.add_argument("--json-out", type=Path, default=OUT_JSON)
    ap.add_argument("--md-out", type=Path, default=OUT_MD)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    pool = normalized_pool(read_json(args.pool))
    draft = read_json(args.draft)
    candidates = pool["candidates"]
    by_id = {c["id"]: c for c in candidates}
    selected = selected_ids(draft)
    stage_ids = sorted(
        [s for s in selected if 21 <= int(s[2:]) <= 36],
        key=lambda s: int(s[2:]),
    )
    if len(stage_ids) != 16:
        raise RuntimeError("Expected GR21-GR36 in draft")
    decisions = decisions_by_winner(pool)

    endpoint = os.environ.get("JEV_ENDPOINT", ENDPOINT)
    model = os.environ.get("JEV_MODEL", "jev-latest")
    key = os.environ.get("TYPESAFE_API_KEY")
    if not args.dry_run and not key:
        raise SystemExit("Set TYPESAFE_API_KEY in the environment. Never commit the key.")

    rows = []
    for pos, sid in enumerate(stage_ids):
        winner = by_id[selected[sid]]
        ids = alt_ids(winner, decisions, candidates)
        alternatives = [by_id[x] for x in ids if x in by_id]
        prev_card = compact(stage_ids[pos - 1], by_id[selected[stage_ids[pos - 1]]]) if pos else None
        next_card = compact(stage_ids[pos + 1], by_id[selected[stage_ids[pos + 1]]]) if pos + 1 < len(stage_ids) else None
        state = {
            "review_contract": (
                "All shown candidates are exact-unique and validated. Do not judge correctness. "
                "Judge likely human puzzle quality only."
            ),
            "slot": sid,
            "previous_selected_stage": prev_card,
            "next_selected_stage": next_card,
            "current_selected_candidate": card(winner),
            "comparison_candidates": [card(c) for c in alternatives],
        }
        qs = questions(sid, winner, alternatives)
        row = {
            "stage": sid,
            "selected_candidate": winner["id"],
            "alternatives": ids,
        }
        if args.dry_run:
            row["state"] = state
            row["questions"] = qs
        else:
            raw, answers = call_jev(endpoint, key, model, state, qs)
            row["answers"] = answers
            row["raw_response"] = raw
            print(sid + ": reviewed", flush=True)
        rows.append(row)

    global_answers = {}
    global_raw = None
    if not args.dry_run:
        global_state = {
            "review_contract": "All stages are exact-unique. Judge human-facing sequence quality only.",
            "selected_sequence": [compact(sid, by_id[selected[sid]]) for sid in stage_ids],
        }
        global_raw, global_answers = call_jev(
            endpoint, key, model, global_state, global_questions(stage_ids)
        )

    result = {
        "schema_version": 1,
        "model": model,
        "endpoint": endpoint,
        "scope": "qualitative_second_review_only",
        "stages": rows,
        "global_answers": global_answers,
        "global_raw_response": global_raw,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if not args.dry_run:
        args.md_out.write_text(render_md(result), encoding="utf-8")
        print("Wrote " + str(args.md_out))
    print("Wrote " + str(args.json_out))


if __name__ == "__main__":
    main()
