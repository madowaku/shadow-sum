# Jev second review for GR21-GR36

The generator and independent validator already prove exact uniqueness. Jev is used only as a second qualitative reviewer for likely human puzzle quality.

The pass reviews causal clarity, distinction from neighboring stages, deduction versus brute-force temptation, FOG fairness where relevant, and finale strength for GR36. Each selected stage is also compared with up to three nearby generated alternatives.

The runner is:

    tools/run_jev_second_review.py

Authentication uses the official TypeSafe environment variable. Never put the key in the repository.

PowerShell:

    $env:TYPESAFE_API_KEY="YOUR_KEY"

Optional:

    $env:JEV_MODEL="jev-latest"
    $env:JEV_ENDPOINT="https://api.typesafe.ai/v1/systemone"

Inspect the payload without calling Jev:

    python tools/run_jev_second_review.py --dry-run

Run the actual second review:

    python tools/run_jev_second_review.py

Outputs:

    generated/jev_second_review.json
    generated/jev_second_review.md

The script makes one Jev request per stage plus one global sequence request.

Per stage it asks an atomic Choice for the best candidate, Scores for causal clarity, sequence distinctness and deduction strength, and a Noul for whether the current selection should be kept. FOG stages add a fairness Score. GR36 adds a finale-strength Score.

The Markdown report softly flags a stage when Jev prefers an alternative, P(keep) is below 0.65, or a 0-4 quality Score is below 2.5. These are review flags, not automatic replacements.

The global pass asks for overall sequence quality, the probability that reselection is warranted before playtesting, and the weakest stage in the two-cause, three-cause, FOG and dense buckets.

Use Jev to decide which slots deserve human A/B playtesting. Do not let it replace the exact validator or automatically rewrite the draft.
