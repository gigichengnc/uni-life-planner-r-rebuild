# Corrected implementation

The corrected implementation lives here and remains separate from `../original/`.

## Implemented modules

```text
01_load_data.R
02_preprocess.R
03_classify_interests.R
04_evaluate.R
05_explore_topics.R
06_sentiment.R
07_recommend_events.R
08_visualise.R
09_evaluate_challenge.R
10_analyse_failures.R
11_controlled_experiments.R
12_validate_external_labels.R
```

### `01_load_data.R`

Replaces hard-coded Windows paths with project-relative loading. It supports both the clear Phase 2 sample fixtures and the locked Phase 3 challenge benchmark.

### `02_preprocess.R`

Provides transparent base-R cleaning, tokenisation, stopword removal, term counts, and a document-term matrix.

### `03_classify_interests.R`

Implements the transparent five-category dictionary baseline. It reports per-category scores, matched terms, top/runner-up scores, margins, and explicit `ambiguous` / `unclassified` outcomes.

### `04_evaluate.R`

Evaluates the classifier on deliberately clear synthetic sample fixtures. This is primarily an implementation check, not a real-world performance claim.

### `05_explore_topics.R`

Keeps LDA as optional corpus-level exploratory topic discovery only. Topic numbers are never converted directly into predefined interest categories.

### `06_sentiment.R`

Keeps NRC sentiment as a separate lexical description with raw counts and length-normalised rates. It is not used as personality inference or category evidence.

### `07_recommend_events.R`

Ranks activities using explicit classification evidence and activity features, with thresholds and a `no_recommendation` outcome when evidence is weak. Sentiment and LDA topic numbers are excluded from ranking.

### `08_visualise.R`

Renders interpretable PNG outputs for classification evidence, topic terms, sentiment rates, and recommendation rankings without adding new modelling logic.

### `09_evaluate_challenge.R`

Evaluates the unchanged transparent classifier on `data/evaluation/`, benchmark version `v1-locked-2026-08-20`. It intentionally does not require a perfect score.

### `10_analyse_failures.R`

Adds Phase 4 diagnosis without changing the classifier or locked benchmark. It assigns incorrect cases a documented diagnostic hypothesis and creates an investigation queue.

### `11_controlled_experiments.R`

Runs Phase 5 controlled validation experiments. Variants A/B/C compare the current baseline, local negation handling, and pre-declared ambiguity/abstention thresholds without automatically replacing the reference baseline.

The model-decision review retains Variant A because B produces no paired improvement and C produces one improvement plus one regression on the validation benchmark.

### `12_validate_external_labels.R`

Adds Phase 6 validation utilities for a future independently labelled unseen evaluation set.

It validates:

- external-test registry structure and `first_seen_after_model_freeze` flags;
- at least two independent first-round annotators per reflection;
- `classified`, `ambiguous`, and `unclassified` label coherence;
- primary and secondary category sets;
- confidence values and written rationales;
- `labelled_without_model_output = TRUE`;
- frozen adjudicated labels;
- exact first-round agreement and an adjudication queue;
- matching reflection IDs across registry, annotations, and final labels.

The validator checks recorded process consistency only. It cannot prove that data were truly unseen, that annotators were independent, or that publication rights exist. See [`../docs/external-evaluation-protocol.md`](../docs/external-evaluation-protocol.md).

## Quick checks

```bash
Rscript tests/smoke_test_phase2.R
Rscript tests/smoke_test_classification.R
Rscript tests/smoke_test_topics.R
Rscript tests/smoke_test_sentiment.R
Rscript tests/smoke_test_recommendations.R
Rscript tests/smoke_test_visualise.R
Rscript tests/smoke_test_challenge.R
Rscript tests/smoke_test_failure_analysis.R
Rscript tests/smoke_test_experiments.R
Rscript tests/smoke_test_external_labels.R
```

The Phase 3–6 tests verify benchmark loading, evaluation, diagnosis, experiment wiring, and labelling-protocol validation. They do **not** establish external accuracy.

Optional topic/sentiment modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

GitHub Actions installs those dependencies automatically.

## Generate or validate derived outputs

Sample figures:

```bash
Rscript scripts/render_sample_outputs.R
```

Challenge benchmark tables:

```bash
Rscript scripts/run_challenge_evaluation.R
```

Failure register and improvement queue:

```bash
Rscript scripts/run_failure_analysis.R
```

Controlled experiment tables:

```bash
Rscript scripts/run_baseline_experiments.R
```

When a real external dataset exists locally, validate its registry, independent annotations, and frozen adjudicated labels with:

```bash
Rscript scripts/validate_external_evaluation.R \
  data/external-evaluation/private/dataset-register.csv \
  data/external-evaluation/private/annotations.csv \
  data/external-evaluation/private/adjudicated-labels.csv
```

## Methodological rules

> **topic discovery is not category classification.**

> **sentiment description is not personality or interest classification.**

> **recommendation requires explicit classification evidence; weak evidence may produce no recommendation.**

> **a benchmark is not held out anymore once you tune repeatedly against it.**

> **failure analysis should diagnose the baseline before changing it.**

> **an experimental variant is not promoted merely because its validation score is higher.**

> **external labels must be created before annotators see model predictions and frozen before evaluation.**
