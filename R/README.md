# Corrected implementation

The corrected implementation lives here and remains separate from `../original/`.

## Implemented in Phase 2 foundation

```text
01_load_data.R
02_preprocess.R
```

### `01_load_data.R`

Replaces the Year 1 hard-coded Windows paths with project-relative discovery and reusable loader functions. It loads:

- synthetic reflection `.txt` files;
- the synthetic activity catalogue;
- a manifest describing the intended theme of each test reflection.

The loader uses base R only.

### `02_preprocess.R`

Separates text cleaning and tokenisation from modelling. It provides reusable functions for:

- UTF-8 normalisation;
- lowercase conversion;
- URL, number, punctuation, and whitespace cleaning;
- explicit stopword removal;
- tokenisation;
- per-document term counts;
- a simple document-term matrix.

This module also uses base R only so that each transformation is transparent.

## Quick check

From a machine with R installed:

```bash
Rscript tests/smoke_test_phase2.R
```

The smoke test checks that five synthetic reflections, ten synthetic activities, token data, term counts, and a five-row document-term matrix can be produced.

## Planned next modules

```text
03_explore_topics.R
04_classify_interests.R
05_sentiment.R
06_recommend_events.R
07_visualise.R
```

The next methodological step is to keep **topic discovery** separate from **category classification** rather than assuming that LDA topic number 1 automatically corresponds to category number 1.
