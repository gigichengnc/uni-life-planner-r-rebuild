# Exploratory topic modelling in Phase 2

## Purpose

The Year 1 implementation used LDA and then treated the selected topic number as if it directly identified one of the five predefined interest categories. That is the central methodological mistake this rebuild is designed to make visible.

Phase 2 keeps **topic discovery** and **category classification** as separate analytical tasks.

The transparent category classifier lives in `R/03_classify_interests.R`. LDA lives separately in `R/05_explore_topics.R` and is used only to inspect patterns that emerge from the corpus.

## Revised topic workflow

```text
all reflection documents
        |
        v
shared preprocessing
        |
        v
one corpus-level document-term matrix
        |
        v
LDA with k exploratory topics
        |
        +--> top terms per topic
        |
        +--> topic probability per document
        |
        +--> dominant topic + uncertainty margin
```

The output labels remain deliberately neutral: `Topic 1`, `Topic 2`, and so on.

There is **no automatic mapping** such as:

```text
Topic 1 = Aesthetics & Spirituality
Topic 2 = Future Skills & Intelligence
```

A topic number is an index produced by the fitted model, not a predefined semantic category.

## Why corpus-level fitting matters

The historical code fitted a new LDA model inside the loop for each individual reflection. That makes the topic numbering and learned word distributions local to each tiny document-level model, so topic numbers cannot be compared meaningfully across reflections.

The reconstruction instead fits one exploratory model across the document-term matrix for the corpus. This at least gives the topics a shared model context.

## Small-corpus warning

The current public fixture set contains only five synthetic reflections. That is far too small to support strong claims about stable latent-topic structure.

`fit_lda_topics()` therefore emits a warning when fewer than 20 documents are supplied. The threshold is a project safeguard, not a claim that 20 documents is automatically sufficient for reliable topic modelling.

The current five-document example exists to verify architecture and execution only.

## Choosing `k`

The Phase 2 wrapper does **not** set `k` equal to the number of predefined categories. Those are different concepts.

For the five synthetic fixtures, the smoke test uses `k = 2` only to verify that the exploratory pipeline can fit a model and produce structured outputs. It does not mean the reflections truly contain exactly two latent topics.

Later work on a larger corpus could compare multiple `k` values using interpretability, stability, held-out diagnostics, and domain judgement. This repository deliberately avoids presenting automatic `k` selection as solved at the current sample size.

## Outputs

`run_topic_exploration()` returns:

- the filtered corpus-level document-term matrix;
- the fitted LDA model;
- ranked top terms for each anonymous topic;
- each document's dominant topic and runner-up topic;
- the probability margin between the top two topics;
- the full document-by-topic probability table.

The probability margin is included so that a dominant-topic label is not presented without some indication of uncertainty.

## Relationship to the category classifier

The architecture is now:

```text
reflection text
      |
      v
preprocessing
      |
      +--> explicit interest-category classifier --> evaluation
      |
      +--> exploratory corpus-level LDA
      |
      +--> sentiment analysis (next phase)
      |
      +--> activity recommendation (later)
```

The outputs can be compared descriptively later, but one branch does not define the labels of the other.

## Dependency

The core loading, preprocessing, classification, and evaluation modules use base R. Topic exploration intentionally adds one modelling dependency: `topicmodels`.

GitHub Actions installs that package before running the topic smoke test. The R module itself checks for the dependency and gives an explicit installation message if it is missing.

## Interpretation rule

The repository should describe LDA results using language such as:

> "In this exploratory fit, Topic 1 is characterised by terms such as ..."

It should not describe them as validated student-interest categories unless a separate, defensible labelling procedure is added and evaluated.
