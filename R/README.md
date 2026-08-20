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

Evaluates the unchanged transparent classifier on `data/evaluation/`, benchmark version `v1-locked-2026-08-20`. It checks expected status, intended theme, expected top/tied categories, and results by challenge type. It intentionally does not require a perfect score.

See [`../docs/evaluation-challenge.md`](../docs/evaluation-challenge.md).

### `10_analyse_failures.R`

Adds Phase 4 diagnosis without changing the classifier or locked benchmark. It assigns incorrect cases a documented diagnostic hypothesis, groups failures into broader families, and creates an improvement queue without automatically changing model code.

See [`../docs/failure-analysis.md`](../docs/failure-analysis.md).

### `11_controlled_experiments.R`

Runs Phase 5 controlled validation experiments without replacing the baseline classifier.

Three pre-declared variants are compared:

```text
A  current dictionary baseline
B  A + local negation handling
C  B + min_top_score = 2 + ambiguity_margin = 1
```

Variant A is checked against `03_classify_interests.R` so the experiment cannot silently redefine the baseline. Variant B ignores dictionary terms that fall within a three-token local negation window after `not`, `no`, `never`, or `without`. Variant C additionally allows weak-evidence abstention and near-tie ambiguity.

The experiment produces paired before/after case comparisons, including improvements **and regressions**. It does not perform threshold search, does not consume benchmark labels during prediction, and never auto-promotes a variant.

Because the Phase 3 benchmark has already been inspected during failure analysis, Phase 5 explicitly treats it as **validation data**. See [`../docs/controlled-experiments.md`](../docs/controlled-experiments.md).

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
```

The Phase 3–5 tests verify benchmark loading, evaluation, diagnosis, experiment wiring, and reporting structure. They do **not** require a particular accuracy or require an experiment to beat the baseline.

Optional topic/sentiment modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

GitHub Actions installs those dependencies automatically.

## Generate derived outputs

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

Generated figures and CSV outputs remain ignored by Git and are uploaded as CI artifacts when available.

## Methodological rules

> **topic discovery is not category classification.**

> **sentiment description is not personality or interest classification.**

> **recommendation requires explicit classification evidence; weak evidence may produce no recommendation.**

> **visualisation displays existing outputs; it does not create new evidence.**

> **a benchmark is not held out anymore once you tune repeatedly against it.**

> **failure analysis should diagnose the baseline before changing it.**

> **an experimental variant is not promoted merely because its validation score is higher.**
