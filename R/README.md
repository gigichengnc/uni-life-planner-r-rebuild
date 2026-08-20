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

Reintroduces LDA only as a separate **exploratory topic-discovery** task.

It builds one corpus-level document-term matrix, fits reproducible LDA, keeps labels neutral as `Topic 1`, `Topic 2`, etc., and never maps topic numbers directly onto the five predefined interest categories.

See [`../docs/topic-exploration.md`](../docs/topic-exploration.md).

### `06_sentiment.R`

Keeps NRC sentiment as a separate **descriptive** task rather than mixing it into category assignment or personality interpretation.

It reports raw NRC lexicon-hit counts, rates per 100 words, dominant lexical-emotion summaries, and explicit tie/no-hit outcomes. It never determines an interest category or LDA topic label.

See [`../docs/sentiment-analysis.md`](../docs/sentiment-analysis.md).

### `07_recommend_events.R`

Rebuilds the activity recommendation step around explicit evidence rather than a broad regex over LDA top words.

It:

- requires a `classified` interest result;
- applies minimum classifier-score and margin thresholds;
- restricts candidates to the predicted interest category;
- derives category-relevant feature terms from each activity title/description;
- ranks candidates using the classifier score plus shared evidence terms;
- returns the matched evidence and score components for inspection;
- returns `no_recommendation` when evidence is weak;
- explicitly excludes sentiment scores and LDA topic numbers from ranking.

See [`../docs/recommendation-engine.md`](../docs/recommendation-engine.md).

## Quick checks

From a machine with R installed:

```bash
Rscript tests/smoke_test_phase2.R
Rscript tests/smoke_test_classification.R
Rscript tests/smoke_test_topics.R
Rscript tests/smoke_test_sentiment.R
Rscript tests/smoke_test_recommendations.R
```

The tests verify implementation behaviour on deliberately clear synthetic fixtures. They do **not** establish real-world classification, topic, sentiment, or recommendation quality.

The optional analytical modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

GitHub Actions installs these dependencies automatically.

## Planned next module

```text
08_visualise.R
```

The methodological rules for the reconstruction are explicit:

> **topic discovery is not category classification.**

> **sentiment description is not personality or interest classification.**

> **recommendation requires explicit classification evidence; weak evidence may produce no recommendation.**

Classification, topic discovery, sentiment description, and recommendation remain separate analytical tasks with separate assumptions.
