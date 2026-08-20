# Phase 5 — Controlled Baseline Experiments

Phase 5 asks a narrower question than “which model is best?”:

> Do small, transparent interventions fix specific failure modes without creating new errors?

The experiment keeps the Phase 3 benchmark unchanged and compares three pre-declared variants. Because the benchmark has already been inspected during Phase 4, it is treated as **validation data**, not as a fresh held-out test set.

## Variants

### Variant A — current dictionary baseline

This is the unchanged Phase 2 classifier. It uses the existing category dictionary, counts matching evidence, marks exact top-score ties as `ambiguous`, and returns `unclassified` only when no category receives evidence.

Its role is to anchor every comparison to the implementation already documented in `R/03_classify_interests.R`.

### Variant B — local negation handling

Variant B keeps the same dictionary and decision thresholds but ignores a category term when one of these negators occurs within the preceding three preprocessed tokens:

```text
not
no
never
without
```

The rule is deliberately small and inspectable. It is intended to probe the Phase 4 `negation_blindness` hypothesis.

This is not full linguistic negation modelling. It does not understand clause boundaries, “not only … but also …”, irony, scope ambiguity, or long-distance dependencies. A regression is therefore possible and should be reported rather than hidden.

### Variant C — negation + calibrated ambiguity / abstention

Variant C uses Variant B scoring, then applies two pre-declared decision rules:

```text
minimum top score = 2
ambiguity margin = 1
```

A document with fewer than two supporting dictionary terms becomes `unclassified`. If two or more positive-scoring categories are within one point of the top score, the result becomes `ambiguous` and the candidate category set is retained explicitly.

The aim is to probe two Phase 4 hypotheses:

- weak evidence should sometimes produce abstention rather than a forced category;
- near-tied mixed-domain evidence may deserve an explicit ambiguous / multi-category decision.

These settings are intentionally simple. Phase 5 does **not** perform a grid search or choose thresholds automatically from the benchmark score.

## What is deliberately not implemented

A context-aware supervised classifier is deferred. The current public data are too small and synthetic to support a serious supervised-model comparison or external performance claim.

Adding a more complex model before obtaining independently labelled data would create the appearance of sophistication without a defensible evaluation design.

## Evaluation protocol

Every variant is evaluated against the same locked benchmark using the full decision:

```text
status
  +
predicted theme
  +
predicted category set
```

The output includes:

- decision accuracy by variant;
- classification / ambiguity / abstention counts;
- results by challenge type;
- paired case-level comparison against Variant A;
- improvements;
- regressions;
- unchanged-correct cases;
- unchanged-wrong cases;
- net change in correct decisions.

A variant is **not** automatically promoted because it obtains the highest validation score. A useful change should also have an interpretable mechanism, limited regressions, and a reason to expect the behaviour to generalise beyond these 12 authored cases.

## Leakage warning

The benchmark is locked in content, but it is no longer statistically held out once model changes are designed while looking at its failures.

Accordingly:

- Phase 5 results are validation results;
- benchmark text and labels must remain unchanged;
- threshold sweeps should not be used to manufacture a better score;
- repeatedly optimising against this benchmark increases overfitting risk;
- any later external accuracy claim requires a new independently labelled unseen test set.

## Reproduce the experiment

```bash
Rscript scripts/run_baseline_experiments.R
```

The script writes derived CSV tables under `output/examples/experiments/` by default. Those outputs are ignored by Git and can also be collected from GitHub Actions artifacts.
