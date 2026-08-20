# From Words to Programs: R-Based Student Reflection Analytics

A retrospective reconstruction and redesign of a Year 1 course project from **STAT 2610SEF Data Analytics with Applications (2025 Spring)**.

The original project, **UNI LIFE PLANNER**, explored whether R-based text analytics could turn student reflections on university activities and competitions into useful signals about interests, emotions, and possible future activities.

This repository preserves the original attempt while rebuilding it as a more reproducible and statistically defensible R project. The rebuilt repository is **`uni-life-planner-r-rebuild`**.

The project documents:

1. what the original Year 1 implementation attempted;
2. how the original R pipeline worked;
3. where the statistical and programming problems occurred;
4. how those problems can be redesigned without erasing the historical work;
5. how the corrected pipeline can be tested and evaluated explicitly.

## Original question

Can student event reflections be processed in R to identify themes, sentiment, and possible activity recommendations?

## Original pipeline

```text
Student reflection text
        |
        v
Text preprocessing in R
(lowercase, punctuation/number removal, stopword removal)
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

The original implementation contains several useful learning examples:

- hard-coded Windows file paths;
- an unsupervised LDA topic index treated as if it were a predefined category label;
- inconsistent descriptions of the number of categories/topics in the written report;
- LDA fitted separately to very small individual documents;
- human "matchness" judgments described as accuracy without a formal evaluation protocol;
- duplicated sentiment-analysis code;
- an undeclared `RColorBrewer` dependency despite calling `brewer.pal()`;
- broad regex activity matching against LDA top words;
- a single monolithic script mixing package installation, data loading, modelling, visualization, and recommendation logic;
- privacy/copyright risks if original student reflections are published directly.

These problems are documented in [`docs/known-problems.md`](docs/known-problems.md).

The purpose of the rebuild is not to hide those mistakes. It is to make the improvement inspectable: **historical implementation → diagnosis → redesign → tested implementation**.

## Repository structure

```text
.
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       └── r-tests.yml
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
│   └── recommendation-engine.md
├── data/
│   ├── README.md
│   ├── sample/
│   │   ├── activities.csv
│   │   ├── manifest.csv
│   │   └── reflections/
│   │       ├── reflection_01.txt
│   │       ├── reflection_02.txt
│   │       ├── reflection_03.txt
│   │       ├── reflection_04.txt
│   │       └── reflection_05.txt
│   └── private/
├── R/
│   ├── README.md
│   ├── 01_load_data.R
│   ├── 02_preprocess.R
│   ├── 03_classify_interests.R
│   ├── 04_evaluate.R
│   ├── 05_explore_topics.R
│   ├── 06_sentiment.R
│   └── 07_recommend_events.R
├── output/
│   ├── figures/
│   └── examples/
└── tests/
    ├── smoke_test_phase2.R
    ├── smoke_test_classification.R
    ├── smoke_test_topics.R
    ├── smoke_test_sentiment.R
    └── smoke_test_recommendations.R
```

## Status

### Phase 1 — reconstructed and frozen

The historical R script was reconstructed from Appendix 1A of the submitted report and frozen as [`original/reconstructed_year1_code.R`](original/reconstructed_year1_code.R). PDF line wrapping was repaired, but the historical programming and methodological logic is intentionally preserved.

### Phase 2 — corrected foundation + separated analytical tasks

The corrected implementation now includes:

- project-relative data discovery instead of hard-coded local paths;
- synthetic public-safe reflection and activity data;
- reusable data loading functions;
- preprocessing separated from modelling;
- a transparent dictionary classifier for the five predefined interest categories;
- explicit ambiguous and unclassified outcomes;
- evaluation against labelled synthetic fixtures;
- optional corpus-level LDA topic exploration kept separate from category classification;
- NRC sentiment as a separate descriptive layer;
- an explainable activity recommender with evidence thresholds and `no_recommendation` outcomes;
- smoke tests for foundation, classification, topic exploration, sentiment, and recommendation;
- a GitHub Actions workflow that runs the R smoke tests on the reconstruction branch and pull requests to `main`.

The loading, preprocessing, classification, evaluation, and recommendation modules use base R. Exploratory LDA intentionally adds the `topicmodels` dependency, while NRC sentiment is isolated behind the `syuzhet` dependency.

## What changed methodologically?

The reconstruction separates analytical tasks that the Year 1 implementation mixed together.

### Category classification

The Year 1 logic effectively treated an LDA topic number as if it were the same thing as a predefined category number. Phase 2 instead uses an explicit category dictionary as a simple classification baseline. Every score and matched term can be inspected.

### Topic discovery

LDA is now fitted once across the corpus and its outputs remain anonymously labelled `Topic 1`, `Topic 2`, and so on. Those topic indices are not automatically converted into the five predefined interest categories.

### Sentiment description

NRC sentiment is now a separate lexical description. It reports emotion/polarity hits and rates per 100 words, but does not determine a student's interest category, infer personality, or label LDA topics.

### Activity recommendation

The Year 1 recommender broadly matched LDA top words against activity announcements. Phase 2 instead consumes the explicit classification result and activity metadata.

A recommendation is produced only when classification evidence passes minimum score and margin thresholds. Candidate activities are restricted to the predicted category and ranked using shared category evidence. The output exposes the score, matched evidence terms, and reason. Weak evidence can produce `no_recommendation` rather than a forced suggestion.

Sentiment scores and LDA topic numbers are intentionally excluded from recommendation ranking.

See [`docs/classification-baseline.md`](docs/classification-baseline.md), [`docs/topic-exploration.md`](docs/topic-exploration.md), [`docs/sentiment-analysis.md`](docs/sentiment-analysis.md), and [`docs/recommendation-engine.md`](docs/recommendation-engine.md).

## Evaluation warning

The five current reflection files and ten current activities are synthetic fixtures written specifically for this reconstruction. Their labels and pairings are test fixtures, not independently validated real-world ground truth.

Therefore, perfect results on these fixtures verify implementation behaviour only. They do not establish real-world classification accuracy, stable latent topics, psychological sentiment validity, or recommendation quality.

Meaningful performance claims require held-out data and independent evaluation.

## Data policy

The public repository does **not** publish the original ten reflection journals or the unredacted submitted report by default. The Phase 2 sample reflections and activity catalogue are synthetic test data written specifically for this reconstruction.

## Quick checks

On a machine with R installed:

```bash
Rscript tests/smoke_test_phase2.R
Rscript tests/smoke_test_classification.R
Rscript tests/smoke_test_topics.R
Rscript tests/smoke_test_sentiment.R
Rscript tests/smoke_test_recommendations.R
```

The optional analytical tests require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

CI installs these packages automatically through `.github/workflows/r-tests.yml`.

Runtime results should be read from the repository's GitHub Actions checks rather than inferred from the presence of the workflow file alone.

## Next methodological phase

The original reflection-to-recommendation path is now reconstructed. The next module can focus on **interpretable visualisation** rather than adding more hidden modelling assumptions.

`08_visualise.R` should turn the existing transparent outputs into plots such as:

- per-category classifier scores;
- classification margins and uncertain cases;
- neutral LDA topic-term summaries;
- NRC sentiment rates;
- recommendation score components and evidence terms.

A later phase should add a genuinely held-out labelled evaluation set and a larger corpus before making substantive performance claims.

## Historical note

This is a retrospective learning repository. The `original/` directory is frozen to show what was actually attempted at the end of Year 1; corrected code belongs separately under `R/` rather than silently replacing the historical version.
