# Phase 6 — External Evaluation and Labelling Protocol

Phase 6 defines how a future **independently labelled, unseen evaluation set** should be collected and frozen before the rebuilt classifier is assessed again.

This phase does **not** create or claim to have an external test set. The repository contains only the protocol, schema templates, validators, and tests for the labelling workflow.

## Why a new dataset is required

The Phase 3 benchmark is fixed in content, but it has already been inspected during Phase 4 failure analysis and used during Phase 5 model experiments. It is therefore validation data, not a fresh external test set.

A future performance claim needs data that satisfy all of the following:

- the reflection text was not used to design the classifier, dictionary, thresholds, or failure rules;
- annotators label the text without seeing model predictions;
- at least two annotators label each reflection independently before discussion;
- disagreements are preserved and adjudicated explicitly rather than silently overwritten;
- the final adjudicated labels are frozen before model evaluation;
- privacy and redistribution rights are documented separately from analytical validity.

## Label space

The preserved Year 1 category schema remains:

1. `Aesthetics & Spirituality`
2. `Future Skills & Intelligence`
3. `Humanity & Love`
4. `Igniting & Sports`
5. `Temperance & Justice`

Annotators may also choose one of two decision states:

- `Ambiguous` — two or more categories are genuinely co-primary and a forced single label would misrepresent the reflection;
- `Unclassified` — the reflection does not have enough evidence for any of the five categories.

## Annotation fields

Each independent annotation records:

- `reflection_id`
- `annotator_id`
- `annotation_round`
- `status`
- `primary_category`
- `secondary_categories`
- `confidence`
- `rationale`
- `labelled_without_model_output`

`secondary_categories` uses `|` as the separator when more than one category is present.

### `classified`

- exactly one valid `primary_category` is required;
- `secondary_categories` may be blank or contain lower-priority relevant categories;
- secondary categories must not repeat the primary category.

### `ambiguous`

- `primary_category` must be blank;
- `secondary_categories` must contain at least two valid categories;
- the categories are treated as a set, not a ranking.

### `unclassified`

- both `primary_category` and `secondary_categories` must be blank.

## Confidence

Use a three-point confidence scale:

- `1` — low confidence; substantial uncertainty remains;
- `2` — moderate confidence;
- `3` — high confidence; the evidence is comparatively clear.

Confidence does not change the label. It is recorded to make uncertainty visible.

## Independent labelling procedure

For each reflection:

1. assign at least two annotators;
2. show the reflection text and this protocol only;
3. do **not** show dictionary terms, classifier scores, predictions, recommendation outputs, Phase 3 labels, or Phase 4 failure diagnoses;
4. each annotator completes an annotation independently;
5. freeze the first-round annotations before discussion;
6. calculate exact agreement and create an adjudication queue;
7. discuss only queued disagreements;
8. create one adjudicated label with a written rationale;
9. freeze the adjudicated label set before running any model on it.

## What counts as disagreement?

The validator treats the complete decision as the comparison unit:

```text
status
+ primary category
+ unordered secondary-category set
```

This is intentionally stricter than comparing only the primary category.

The repository reports exact agreement rather than pretending that a simple single-label kappa automatically fits ambiguous/multi-category decisions. More advanced inter-rater statistics can be added later if the final labelling design and sample size justify them.

## Adjudication

Adjudication is not a third annotator silently replacing the first two labels.

The final record should preserve:

- the original independent annotations;
- whether disagreement existed;
- who adjudicated;
- the adjudication method;
- the final decision;
- a rationale;
- dataset version;
- a `frozen = TRUE` flag.

Suggested adjudication methods include `discussion_consensus` or `third_reviewer`.

## Unseen-data registry

Before model evaluation, create a dataset registry containing at least:

- `reflection_id`
- `source_batch`
- `split`
- `first_seen_after_model_freeze`
- `public_release_allowed`
- `text_path`

For a genuine external test set:

```text
split = external_test
first_seen_after_model_freeze = TRUE
```

The registry is evidence about process; it does not by itself prove statistical independence.

## Freeze rule

Once adjudicated external labels are frozen:

- do not edit the external texts to make predictions easier;
- do not edit labels after seeing model errors unless a documented data-quality error is discovered;
- if a genuine label correction is necessary, version the dataset and preserve the previous version;
- do not tune model rules or thresholds on the external test results and then continue calling the same set "unseen".

If model development resumes after looking at external-test errors, obtain another unseen test set for the next external claim.

## Privacy and publication

Analytical validity does not grant publication rights.

Real reflection text, annotator identifiers, or source metadata may contain personal or redistribution-sensitive information. The public repository therefore keeps only templates. Real external-evaluation material should be stored under:

```text
data/external-evaluation/private/
```

which is ignored by Git by default. Public release should occur only when consent, anonymisation, and redistribution rights are clear.

## Public templates

The repository provides:

- `data/external-evaluation/dataset-register-template.csv`
- `data/external-evaluation/annotations-template.csv`
- `data/external-evaluation/adjudicated-labels-template.csv`

These are empty schemas, not collected data.

## Validation code

`R/12_validate_external_labels.R` validates dataset registries, independent annotations, adjudicated labels, exact agreement, and the disagreement queue.

The validator checks process consistency. It cannot prove that annotators were genuinely independent or that the data were truly unseen; those remain research-governance requirements that must be documented honestly.
