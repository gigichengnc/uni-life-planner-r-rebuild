# Corrected implementation

The corrected implementation lives here and remains separate from `../original/`.

## Implemented in Phase 2

```text
01_load_data.R
02_preprocess.R
03_classify_interests.R
04_evaluate.R
05_explore_topics.R
06_sentiment.R
07_recommend_events.R
08_visualise.R
```

### `01_load_data.R`

Replaces the Year 1 hard-coded Windows paths with project-relative discovery and reusable loader functions. It loads synthetic reflections, the synthetic activity catalogue, and the manifest of intended test themes.

### `02_preprocess.R`

Separates text cleaning and tokenisation from modelling. It provides transparent base-R functions for UTF-8 normalisation, lowercase conversion, URL/number/punctuation cleaning, stopword removal, tokenisation, term counts, and a document-term matrix.

### `03_classify_interests.R`

Introduces a transparent dictionary baseline for the five predefined categories. It does **not** treat LDA topic numbers as category identities.

The classifier reports per-category scores, matched terms, the predicted category, top and runner-up scores, the margin, and explicit `ambiguous` / `unclassified` outcomes.

### `04_evaluate.R`

Compares predictions with labelled synthetic fixtures and reports strict accuracy, coverage, classified-case accuracy, case-level results, and a confusion matrix.

The current labels are synthetic test labels, so the evaluation is a pipeline check rather than a real-world performance claim. See [`../docs/classification-baseline.md`](../docs/classification-baseline.md).

### `05_explore_topics.R`

Reintroduces LDA only as a separate **exploratory topic-discovery** task. It builds one corpus-level document-term matrix, fits reproducible LDA, keeps labels neutral as `Topic 1`, `Topic 2`, etc., and never maps topic numbers directly onto the five predefined interest categories.

See [`../docs/topic-exploration.md`](../docs/topic-exploration.md).

### `06_sentiment.R`

Keeps NRC sentiment as a separate **descriptive** task rather than mixing it into category assignment or personality interpretation. It reports raw NRC lexicon-hit counts, rates per 100 words, dominant lexical-emotion summaries, and explicit tie/no-hit outcomes.

See [`../docs/sentiment-analysis.md`](../docs/sentiment-analysis.md).

### `07_recommend_events.R`

Rebuilds activity recommendation around explicit classification evidence rather than broad regex matching against LDA top words. It applies evidence thresholds, restricts candidates to the predicted category, exposes score components and matched terms, permits `no_recommendation`, and excludes sentiment/LDA topic numbers from ranking.

See [`../docs/recommendation-engine.md`](../docs/recommendation-engine.md).

### `08_visualise.R`

Turns the transparent outputs above into reproducible PNG figures without adding another modelling layer.

It can render:

- per-category classification scores;
- top-vs-runner-up classification evidence and margins;
- exploratory LDA topic-term probabilities while keeping neutral topic labels;
- NRC lexical sentiment rates;
- explainable recommendation rankings.

See [`../docs/visualisation.md`](../docs/visualisation.md).

## Quick checks

From a machine with R installed:

```bash
Rscript tests/smoke_test_phase2.R
Rscript tests/smoke_test_classification.R
Rscript tests/smoke_test_topics.R
Rscript tests/smoke_test_sentiment.R
Rscript tests/smoke_test_recommendations.R
Rscript tests/smoke_test_visualise.R
```

The tests verify implementation behaviour on deliberately clear synthetic fixtures. They do **not** establish real-world classification, topic, sentiment, recommendation, or visual validity.

The optional analytical modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

GitHub Actions installs these dependencies automatically and uploads CI-rendered sample figures as a workflow artifact when available.

## Render the complete sample output

```bash
Rscript scripts/render_sample_outputs.R
```

By default, the five generated figures are written to `output/figures/sample/`. Generated outputs are ignored by Git.

## Methodological rules

> **topic discovery is not category classification.**

> **sentiment description is not personality or interest classification.**

> **recommendation requires explicit classification evidence; weak evidence may produce no recommendation.**

> **visualisation displays existing outputs; it does not create new evidence.**

Classification, topic discovery, sentiment description, recommendation, and presentation remain separate tasks with separate assumptions.
