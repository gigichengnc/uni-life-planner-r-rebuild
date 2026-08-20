# Statistical redesign

The redesign should preserve the original educational idea while separating tasks that the Year 1 code blended together.

## 1. Define the tasks explicitly

### Task A — Exploratory text analysis

Question: what themes and words recur across student event reflections?

Possible methods:

- term frequency / TF-IDF;
- word clouds only as a communication graphic, not as an inferential method;
- corpus-level topic modelling if the dataset becomes sufficiently large.

### Task B — Interest-category classification

Question: which predefined student-interest category best matches a reflection?

Start with a transparent baseline:

1. define a category dictionary;
2. preprocess a reflection;
3. calculate a weighted score for each category;
4. return the highest-scoring category plus evidence words;
5. allow `uncertain` when no score is strong enough.

Later versions could compare this baseline with a supervised classifier if enough labelled data becomes available.

### Task C — Sentiment/emotion analysis

Keep sentiment separate from interest classification. A reflection can be negative about a competition while still strongly indicating interest in future-skills activities.

### Task D — Event recommendation

First classify the reflection and each activity into a shared schema. Then calculate recommendation scores from compatible features rather than searching for any overlapping word.

## 2. Evaluation plan

For each reflection, create a small labelled table:

```text
reflection_id, expected_primary_category, optional_secondary_category
01, Aesthetics & Spirituality, Humanity & Love
02, Temperance & Justice,
...
```

Then evaluate:

- exact primary-category accuracy;
- top-2 accuracy if multiple interests are plausible;
- confusion matrix;
- per-category precision/recall if the dataset is large enough;
- qualitative error analysis explaining why failures occurred.

With only ten reflections, the quantitative metrics should be treated as descriptive, not as evidence of generalizable model performance.

## 3. Reproducibility

The corrected implementation should:

- use project-relative paths;
- pin dependencies;
- set seeds only where randomness exists;
- save intermediate structured outputs;
- separate source data from generated figures;
- include a small synthetic sample dataset for public testing.
