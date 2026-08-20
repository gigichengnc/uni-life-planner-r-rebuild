# From Words to Programs: R-Based Student Reflection Analytics

A retrospective reconstruction and redesign of a Year 1 course project from **STAT 2610SEF Data Analytics with Applications (2025 Spring)**.

The original project, **UNI LIFE PLANNER**, explored whether R-based text analytics could turn student reflections on university activities and competitions into useful signals about interests, emotions, and possible future activities.

This repository preserves the original attempt while rebuilding it as a more reproducible and statistically defensible R project. The rebuilt repository is **`uni-life-planner-r-rebuild`**.

The project now documents the complete learning path:

```text
Year 1 implementation
        ↓
problem diagnosis
        ↓
methodological redesign
        ↓
modular rebuild
        ↓
tests + interpretable outputs
        ↓
locked challenge benchmark
        ↓
failure analysis
        ↓
controlled baseline experiments
```

## Original question

Can student event reflections be processed in R to identify themes, sentiment, and possible activity recommendations?

## Original pipeline

```text
Student reflection text
        |
        v
Text preprocessing in R
        |
        v
Document-Term Matrix
        |
        v
LDA topic modelling + top terms
        |
        v
Manually named interest category
        |
        +--> Word cloud
        |
        +--> NRC sentiment analysis
        |
        v
Keyword matching against activity announcements
        |
        v
Suggested student activities
```

## Why rebuild it?

The Year 1 implementation contains several useful learning examples:

- hard-coded Windows file paths;
- an unsupervised LDA topic index treated as if it were a predefined category label;
- inconsistent descriptions of the number of categories/topics;
- LDA fitted separately to very small individual documents;
- human “matchness” judgments described as accuracy without a formal evaluation protocol;
- duplicated sentiment-analysis code;
- an undeclared `RColorBrewer` dependency despite calling `brewer.pal()`;
- broad regex activity matching against LDA top words;
- a monolithic script mixing setup, loading, modelling, visualisation, and recommendation logic;
- privacy/copyright risks if original student reflections are published directly.

These problems are documented in [`docs/known-problems.md`](docs/known-problems.md).

## Rebuilt architecture

```text
Reflection text
      |
      v
Data loading + preprocessing
      |
      +--> interest classification --> clear-fixture evaluation
      |
      +--> optional corpus-level LDA topic exploration
      |
      +--> NRC lexical sentiment description
      |
      v
Explainable activity recommendation
      |
      v
Interpretable visualisation
      |
      v
Locked synthetic challenge evaluation
      |
      v
Failure taxonomy + improvement queue
      |
      v
Controlled validation experiments
```

The analytical tasks remain separate. LDA topic numbers are not category labels, sentiment is not personality, and recommendation does not silently consume sentiment or topic indices.

## Repository structure

```text
.
├── README.md
├── .github/workflows/r-tests.yml
├── original/
│   ├── README.md
│   └── reconstructed_year1_code.R
├── docs/
│   ├── reconstruction-notes.md
│   ├── known-problems.md
│   ├── statistical-redesign.md
│   ├── classification-baseline.md
│   ├── topic-exploration.md
│   ├── sentiment-analysis.md
│   ├── recommendation-engine.md
│   ├── visualisation.md
│   ├── evaluation-challenge.md
│   ├── failure-analysis.md
│   └── controlled-experiments.md
├── data/
│   ├── README.md
│   ├── sample/
│   │   ├── activities.csv
│   │   ├── manifest.csv
│   │   └── reflections/
│   ├── evaluation/
│   │   ├── README.md
│   │   ├── labels.csv
│   │   └── reflections/
│   │       ├── eval_01.txt
│   │       ├── ...
│   │       └── eval_12.txt
│   └── private/
├── R/
│   ├── 01_load_data.R
│   ├── 02_preprocess.R
│   ├── 03_classify_interests.R
│   ├── 04_evaluate.R
│   ├── 05_explore_topics.R
│   ├── 06_sentiment.R
│   ├── 07_recommend_events.R
│   ├── 08_visualise.R
│   ├── 09_evaluate_challenge.R
│   ├── 10_analyse_failures.R
│   └── 11_controlled_experiments.R
├── scripts/
│   ├── render_sample_outputs.R
│   ├── run_challenge_evaluation.R
│   ├── run_failure_analysis.R
│   └── run_baseline_experiments.R
└── tests/
    ├── smoke_test_phase2.R
    ├── smoke_test_classification.R
    ├── smoke_test_topics.R
    ├── smoke_test_sentiment.R
    ├── smoke_test_recommendations.R
    ├── smoke_test_visualise.R
    ├── smoke_test_challenge.R
    ├── smoke_test_failure_analysis.R
    └── smoke_test_experiments.R
```

