# Known problems in the Year 1 implementation

This document separates **programming problems**, **statistical/methodological problems**, and **data/governance problems**.

## P01 — Hard-coded local file paths

**Original behaviour**

The code points directly to paths such as:

```r
"C:/Users/cnc_g/OneDrive/文件/HW/01.txt"
```

**Why this is a problem**

The program depends on one user's computer and directory structure. Another user cannot run the project without editing the source.

**Refactor direction**

Use project-relative paths such as `data/sample/reflection_01.txt`, ideally via `here::here()` or a configuration file.

---

## P02 — Topic index is treated as a predefined category label

**Original behaviour**

```r
lda_model <- LDA(dtm, k = length(categories), ...)
most_relevant_topic <- which.max(colSums(posterior(lda_model)$topics))
category_name <- names(categories)[most_relevant_topic]
```

**Why this is a problem**

LDA is unsupervised. Topic 1, Topic 2, etc. do not inherently correspond to the manually named categories in the same numerical order. The code therefore creates a category mapping that the model itself has not learned or justified.

**Impact observed in the report**

Some reflections were assigned to categories that did not match the human interpretation. A legal/mock-trial reflection, for example, was reported by the R program as `Igniting & Sports` even though the human interpretation was closer to `Temperance & Justice`.

**Refactor direction**

Treat topic modelling as exploratory. Build category classification as a separate step with explicit labelled rules/data.

---

## P03 — Five, six, and seven categories/topics are described inconsistently

The appendix code defines **five** categories. Elsewhere in the written methodology, the project describes different counts (including six/seven categories/topics).

**Refactor direction**

Create one canonical category schema and reference it everywhere.

---

## P04 — LDA is fitted separately to very small individual texts

The loop builds a corpus and DTM from one reflection file at a time, then fits a five-topic LDA model inside that loop.

**Why this is fragile**

Topic models are normally intended to infer recurring latent structure across a collection of documents. Fitting multiple topics to one short reflection broken into lines can produce unstable or artificial topics.

**Refactor direction**

If LDA is retained, train it at corpus level across all documents, then inspect document-topic distributions. For a small dataset, a simpler transparent baseline may be preferable.

---

## P05 — `matchness` is not a formal accuracy metric

The report includes human judgments such as 20%, 60%, 90% matchness, but the submitted material does not define a reproducible labelled test set, confusion matrix, precision/recall, or another formal evaluation protocol.

**Refactor direction**

Manually label each reflection with one or more expected categories, freeze the labels before testing, and calculate explicit metrics.

---

## P06 — Recommendation logic is broad regex matching

```r
related_rows <- announcements[
  grepl(paste(bag_of_words, collapse = "|"), announcements, ignore.case = TRUE)
]
```

Any announcement containing any top-topic word can be returned.

**Why this is a problem**

Generic words such as `team`, `growth`, `competition`, `experience`, or `community` can match unrelated activities.

**Refactor direction**

Use weighted category/activity features and require multiple or higher-specificity matches.

---

## P07 — Duplicated sentiment-analysis code

The appendix performs NRC sentiment analysis, creates an on-screen barplot, and then immediately performs the same sentiment computation again before writing a PNG.

**Refactor direction**

Calculate sentiment once and pass the result to reusable plotting/export functions.

---

## P08 — `RColorBrewer` dependency is not declared

The original script calls:

```r
brewer.pal(8, "Dark2")
```

but `RColorBrewer` does not appear in the package list shown in the appendix.

**Possible outcome**

A fresh R environment may fail with `could not find function "brewer.pal"` unless another loaded package happens to expose/import it in a usable way.

**Refactor direction**

Declare `RColorBrewer` explicitly or call `RColorBrewer::brewer.pal()`.

---

## P09 — Package installation is mixed into analysis execution

The script installs missing packages every time the project setup is run.

**Refactor direction**

Use a reproducible dependency file/environment such as `renv.lock`. Analysis scripts should load dependencies, not mutate the user's R installation automatically.

---

## P10 — One monolithic script has too many responsibilities

The same loop handles data loading, cleaning, topic modelling, classification, recommendation, sentiment analysis, plotting, output formatting, and file export.

**Refactor direction**

Split into functions/modules and add tests.

---

## P11 — Source text can mix different semantic layers

The report describes reflection journals alongside AI-generated personality analysis and other contextual material. If these are placed in the same text file, the model may learn words from the added analysis rather than only from the student's event reflection.

**Refactor direction**

Store `reflection_text`, `context`, and `ai_annotation` as separate fields and analyse them separately.

---

## P12 — Public-data/privacy risk

The original submission includes personal reflection content and identifying information. A public GitHub reconstruction should not upload those materials by default.

**Refactor direction**

Use synthetic/redacted samples in `data/sample/` and keep private material under `data/private/`, which is ignored by Git.
