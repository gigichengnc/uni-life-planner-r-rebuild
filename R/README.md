# Corrected implementation

The corrected implementation lives here and remains separate from `../original/`.

## Implemented in Phase 2

```text
01_load_data.R
02_preprocess.R
03_classify_interests.R
04_evaluate.R
05_explore_topics.R
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

It:

- builds one filtered document-term matrix across the corpus;
- fits an LDA model with reproducible seed settings;
- keeps labels neutral as `Topic 1`, `Topic 2`, etc.;
- extracts top terms for each topic;
- reports document-topic probabilities, dominant topics, runner-up topics, and margins;
- warns when the corpus is very small;
- never converts a topic number directly into one of the five predefined interest categories.

This module intentionally uses the `topicmodels` package. See [`../docs/topic-exploration.md`](../docs/topic-exploration.md).

## Quick checks

From a machine with R installed:

```bash
Rscript tests/smoke_test_phase2.R
Rscript tests/smoke_test_classification.R
Rscript tests/smoke_test_topics.R
```

The first test checks data loading and preprocessing. The second checks the dictionary classifier and evaluation pipeline on the five deliberately clear synthetic fixtures. The third checks that corpus-level LDA can fit and return structured topic outputs; it does **not** validate the topics as real-world constructs.

The topic smoke test requires:

```r
install.packages("topicmodels")
```

GitHub Actions installs this dependency automatically.

## Planned next modules

```text
06_sentiment.R
07_recommend_events.R
08_visualise.R
```

The methodological rule for the reconstruction is explicit:

> **topic discovery is not category classification.**

Classification has its own transparent scoring and evaluation path. LDA is optional exploratory analysis at corpus level only.
