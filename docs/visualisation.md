# Phase 2 visualisation layer

## Purpose

The visualisation layer exists to make the rebuilt analysis inspectable. It does **not** add a new predictive model and it does not change any classification, topic, sentiment, or recommendation decision.

`R/08_visualise.R` converts the structured outputs of the earlier modules into PNG figures that can be reviewed in a portfolio, report, or debugging workflow.

## Figures

The default sample renderer produces five figures:

1. `01-classification-scores.png` — dictionary evidence for every predefined interest category and reflection;
2. `02-classification-confidence.png` — top and runner-up classification scores with the resulting margin;
3. `03-topic-terms.png` — high-probability terms from neutrally labelled exploratory LDA topics;
4. `04-sentiment-rates.png` — corpus-mean NRC lexicon-hit rates per 100 words;
5. `05-recommendations.png` — ranked activity recommendations for one reflection, including evidence-count context.

## Interpretability rules

The figures preserve the methodological separation established in Phase 2:

- classification plots show dictionary evidence, not probabilities;
- LDA plots keep labels such as `Topic 1` and `Topic 2`; they are not automatically renamed as interest categories;
- NRC plots are lexical descriptions, not measures of personality or a student's true psychological state;
- recommendation plots show the explicit heuristic score already produced by the recommendation engine;
- sentiment and LDA topic numbers remain excluded from recommendation ranking.

The plots therefore visualise the logic that already exists rather than hiding another layer of assumptions inside presentation code.

## Reproducible sample rendering

From the repository root:

```bash
Rscript scripts/render_sample_outputs.R
```

This runs the synthetic Phase 2 pipeline and writes the generated PNG files to:

```text
output/figures/sample/
```

A custom output directory can be supplied:

```bash
Rscript scripts/render_sample_outputs.R --output=output/figures/custom
```

Generated figures are ignored by Git. They are derived outputs rather than source files.

## CI check

`tests/smoke_test_visualise.R` renders the five figures to `output/figures/ci/` and verifies that the files exist and are non-empty.

GitHub Actions can upload those CI-generated figures as a workflow artifact. The artifact demonstrates that the current branch rendered the plots successfully; it should not be treated as new evidence about real-world model quality.

## Limitation

All current public figures are based on deliberately clear synthetic fixtures. They are useful for checking architecture, reproducibility, and presentation. They are not a substitute for a held-out real-world evaluation dataset or a sufficiently large corpus for substantive topic-modelling claims.
