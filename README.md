# From Words to Programs: R-Based Student Reflection Analytics

A retrospective reconstruction and redesign of a Year 1 course project from **STAT 2610SEF Data Analytics with Applications (2025 Spring)**.

The original project, **UNI LIFE PLANNER**, explored whether R-based text analytics could turn student reflections on university activities and competitions into useful signals about interests, emotions, and possible future activities.

This repository preserves the original attempt while rebuilding it as a more reproducible and statistically defensible R project. The rebuilt repository is **`uni-life-planner-r-rebuild`**.

The project documents:

1. what the original Year 1 implementation attempted;
2. where its statistical and programming problems occurred;
3. how those problems were redesigned without erasing the historical work;
4. how the corrected pipeline can be tested, visualised, and stress-tested;
5. where the transparent baseline still fails and how those failures can be diagnosed before model escalation.

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
- human "matchness" judgments described as accuracy without a formal evaluation protocol;
- duplicated sentiment-analysis code;
- an undeclared `RColorBrewer` dependency despite calling `brewer.pal()`;
- broad regex activity matching against LDA top words;
- a monolithic script mixing setup, loading, modelling, visualisation, and recommendation logic;
- privacy/copyright risks if original student reflections are published directly.

These problems are documented in [`docs/known-problems.md`](docs/known-problems.md).

The rebuild turns that into an inspectable learning sequence:

```text
historical implementation
        ↓
problem diagnosis
        ↓
methodological redesign
        ↓
modular implementation
        ↓
explicit tests
        ↓
interpretable outputs
        ↓
locked failure-case benchmark
        ↓
failure diagnosis
        ↓
model decision gate
```

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
│   └── failure-analysis.md
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
│   └── 10_analyse_failures.R
├── scripts/
│   ├── render_sample_outputs.R
│   ├── run_challenge_evaluation.R
│   └── run_failure_analysis.R
└── tests/
    ├── smoke_test_phase2.R
    ├── smoke_test_classification.R
    ├── smoke_test_topics.R
    ├── smoke_test_sentiment.R
    ├── smoke_test_recommendations.R
    ├── smoke_test_visualise.R
    ├── smoke_test_challenge.R
    └── smoke_test_failure_analysis.R
```

## Status

### Phase 1 — reconstructed and frozen

The historical R script was reconstructed from Appendix 1A of the submitted report and frozen as [`original/reconstructed_year1_code.R`](original/reconstructed_year1_code.R). PDF line wrapping was repaired, but the historical programming and methodological logic is intentionally preserved.

### Phase 2 — end-to-end reconstruction implemented

The corrected reconstruction includes project-relative loading, transparent preprocessing, a five-category dictionary classifier, explicit `ambiguous` / `unclassified` outcomes, corpus-level exploratory LDA, separate NRC sentiment description, explainable activity recommendation, base-R visualisation, smoke tests, and GitHub Actions automation.

The loading, preprocessing, classification, evaluation, recommendation, and visualisation modules use base R. Exploratory LDA adds the `topicmodels` dependency; NRC sentiment is isolated behind `syuzhet`.

### Phase 3 — locked synthetic challenge benchmark

The clear Phase 2 fixtures are not enough to evaluate failure behaviour, so Phase 3 adds benchmark version **`v1-locked-2026-08-20`** with 12 harder synthetic reflections.

The challenge set includes paraphrase, negation/context, mixed-domain, off-domain, and surface-keyword-versus-purpose cases. It evaluates the full decision: `classified` / `ambiguous` / `unclassified`, intended theme, and expected top or tied categories.

This benchmark is **synthetic and deliberately designed to probe known weaknesses**. It is not an unbiased external test set. Once created, v1 is treated as locked; rewriting cases to improve a later score would invalidate the benchmark logic. See [`docs/evaluation-challenge.md`](docs/evaluation-challenge.md).

### Phase 4 — failure analysis before model escalation

Phase 4 keeps both the classifier and the locked benchmark unchanged. `R/10_analyse_failures.R` converts incorrect challenge decisions into a documented diagnostic taxonomy and an investigation queue.

Example diagnostic families include lexical coverage, negation/compositional language, semantic context, intent weighting, multi-label/abstention behaviour, calibration, and off-domain false positives.

Each diagnosis is a **hypothesis about the observable error pattern**, not proof of the underlying causal mechanism. Suggested next steps are deliberately advisory: Phase 4 does not automatically edit the dictionary, tune thresholds, or replace the classifier.

See [`docs/failure-analysis.md`](docs/failure-analysis.md).

## Methodological rules

### Category classification

The Year 1 logic effectively treated an LDA topic number as a predefined category number. The rebuild instead uses an explicit dictionary baseline that exposes category scores and matched evidence terms.

### Topic discovery

LDA is fitted across the corpus and stays neutrally labelled `Topic 1`, `Topic 2`, and so on. Topic indices are never automatically converted into interest categories.

### Sentiment description

NRC output is treated as lexical description. It does not determine an interest category or infer personality.

### Activity recommendation

Recommendations require sufficiently strong classification evidence, restrict candidates to the predicted category, rank them using shared evidence, and can return `no_recommendation` when evidence is weak. Sentiment and LDA topic numbers are excluded from ranking.

### Challenge evaluation and failure analysis

The locked benchmark deliberately asks whether the transparent classifier fails gracefully. Phase 4 then diagnoses observed failures without changing the benchmark or classifier. If later changes are repeatedly designed while looking at this benchmark, it becomes validation data and a new unseen test set is required for external claims.

## Evaluation warning

`data/sample/` contains deliberately easy synthetic fixtures. `data/evaluation/` is harder and locked, but it is still synthetic and was authored specifically for this project.

Neither dataset supports a claim of real-world classification accuracy. A genuine external performance claim would require independently labelled, unseen data from a broader population and a clearly documented labelling protocol.

The Phase 4 taxonomy is also rule-based. It is useful for disciplined debugging, not a scientifically validated causal analysis of model errors.

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
```

Optional analytical modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

CI installs these packages and uploads rendered figures, challenge-evaluation tables, and failure-analysis tables as workflow artifacts when available.

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

Generated PNG/CSV outputs are ignored by Git so source history stays focused on code, fixtures, and documentation.

## Next phase

The next phase should be a **controlled model-decision experiment**, not automatic escalation. Review the Phase 4 failure register first, then choose the smallest justified intervention: a transparent phrase/negation rule, calibrated abstention or multi-label logic, evidence-supported dictionary changes, or a supervised/context-aware classifier only if enough independently labelled data exists.

Any model change should be recorded separately from the locked benchmark, and repeated tuning against the benchmark should be treated as validation rather than fresh testing.

## Historical note

This is a retrospective learning repository. The `original/` directory is frozen to show what was actually attempted at the end of Year 1; corrected code belongs separately under `R/` rather than silently replacing the historical version.
