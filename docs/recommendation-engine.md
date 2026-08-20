# Phase 2 activity recommendation engine

## Purpose

The Year 1 implementation recommended activities by taking top words from an LDA topic and running a broad regular-expression match against activity announcements. That creates two problems at once:

1. the topic itself was incorrectly treated as a predefined interest category;
2. a single generic word could trigger an activity recommendation without enough supporting evidence.

Phase 2 replaces that logic with an explicit, inspectable recommendation rule.

## Inputs

`R/07_recommend_events.R` uses only:

- the predicted interest category from the transparent classifier;
- the classifier's top score;
- the classification margin;
- the matched category evidence terms;
- each activity's declared category;
- category-relevant terms found in the activity title and description.

It intentionally does **not** use NRC sentiment scores or LDA topic numbers.

## Eligibility gate

A reflection is eligible for recommendations only when:

1. classification status is `classified`;
2. the predicted theme exists in the category dictionary;
3. the classifier score reaches `min_top_score`;
4. the classification margin reaches `min_margin`;
5. at least one activity exists in the predicted category;
6. an activity reaches the `min_shared_evidence` threshold.

The default settings are deliberately conservative:

```text
min_top_score = 2
min_margin = 1
min_shared_evidence = 1
```

If those conditions are not met, the system returns `no_recommendation` with a diagnostic reason rather than forcing an answer.

## Activity features

For each activity, the title and description are preprocessed with the same transparent tokenizer used elsewhere in Phase 2. The resulting tokens are intersected with the dictionary for the activity's declared category.

This produces explicit `activity_feature_terms` such as:

```text
hackathon, coding, data, prototype
```

The reflection's matched classification evidence is then compared with those activity features.

## Recommendation score

For an eligible reflection/activity pair in the same category, the default score is:

```text
recommendation_score
  = 5 * category_match
  + 0.5 * classifier_top_score
  + 2 * shared_evidence_count
```

Because candidates are restricted to the predicted category, `category_match` is 1 for every scored candidate. The classifier score records how much category evidence the reflection contained, while `shared_evidence_count` differentiates activities within that category.

The defaults are a transparent baseline rather than optimised weights. They are intentionally easy to inspect and change.

## Output

Every recommendation includes:

- reflection ID;
- rank;
- event ID and title;
- category;
- total recommendation score;
- classifier score;
- classification margin;
- number of shared evidence terms;
- the actual shared evidence terms;
- the activity feature terms;
- a short reason string.

The function also returns a diagnostics table for every reflection, including those for which no recommendation is produced.

## Why sentiment is excluded

A reflection can contain frustration, fear, disappointment, or negative language while still clearly expressing interest in a topic. Using sentiment to suppress or promote activity recommendations would add an assumption that is not justified by the current project design.

Sentiment therefore remains a separate descriptive analysis in `R/06_sentiment.R`.

## Why LDA is excluded

LDA remains an optional exploratory topic-discovery tool in `R/05_explore_topics.R`. Topic numbers are not category identities, confidence scores, or recommendation labels.

The recommendation engine consumes the explicit classification path instead.

## Current evaluation limitation

The current activities and reflections are synthetic fixtures written for reconstruction and smoke testing. A successful smoke test demonstrates that the recommendation rules behave as designed on clear examples; it does not establish real-world recommendation quality.

A later evaluation should use independently labelled or user-rated reflection/activity pairs and measure ranking quality separately from classification accuracy.
