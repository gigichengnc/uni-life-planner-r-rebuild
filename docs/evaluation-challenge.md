# Phase 3: locked synthetic challenge evaluation

Phase 2 proved that the rebuilt pipeline can execute on deliberately clear synthetic fixtures. That is useful for implementation testing, but it is not enough to support performance claims.

Phase 3 therefore adds a harder **locked synthetic challenge benchmark** under `data/evaluation/`.

## Why this is different from `data/sample/`

The original five sample reflections were intentionally category-distinct. They are good fixtures for checking that the implementation behaves as designed, but they are too easy to function as a meaningful stress test.

The challenge benchmark introduces cases that are more likely to expose weaknesses in a transparent bag-of-words dictionary baseline:

- paraphrases that use fewer exact dictionary terms;
- negation, where a keyword appears but the writer rejects that interpretation;
- mixed-domain reflections with two plausible categories;
- off-domain material that should remain unclassified;
- contexts where frequent surface keywords conflict with the intended semantic focus;
- cases where one domain supplies tools while another domain supplies the actual purpose.

## Locked benchmark policy

Version `v1-locked-2026-08-20` contains 12 synthetic reflections and their labels.

The benchmark was authored to probe known weaknesses of the baseline, so it is **not an unbiased external test set** and is not independently annotated. It must not be described as real-world accuracy evidence.

Once created, v1 is treated as locked. A later classifier may perform badly on some cases, but the texts and labels should not be rewritten merely to improve the score. If benchmark content genuinely needs correction, create a new documented version.

If repeated model changes are made after looking at v1 results, v1 has effectively become validation data. A new unseen dataset is then required for any fresh held-out claim.

## What is evaluated

The benchmark evaluates the whole classification decision, not only a category string.

For every reflection it checks:

1. whether the model should return `classified`, `ambiguous`, or `unclassified`;
2. whether the predicted theme matches the intended outcome;
3. whether the category or tied top categories match the expected category set.

The output includes:

- overall decision accuracy;
- single-label accuracy for cases expected to be classified;
- ambiguity-handling accuracy;
- unclassified-handling accuracy;
- model classification coverage;
- per-case failures;
- performance by challenge type.

These metrics are descriptive for this synthetic benchmark only.

## Running it

```bash
Rscript tests/smoke_test_challenge.R
Rscript scripts/run_challenge_evaluation.R
```

The runner writes `summary.csv`, `cases.csv`, `failures.csv`, and `by-challenge-type.csv` under `output/examples/challenge/` by default.

## What should happen next

Do **not** immediately expand the dictionary to memorise every failure. First inspect the failure types. Some failures may indicate limitations that a keyword dictionary cannot solve cleanly, such as negation, compositional meaning, or genuinely multi-label reflections.

Only after the failure analysis should the project decide whether to:

- refine transparent rules;
- support explicit multi-label classification;
- add phrase/negation handling;
- compare a supervised classifier on a larger labelled dataset;
- or keep the dictionary as an interpretable baseline and accept its limits.
