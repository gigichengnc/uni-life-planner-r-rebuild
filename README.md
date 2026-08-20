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
│   └── original_from_report.R
├── docs/
│   ├── reconstruction-notes.md
│   ├── known-problems.md
│   └── statistical-redesign.md
├── data/
│   ├── README.md
│   ├── sample/
│   └── private/
├── R/
│   └── README.md
├── output/
│   ├── figures/
│   └── examples/
└── tests/
```

## Status

**Phase 1 — reconstruction and audit.**

The original R script has been reconstructed from Appendix 1A of the submitted report. The public-facing repository should not yet include the original reflection journals or the unredacted submitted report because they contain personal information and/or material whose redistribution rights should be checked first.

## Next phase

The next implementation should separate **topic discovery** from **category classification**:

- corpus-level exploratory topic modelling, if LDA is retained;
- a transparent dictionary/rule-based baseline for the five predefined Metro Faith-style categories;
- explicit evaluation against manually labelled reflections;
- modular R functions;
- project-relative paths;
- reproducible dependencies;
- synthetic/redacted sample data only.

## Historical note

This is a retrospective learning repository. The `original/` directory is preserved to show what was actually attempted at the end of Year 1; corrected code should live separately under `R/` rather than silently replacing the historical version.
