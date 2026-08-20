# Reconstruction notes

## Source

The original R script was reconstructed from **Appendix 1A, pages 50–55** of the submitted `UNI LIFE PLANNER` report for STAT 2610SEF (2025 Spring).

## Reconstruction rule

The historical file should preserve the original logic. Only PDF formatting artefacts such as line wrapping were repaired. Problems that were visible in the original implementation were deliberately not silently fixed.

## Confirmed original components

The appendix shows:

- an 11-package list (`tm`, `topicmodels`, `dplyr`, `crayon`, `wordcloud`, `ggplot2`, `syuzhet`, `ldatuning`, `textTinyR`, `rmarkdown`, `knitr`);
- automatic package installation;
- ten hard-coded reflection-journal paths;
- one hard-coded activity-announcement path;
- five predefined interest categories;
- `tm` preprocessing;
- a document-term matrix;
- LDA with `k = length(categories)`;
- top-10 topic terms;
- mapping of the selected LDA topic index directly to `names(categories)`;
- regex keyword matching against activity announcements;
- word-cloud generation;
- NRC sentiment analysis;
- PNG exports of sentiment plots and word clouds.

## Important preservation decision

The submitted report itself and the original text files should not be added to a public repository until privacy and redistribution questions are resolved. This is why Phase 1 uses documentation plus a code transcription only.
