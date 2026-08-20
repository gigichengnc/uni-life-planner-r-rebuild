# From Words to Programs: R-Based Student Reflection Analytics

A retrospective reconstruction and redesign of a Year 1 course project from **STAT 2610SEF Data Analytics with Applications (2025 Spring)**.

The original project, **UNI LIFE PLANNER**, explored whether R-based text analytics could turn student reflections on university activities and competitions into useful signals about interests, emotions, and possible future activities.

This repository preserves the original attempt while rebuilding it as a more reproducible and statistically defensible R project. The rebuilt repository is **`uni-life-planner-r-rebuild`**.

The project documents:

1. what the original Year 1 implementation attempted;
2. how the original R pipeline worked;
3. where the statistical and programming problems occurred;
4. how those problems can be redesigned without erasing the historical work;
5. how the corrected pipeline can be tested, evaluated, and visualised explicitly.

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

The purpose of the rebuild is not to hide those mistakes. It is to make the improvement inspectable:

```text
historical implementation
        ↓
problem diagnosis
        ↓
methodological redesign
        ↓
modular implementation
        ↓
explicit tests and evaluation
        ↓
interpretable visual outputs
```

## Rebuilt architecture

```text
Reflection text
      |
      v
Data loading + preprocessing
      |
      +--> interest classification --> explicit evaluation
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
```

The important design rule is that these tasks remain separate. LDA topic numbers are not category labels, sentiment is not personality, and recommendation does not silently consume sentiment or topic indices.

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
│   ├── recommendation-engine.md
│   └── visualisation.md
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
│   ├── 07_recommend_events.R
│   └── 08_visualise.R
├── scripts/
│   └── render_sample_outputs.R
├── output/
│   ├── figures/
│   └── examples/
└── tests/
    ├── smoke_test_phase2.R
    ├── smoke_test_classification.R
    ├── smoke_test_topics.R
    ├── smoke_test_sentiment.R
    ├── smoke_test_recommendations.R
    └── smoke_test_visualise.R
```

## Status

### Phase 1 — reconstructed and frozen

The historical R script was reconstructed from Appendix 1A of the submitted report and frozen as [`original/reconstructed_year1_code.R`](original/reconstructed_year1_code.R). PDF line wrapping was repaired, but the historical programming and methodological logic is intentionally preserved.

### Phase 2 — end-to-end reconstruction implemented

The corrected reconstruction now includes:

- project-relative loading instead of hard-coded local paths;
- synthetic public-safe reflection and activity fixtures;
- reusable preprocessing;
- a transparent five-category dictionary classifier;
- explicit ambiguous and unclassified outcomes;
- classification evaluation against labelled synthetic fixtures;
- optional corpus-level LDA kept separate from category classification;
- NRC sentiment as a separate descriptive layer;
- an explainable recommender with evidence gates and `no_recommendation` outcomes;
- a base-R visualisation layer for the main interpretable outputs;
- smoke tests for all six stages;
- GitHub Actions automation for the tests and CI-rendered figure artifacts.

The loading, preprocessing, classification, evaluation, recommendation, and visualisation modules use base R. Exploratory LDA intentionally adds the `topicmodels` dependency, while NRC sentiment is isolated behind the `syuzhet` dependency.

## What changed methodologically?

### Category classification

The Year 1 logic effectively treated an LDA topic number as a predefined category number. Phase 2 instead uses an explicit dictionary baseline, exposing category scores and matched evidence terms.

### Topic discovery

LDA is fitted once across the corpus. Outputs remain neutrally labelled `Topic 1`, `Topic 2`, and so on. Topic indices are never automatically converted into the five predefined interest categories.

### Sentiment description

NRC output is treated as lexical description. Raw counts and length-normalised rates can be shown, but they do not determine interest categories or personality.

### Activity recommendation

The Year 1 recommender broadly matched LDA top words against activity announcements. Phase 2 requires sufficiently strong classification evidence, restricts candidate activities to the predicted category, ranks them using shared category evidence, and exposes the reasons for each recommendation. Weak evidence can produce no recommendation.

### Visualisation

The new plotting layer displays classification evidence, LDA topic terms, NRC rates, and recommendation scores without introducing new decision rules. Generated figures are derived outputs and remain ignored by Git by default.

See [`docs/classification-baseline.md`](docs/classification-baseline.md), [`docs/topic-exploration.md`](docs/topic-exploration.md), [`docs/sentiment-analysis.md`](docs/sentiment-analysis.md), [`docs/recommendation-engine.md`](docs/recommendation-engine.md), and [`docs/visualisation.md`](docs/visualisation.md).

## Evaluation warning

The five reflection files and ten activities in `data/sample/` are deliberately clear synthetic fixtures. Their labels and pairings are test fixtures, not independently validated real-world ground truth.

Perfect results on them can verify implementation behaviour only. They do not establish real-world classification accuracy, stable latent topics, psychological sentiment validity, recommendation quality, or external validity of the plots.

Meaningful performance claims require held-out data, independent labelling, and a larger corpus.

## Data policy

The public repository does **not** publish the original ten reflection journals or the unredacted submitted report by default. The Phase 2 sample reflections and activity catalogue are synthetic data written specifically for this reconstruction.

## Run the checks

On a machine with R installed:

```bash
Rscript tests/smoke_test_phase2.R
Rscript tests/smoke_test_classification.R
Rscript tests/smoke_test_topics.R
Rscript tests/smoke_test_sentiment.R
Rscript tests/smoke_test_recommendations.R
Rscript tests/smoke_test_visualise.R
```

The optional analytical modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

CI installs these packages through `.github/workflows/r-tests.yml` and uploads the rendered CI sample figures as a workflow artifact when available.

## Render the sample portfolio figures

```bash
Rscript scripts/render_sample_outputs.R
```

This writes five PNG figures to `output/figures/sample/` by default:

- classification scores;
- top-vs-runner-up classification evidence;
- exploratory topic terms;
- NRC sentiment rates;
- explainable recommendation rankings.

Generated outputs are ignored by Git so source history stays focused on code and documentation.

## Next phase

The original reflection-to-recommendation workflow is now reconstructed end to end. The next meaningful work is **validation rather than adding more model complexity**: create a genuinely held-out labelled dataset, document the labelling protocol, test failure cases, and then compare the transparent baseline with alternative classifiers only if the data volume supports it.

## Historical note

This is a retrospective learning repository. The `original/` directory is frozen to show what was actually attempted at the end of Year 1; corrected code belongs separately under `R/` rather than silently replacing the historical version.
