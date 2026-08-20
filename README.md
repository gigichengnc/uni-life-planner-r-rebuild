# From Words to Programs: R-Based Student Events Feedback Analysis

A retrospective reconstruction of a Year 1 course project from **STAT 2610SEF Data Analytics with Applications (2025 Spring)**.

The original project, **UNI LIFE PLANNER**, explored whether R-based text analytics could turn student reflections on university activities and competitions into useful signals about interests, emotions, and possible future activities.

This repository intentionally preserves both the ambition and the problems of the original implementation. The goal is not to pretend the Year 1 code was production-ready. Instead, it documents:

1. what the original project attempted;
2. how the original R pipeline worked;
3. where the statistical and programming problems occurred;
4. how the project could be redesigned today without erasing the original work.

## Original question

Can student event reflections be processed in R to identify themes, sentiment, and possible activity recommendations?

## Original pipeline

```text
Student reflection text
        |
        v
Text preprocessing in R
(lowercase, punctuation/number removal, stopword removal)
        |
        v
Document-Term Matrix
        |
        v
LDA topic modelling + top terms
        |
        v
Manually named interest category
        |
        +--> Word cloud
        |
        +--> NRC sentiment analysis
        |
        v
Keyword matching against activity announcements
        |
        v
Suggested student activities
```

## Why this repository is called `Problematic-Code-Uni`

The original code contains several useful learning examples:

- hard-coded Windows file paths;
- an unsupervised LDA topic index treated as if it were a predefined category label;
- inconsistent descriptions of the number of categories/topics in the written report;
- LDA fitted separately to very small individual documents;
- human "matchness" judgments described as accuracy without a formal evaluation protocol;
- duplicated sentiment-analysis code;
- an undeclared `RColorBrewer` dependency despite calling `brewer.pal()`;
- a single monolithic script mixing package installation, data loading, modelling, visualization, and recommendation logic;
- privacy/copyright risks if original student reflections are published directly.

These problems are documented in [`docs/known-problems.md`](docs/known-problems.md).

## Repository structure

```text
.
├── README.md
├── .gitignore
├── original/
│   ├── README.md
│   └── reconstructed_year1_code.R
├── docs/
│   ├── reconstruction-notes.md
│   ├── known-problems.md
│   └── statistical-redesign.md
├── data/
│   ├── README.md
│   ├── sample/
│   │   ├── activities.csv
│   │   ├── manifest.csv
│   │   └── reflections/
│   │       ├── reflection_01.txt
│   │       ├── reflection_02.txt
│   │       ├── reflection_03.txt
│   │       ├── reflection_04.txt
│   │       └── reflection_05.txt
│   └── private/
├── R/
│   ├── README.md
│   ├── 01_load_data.R
│   └── 02_preprocess.R
├── output/
│   ├── figures/
│   └── examples/
└── tests/
    └── smoke_test_phase2.R
```

## Status

### Phase 1 — reconstructed and frozen

The historical R script was reconstructed from Appendix 1A of the submitted report and frozen as [`original/reconstructed_year1_code.R`](original/reconstructed_year1_code.R). PDF line wrapping was repaired, but the historical programming and methodological logic is intentionally preserved.

### Phase 2 — foundation in progress

The corrected implementation has started with the parts that should be fixed before any new modelling is added:

- project-relative data discovery instead of hard-coded local paths;
- synthetic public-safe reflection and activity data;
- reusable data loading functions;
- preprocessing separated from modelling;
- explicit token and term-count outputs;
- a small smoke test for the corrected foundation.

The first two corrected modules use base R only, making the transformations easier to inspect and reducing unnecessary dependency problems.

## Data policy

The public repository does **not** publish the original ten reflection journals or the unredacted submitted report by default. The Phase 2 sample reflections and activity catalogue are synthetic test data written specifically for this reconstruction.

## Next methodological phase

The next implementation should separate **topic discovery** from **category classification**:

- corpus-level exploratory topic modelling, if LDA is retained;
- a transparent dictionary/rule-based baseline for the five predefined categories;
- explicit evaluation against labelled synthetic/redacted reflections;
- sentiment analysis as a separate task;
- recommendation logic based on explicit scores rather than arbitrary topic-number alignment.

## Quick foundation check

On a machine with R installed:

```bash
Rscript tests/smoke_test_phase2.R
```

## Historical note

This is a retrospective learning repository. The `original/` directory is frozen to show what was actually attempted at the end of Year 1; corrected code belongs separately under `R/` rather than silently replacing the historical version.
