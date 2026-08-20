# Phase 4 — Failure analysis before model escalation

Phase 4 asks a different question from Phase 3.

Phase 3 measures whether the locked synthetic challenge benchmark is handled correctly. Phase 4 asks **why** the current transparent baseline fails when it does.

The classifier and benchmark are intentionally left unchanged during this phase.

## What is locked

The benchmark version is:

```text
v1-locked-2026-08-20
```

The following are not changed in Phase 4:

- `data/evaluation/reflections/`;
- `data/evaluation/labels.csv`;
- `R/03_classify_interests.R`;
- classifier thresholds or category dictionaries.

Changing those while diagnosing the same benchmark would mix evaluation with tuning.

## Diagnostic flow

```text
locked challenge benchmark
        ↓
existing classifier
        ↓
Phase 3 decision evaluation
        ↓
correct cases + failures
        ↓
Phase 4 failure taxonomy
        ↓
priority + suggested investigation
        ↓
manual decision about the next modelling step
```

`R/10_analyse_failures.R` assigns each incorrect case one primary diagnostic label. The label is a **diagnostic hypothesis**, not proof of the true causal mechanism.

## Failure families

The taxonomy includes patterns such as:

- **abstention and scope** — off-domain text is still forced into a category;
- **lexical coverage** — relevant meaning is expressed with vocabulary outside the dictionary;
- **compositional language** — a keyword is counted even when local negation changes its meaning;
- **semantic context** — surface words point to one category while the reflection's main purpose belongs elsewhere;
- **intent weighting** — primary and secondary signals are treated too similarly;
- **multi-label and abstention** — mixed-domain cases are forced into one label or the wrong tied set;
- **calibration** — the score/margin rule produces too much or too little ambiguity;
- **baseline integrity** — a deliberately clean case fails and should be debugged before adding model complexity.

## Why there is an improvement queue

The analysis generates a queue ordered roughly by diagnostic priority. The queue is not an automatic patch list.

For example, a `negation_blindness` diagnosis may justify testing a transparent phrase/negation rule. A `paraphrase_coverage_gap` should not automatically trigger dictionary expansion from the locked case itself, because that would leak benchmark information into the model.

The safer sequence is:

```text
observe failure
    ↓
form hypothesis
    ↓
collect or define training/validation evidence separately
    ↓
change model/rule
    ↓
re-run locked benchmark
```

If the same benchmark is inspected repeatedly while designing changes, it gradually becomes validation data. A later external performance claim would therefore require a new unseen test set.

## Generated outputs

Run:

```bash
Rscript scripts/run_failure_analysis.R
```

The default output directory is `output/examples/failure-analysis/` and contains:

- `benchmark-summary.csv` — Phase 3 benchmark metrics;
- `case-diagnostics.csv` — every benchmark case plus diagnostic fields;
- `failure-register.csv` — incorrect cases only;
- `failure-modes.csv` — grouped failure modes, counts, cases, and suggested next steps;
- `failure-families.csv` — broader diagnostic families;
- `improvement-queue.csv` — prioritised investigation queue.

These are generated outputs and are ignored by Git. CI uploads them as artifacts when available.

## Interpretation limits

The challenge benchmark is synthetic and was authored for this reconstruction. The failure taxonomy is also rule-based and reflects the benchmark design. It is useful for disciplined debugging and portfolio documentation, but it is not an independently validated causal analysis of model errors.

The purpose of Phase 4 is therefore not to claim that a failure mode has been scientifically proven. It is to stop the project from jumping directly from a disappointing score to a more complex model without first understanding the observable error pattern.

## Decision gate after Phase 4

Only after reviewing the failure register should the project decide whether the next experiment should be:

1. a transparent preprocessing or phrase rule;
2. calibrated abstention or multi-label logic;
3. dictionary changes supported by separate evidence;
4. a supervised/context-aware classifier, but only if enough independently labelled data exists;
5. no model change because the current limitation is acceptable for the project's scope.

A more complicated model is not automatically an improvement unless it is evaluated against a suitable fixed benchmark and, eventually, genuinely unseen external data.