## Status

### Phase 1 — reconstructed and frozen

The historical R script was reconstructed from Appendix 1A of the submitted report and frozen as [`original/reconstructed_year1_code.R`](original/reconstructed_year1_code.R). PDF line wrapping was repaired, but the historical programming and methodological logic is intentionally preserved.

### Phase 2 — end-to-end reconstruction implemented

The corrected reconstruction includes project-relative loading, transparent preprocessing, a five-category dictionary classifier, explicit `ambiguous` / `unclassified` outcomes, corpus-level exploratory LDA, separate NRC sentiment description, explainable activity recommendation, base-R visualisation, smoke tests, and GitHub Actions automation.

The loading, preprocessing, classification, evaluation, recommendation, and visualisation modules use base R. Exploratory LDA adds the `topicmodels` dependency; NRC sentiment is isolated behind `syuzhet`.

### Phase 3 — locked synthetic challenge benchmark

Phase 3 adds benchmark version **`v1-locked-2026-08-20`** with 12 harder synthetic reflections covering paraphrase, negation/context, mixed-domain, off-domain, and surface-keyword-versus-purpose cases.

The benchmark is synthetic and deliberately probes known weaknesses. It is not an unbiased external test set, and its text/labels are treated as locked rather than rewritten to improve later scores. See [`docs/evaluation-challenge.md`](docs/evaluation-challenge.md).

### Phase 4 — failure analysis before model escalation

`R/10_analyse_failures.R` converts incorrect challenge decisions into a documented diagnostic taxonomy and investigation queue without changing the classifier or benchmark.

Diagnostic families include lexical coverage, negation/compositional language, semantic context, intent weighting, multi-label/abstention behaviour, calibration, and off-domain false positives. These diagnoses are structured hypotheses about error patterns, not proven causal explanations. See [`docs/failure-analysis.md`](docs/failure-analysis.md).

### Phase 5 — controlled validation experiments

Phase 5 tests the smallest justified interventions before considering a more complex model. It preserves `R/03_classify_interests.R` as the reference baseline and compares three pre-declared variants:

```text
A  current dictionary baseline
B  A + local three-token negation handling
C  B + minimum top score 2 + ambiguity margin 1
```

Variant A is checked against the existing classifier so the experiment cannot silently redefine the baseline. Variant B probes the `negation_blindness` hypothesis. Variant C probes whether weak evidence should abstain and whether near-tied mixed-domain evidence should be represented as ambiguous.

No threshold grid search is used. Benchmark labels are used only for evaluation, never prediction. The experiment reports case-level **improvements and regressions**, and no variant is automatically promoted based on validation accuracy alone.

Because the benchmark has already been inspected in Phase 4, Phase 5 explicitly treats it as **validation data**, not a fresh held-out test set. See [`docs/controlled-experiments.md`](docs/controlled-experiments.md).

A supervised/context-aware classifier remains deferred until there is enough independently labelled data to justify it.

## Evaluation warning

`data/sample/` contains deliberately easy synthetic fixtures. `data/evaluation/` is harder and locked, but it is still synthetic and was authored specifically for this project.

Neither dataset supports a claim of real-world classification accuracy. Repeated design decisions based on the challenge benchmark make it validation data. A genuine external performance claim requires a new independently labelled unseen test set from a broader population and a clearly documented labelling protocol.

## Run the checks

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

Optional analytical modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

CI installs these packages and uploads rendered figures plus Phase 3–5 CSV artifacts when available.

## Generate derived outputs

Portfolio figures:

```bash
Rscript scripts/render_sample_outputs.R
```

Challenge benchmark tables:

```bash
Rscript scripts/run_challenge_evaluation.R
```

Failure diagnosis and improvement queue:

```bash
Rscript scripts/run_failure_analysis.R
```

Controlled A/B/C experiment tables:

```bash
Rscript scripts/run_baseline_experiments.R
```

The Phase 5 runner writes:

```text
variant-settings.csv
variant-summary.csv
case-results.csv
by-challenge-type.csv
paired-comparison.csv
paired-summary.csv
```

Generated PNG/CSV outputs are ignored by Git so source history stays focused on code, fixtures, and documentation.

## Next decision gate

Phase 5 should answer whether either transparent intervention deserves to become a **candidate baseline**. The decision should consider validation improvement, regressions, interpretability, and whether the mechanism is likely to generalise—not only the highest score.

If a candidate is promoted later, the current baseline should remain reproducible, the change should be versioned explicitly, and a new unseen independently labelled test set should be created before making external performance claims.

## Historical note

This is a retrospective learning repository. The `original/` directory is frozen to show what was actually attempted at the end of Year 1; corrected code belongs separately under `R/` rather than silently replacing the historical version.
