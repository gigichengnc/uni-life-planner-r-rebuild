# Phase 2 classification baseline

## Purpose

The Year 1 implementation used an unsupervised LDA topic index and then treated that index as if it directly identified one of the five predefined student-interest categories. That mapping is not statistically justified.

Phase 2 therefore introduces a deliberately simple **dictionary-based classification baseline** before considering any more complex model.

## Five categories

The baseline keeps the five categories used by the reconstructed Year 1 code:

1. Aesthetics & Spirituality
2. Future Skills & Intelligence
3. Humanity & Love
4. Igniting & Sports
5. Temperance & Justice

Each category has an explicit list of indicative terms in `R/03_classify_interests.R`.

## How scoring works

The default mode is **binary dictionary scoring**:

1. preprocess each reflection into tokens;
2. compare the observed tokens with each category dictionary;
3. give one point for each distinct matched dictionary term;
4. select the category with the highest score;
5. return `Ambiguous` when multiple categories share the highest positive score;
6. return `Unclassified` when every category scores zero.

A frequency-based mode is also available, but binary scoring is the default because repeated use of one word should not automatically dominate the baseline.

## Why this is better than the Year 1 category mapping

The method is not presented as sophisticated machine learning. Its advantage is that the decision rule is visible and testable.

For every prediction we can inspect:

- the score of every category;
- the terms that matched;
- the top score;
- the runner-up score;
- the classification margin;
- whether the result was classified, ambiguous, or unclassified.

This makes errors diagnosable rather than hiding them behind an arbitrary topic-number-to-category mapping.

## Evaluation

`R/04_evaluate.R` compares predictions with the `intended_theme` field in `data/sample/manifest.csv` and reports:

- number of cases;
- number classified;
- number correct;
- strict accuracy;
- coverage;
- accuracy among classified cases;
- a confusion matrix.

## Critical limitation

The five current reflections are **synthetic fixtures written specifically for this reconstruction**. Their labels are intended test labels, not independently validated ground truth.

Therefore, even if the smoke test reaches 100% on these five fixtures, that result must **not** be described as evidence that the classifier has 100% real-world accuracy. It only shows that the transparent baseline behaves as expected on deliberately clear examples.

A meaningful performance claim would require a separate labelled evaluation dataset that was not written to fit the dictionary. Ideally, labels would be assigned independently by more than one reviewer and disagreements would be documented.

## Relationship to LDA

LDA may still have a place later as an exploratory **topic discovery** method at corpus level. It should not be used to claim that topic 1 automatically equals predefined category 1, topic 2 equals category 2, and so on.

The revised architecture is therefore:

```text
reflection text
      |
      v
preprocessing
      |
      +--> explicit category classifier --> evaluation
      |
      +--> optional corpus-level topic discovery
      |
      +--> sentiment analysis
```

These are separate analytical tasks with separate assumptions.
