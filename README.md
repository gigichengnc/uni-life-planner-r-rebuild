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
        ↓
model decision review
        ↓
external-evaluation protocol
```

## Original question

Can student event reflections be processed in R to identify themes, sentiment, and possible activity recommendations?

## Why rebuild it?

The Year 1 implementation contains several useful learning examples:

- hard-coded Windows file paths;
- an unsupervised LDA topic index treated as if it were a predefined category label;
- inconsistent descriptions of the number of categories/topics;
- LDA fitted separately to very small individual documents;
- human "matchness" judgments described as accuracy without a formal evaluation protocol;
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
      |
      v
Model decision review
      |
      v
Independent-labelling + unseen-test protocol
```

The analytical tasks remain separate. LDA topic numbers are not category labels, sentiment is not personality, and recommendation does not silently consume sentiment or topic indices.

## Repository structure

```text
.
├── README.md
├── .github/workflows/r-tests.yml
├── original/
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
│   ├── controlled-experiments.md
│   ├── model-decision-review.md
│   └── external-evaluation-protocol.md
├── data/
│   ├── sample/
│   ├── evaluation/
│   ├── external-evaluation/
│   │   ├── README.md
│   │   ├── dataset-register-template.csv
│   │   ├── annotations-template.csv
│   │   ├── adjudicated-labels-template.csv
│   │   └── private/
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
│   ├── 11_controlled_experiments.R
│   └── 12_validate_external_labels.R
├── scripts/
│   ├── render_sample_outputs.R
│   ├── run_challenge_evaluation.R
│   ├── run_failure_analysis.R
│   ├── run_baseline_experiments.R
│   └── validate_external_evaluation.R
└── tests/
    ├── smoke_test_phase2.R
    ├── smoke_test_classification.R
    ├── smoke_test_topics.R
    ├── smoke_test_sentiment.R
    ├── smoke_test_recommendations.R
    ├── smoke_test_visualise.R
    ├── smoke_test_challenge.R
    ├── smoke_test_failure_analysis.R
    ├── smoke_test_experiments.R
    └── smoke_test_external_labels.R
```

## Status

### Phase 1 — reconstructed and frozen

The historical R script was reconstructed from Appendix 1A of the submitted report and frozen under `original/`. PDF line wrapping was repaired, but the historical programming and methodological logic is intentionally preserved.

### Phase 2 — end-to-end reconstruction implemented

The corrected reconstruction includes project-relative loading, transparent preprocessing, a five-category dictionary classifier, explicit `ambiguous` / `unclassified` outcomes, corpus-level exploratory LDA, separate NRC sentiment description, explainable activity recommendation, base-R visualisation, smoke tests, and GitHub Actions automation.

### Phase 3 — locked synthetic challenge benchmark

Benchmark version **`v1-locked-2026-08-20`** adds 12 harder synthetic reflections covering paraphrase, negation/context, mixed-domain, off-domain, and surface-keyword-versus-purpose cases.

It is synthetic and challenge-oriented, not an unbiased external test set.

### Phase 4 — failure analysis

`R/10_analyse_failures.R` converts incorrect challenge decisions into a documented diagnostic taxonomy and investigation queue without changing the classifier or benchmark.

### Phase 5 — controlled validation experiments

Three pre-declared variants were compared:

```text
A  current dictionary baseline
B  A + local three-token negation handling
C  B + minimum top score 2 + ambiguity margin 1
```

The model-decision review retains **Variant A**. Deterministic reproduction from repository definitions gives A = **8/12**, B = **8/12**, and C = **8/12** correct validation decisions. B changes no decisions; C fixes one case and regresses one case. These are validation results on authored synthetic cases, not external accuracy claims. See [`docs/model-decision-review.md`](docs/model-decision-review.md).

### Phase 6 — independent labelling and external-test protocol

Phase 6 deliberately does **not** invent another synthetic "external" test set.

Instead it defines the process required before the project can make a fresh performance claim:

- at least two independent first-round annotators per reflection;
- annotators do not see model predictions, scores, dictionary terms, or failure diagnoses;
- `classified`, `ambiguous`, and `unclassified` are all valid outcomes;
- primary and secondary category evidence is recorded explicitly;
- confidence and short rationales are preserved;
- exact first-round agreement is measured;
- disagreements enter an adjudication queue rather than being silently overwritten;
- final adjudicated labels are versioned and frozen before model evaluation;
- a dataset registry records whether each case was first seen after model freeze;
- real external reflection text and annotation exports remain private by default.

Public schema files live under `data/external-evaluation/`; real material belongs in the git-ignored `data/external-evaluation/private/` directory. See [`docs/external-evaluation-protocol.md`](docs/external-evaluation-protocol.md).

`R/12_validate_external_labels.R` checks schema/process consistency and can build an adjudication queue. It cannot prove that the data were genuinely unseen or that annotators were truly independent; those remain governance requirements that must be documented honestly.

## Evaluation warning

`data/sample/` contains deliberately easy synthetic fixtures. `data/evaluation/` is harder and locked but was still authored specifically for this project and has already been used for model development.

Neither dataset supports a claim of real-world classification accuracy.

A genuine external performance claim requires a new independently labelled unseen test set collected and frozen under the Phase 6 protocol.

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
Rscript tests/smoke_test_external_labels.R
```

Optional analytical modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

## Useful commands

Render sample portfolio figures:

```bash
Rscript scripts/render_sample_outputs.R
```

Run challenge/failure/experiment reports:

```bash
Rscript scripts/run_challenge_evaluation.R
Rscript scripts/run_failure_analysis.R
Rscript scripts/run_baseline_experiments.R
```

When a real external-evaluation bundle exists locally:

```bash
Rscript scripts/validate_external_evaluation.R \
  data/external-evaluation/private/dataset-register.csv \
  data/external-evaluation/private/annotations.csv \
  data/external-evaluation/private/adjudicated-labels.csv
```

## Next evidence gate

The project should now stop tuning against the 12 authored validation cases.

The next substantive work is **data collection and independent labelling**, not another benchmark-specific code rule. Once a new external set is frozen, compare the retained A baseline against any future phrase-aware or context-aware candidate exactly once for the external claim.

## Historical note

This is a retrospective learning repository. The `original/` directory is frozen to show what was actually attempted at the end of Year 1; corrected code belongs separately under `R/` rather than silently replacing the historical version.
