# Uni Life Planner — R Rebuild

**A reproducible reconstruction of a Year 1 R text-analytics project, rebuilt around transparent baselines, abstention, and explicit evidence boundaries.**

The current project separates interest classification, topic exploration, sentiment description, recommendation, and evaluation instead of treating them as one model. The reference classifier is a five-category dictionary baseline that can return `Ambiguous` or `Unclassified` rather than forcing every reflection into a category.

## Run it

```bash
Rscript tests/smoke_test_classification.R
Rscript scripts/run_challenge_evaluation.R output/examples/challenge
```

Optional topic/sentiment modules require `topicmodels` and `syuzhet`.

> **Evidence boundary:** the retained baseline reproduces **8/12** correct decisions on a locked synthetic challenge set. Those 12 authored cases are validation data, not an external test set, so this repository makes **no real-world accuracy claim**. The next evidence gate is independently labelled, genuinely unseen reflections.

This is a retrospective reconstruction of **STAT 2610SEF Data Analytics with Applications (2025 Spring)**. The Year 1 attempt is preserved under `original/`; the corrected implementation lives separately under `R/`.

## Portfolio snapshot

| Item | Current project state |
| --- | --- |
| Original problem | Analyse student activity reflections and turn text into useful signals |
| Historical baseline | Frozen under `original/` rather than silently rewritten |
| Rebuilt pipeline | Loading, preprocessing, classification, topic exploration, sentiment, recommendation, visualisation, and evaluation are separate modules |
| Reference classifier | Transparent five-category dictionary baseline with `Ambiguous` and `Unclassified` outcomes |
| Validation | Five clear implementation fixtures plus a locked 12-case **self-authored synthetic validation** benchmark; neither is an external test |
| Model-development decision | Retain Variant A as the simplest reference baseline; the 12-case exercise is not a statistically powered model-selection result |
| Reproducibility | GitHub Actions runs on pull requests to `main` and pushes to `main` using R 4.6.1 and a dated 2026-08-20 CRAN snapshot |
| External accuracy claim | **Not made**; a new independently labelled unseen dataset is still required |
| Next evidence gate | Collect, independently label, adjudicate, freeze, and evaluate genuinely unseen reflections |

For the clearest summary of how the project changed, see [`docs/before-vs-after.md`](docs/before-vs-after.md).

## The original question

> Can student event reflections be processed in R to identify themes, sentiment, and possible activity recommendations?

The question remains useful. The main change is **how the evidence is produced and interpreted**.

## Why rebuild it?

The Year 1 implementation contains several useful learning examples:

- hard-coded Windows file paths;
- an unsupervised LDA topic index treated as if it were a predefined category label;
- inconsistent descriptions of the number of categories/topics;
- LDA fitted separately to very small individual documents;
- human “matchness” judgments described as accuracy without a formal evaluation protocol;
- duplicated sentiment-analysis code;
- an undeclared `RColorBrewer` dependency despite calling `brewer.pal()`;
- broad regex activity matching against LDA top words;
- a monolithic script mixing setup, loading, modelling, visualisation, and recommendation logic;
- privacy/copyright risks if original student reflections are published directly.

The detailed audit is preserved in [`docs/known-problems.md`](docs/known-problems.md).

## What changed

| Year 1 implementation | Rebuilt project |
| --- | --- |
| Hard-coded local paths | Project-relative data loading |
| One monolithic script | Twelve focused R modules |
| LDA topic number mapped to a category name | Category classification and topic discovery are separate tasks |
| Every result pushed toward one category | Explicit `Ambiguous` and `Unclassified` states |
| “Matchness” used as informal accuracy | Predictions and labels are separated; evaluation is explicit |
| Sentiment mixed into the broader interpretation | NRC sentiment is descriptive only |
| Regex recommendations from LDA top words | Recommendations require explicit classification evidence |
| No reproducible test pipeline | Smoke tests and GitHub Actions |
| Easy examples could look like validation | Clear fixtures are labelled as implementation checks |
| Model changes could be judged by aggregate score alone | Locked benchmark, failure analysis, paired comparisons, and a model-decision record |
| No external-test protocol | Independent annotation, adjudication, freeze, and privacy rules are defined before future evaluation |

See [`docs/before-vs-after.md`](docs/before-vs-after.md) for the fuller technical comparison.

## Rebuilt architecture

```text
Reflection text
      |
      v
Data loading + preprocessing
      |
      +--> interest classification --> clear-fixture evaluation
      |
      +--> optional corpus-level LDA topic exploration
      |
      +--> NRC lexical sentiment description
      |
      v
Explainable activity recommendation
      |
      v
Interpretable visualisation
      |
      v
Locked synthetic challenge evaluation
      |
      v
Failure taxonomy + improvement queue
      |
      v
Controlled validation experiments
      |
      v
Model decision review
      |
      v
Independent-labelling + unseen-test protocol
```

The analytical boundaries are intentional:

- **topic discovery is not category classification**;
- **sentiment description is not personality or interest classification**;
- **recommendation requires explicit evidence**;
- **validation data are not a substitute for a fresh external test set**.

## Evidence and model decision

### Clear synthetic fixtures

`data/sample/` contains deliberately easy examples used mainly to verify implementation and output structure.

They are **not** evidence of real-world accuracy.

### Locked challenge benchmark

`data/evaluation/` contains benchmark version **`v1-locked-2026-08-20`** with 12 harder synthetic reflections covering paraphrase, negation/context, mixed-domain, off-domain, and surface-keyword-versus-purpose cases.

Once this benchmark informed model-development decisions, it became **validation data**, not an untouched test set.

### Controlled experiments

Three pre-declared variants were compared:

```text
A  current dictionary baseline
B  A + local three-token negation handling
C  B + minimum top score 2 + ambiguity margin 1
```

The repository definitions reproduce **8/12** correct validation decisions for A, B, and C. B changes no decisions; C fixes one case and regresses one case. The model-decision review therefore retains **Variant A** rather than promoting extra logic without net evidence of improvement.

This is a **worked model-development and restraint example**, not a statistically powered model-selection study. The dictionary, synthetic cases, labels, and candidate variants were developed within the same project, so the 8/12 result should not be generalized beyond this validation exercise.

See [`docs/model-decision-review.md`](docs/model-decision-review.md).

## Reproducibility

GitHub Actions runs the complete required smoke-test and reporting pipeline on pull requests targeting `main` and on pushes to `main`, including:

- loading and preprocessing;
- classification;
- corpus-level topic exploration;
- sentiment;
- recommendations;
- visualisation;
- locked challenge evaluation;
- failure analysis;
- controlled experiments;
- external-label protocol validation;
- derived challenge/failure/experiment tables.

The CI reference environment uses **Ubuntu 24.04**, **R 4.6.1**, and a **Posit Public Package Manager CRAN snapshot dated 2026-08-20**. It also installs the GSL system dependency needed by `topicmodels` and verifies `topicmodels` 0.2-17 and `syuzhet` 1.0.7 before running the tests.

This is a pinned CI reference environment, not a complete container or OS-level lock. See [`docs/reproducibility.md`](docs/reproducibility.md) for the exact boundary.

### Run locally

```bash
Rscript tests/smoke_test_phase2.R
Rscript tests/smoke_test_classification.R
Rscript tests/smoke_test_topics.R
Rscript tests/smoke_test_sentiment.R
Rscript tests/smoke_test_recommendations.R
Rscript tests/smoke_test_visualise.R
Rscript tests/smoke_test_challenge.R
Rscript tests/smoke_test_failure_analysis.R
Rscript tests/smoke_test_experiments.R
Rscript tests/smoke_test_external_labels.R
```

Optional analytical modules require:

```r
install.packages(c("topicmodels", "syuzhet"))
```

Generate the portfolio/reporting outputs with:

```bash
Rscript scripts/render_sample_outputs.R
Rscript scripts/run_challenge_evaluation.R
Rscript scripts/run_failure_analysis.R
Rscript scripts/run_baseline_experiments.R
```

## Repository map

```text
.
├── original/                  # frozen Year 1 reconstruction
├── R/                         # corrected modular implementation
├── data/
│   ├── sample/                # deliberately clear synthetic fixtures
│   ├── evaluation/            # locked synthetic challenge benchmark
│   ├── external-evaluation/   # public schemas + ignored private area
│   └── private/               # ignored private material
├── docs/                      # methodology, audits, decisions, protocols
├── scripts/                   # reproducible reporting/validation runners
├── tests/                     # smoke tests
├── output/                    # generated outputs/artifacts
└── .github/workflows/         # CI
```

## Documentation guide

Start here:

- [`docs/before-vs-after.md`](docs/before-vs-after.md) — concise technical comparison of the Year 1 project and rebuild;
- [`docs/known-problems.md`](docs/known-problems.md) — audit of the historical implementation;
- [`docs/statistical-redesign.md`](docs/statistical-redesign.md) — redesign principles;
- [`docs/classification-baseline.md`](docs/classification-baseline.md) — transparent classifier design;
- [`docs/topic-exploration.md`](docs/topic-exploration.md) — why LDA remains exploratory;
- [`docs/sentiment-analysis.md`](docs/sentiment-analysis.md) — scope of NRC sentiment;
- [`docs/recommendation-engine.md`](docs/recommendation-engine.md) — evidence-based recommendation logic;
- [`docs/evaluation-challenge.md`](docs/evaluation-challenge.md) — locked synthetic benchmark;
- [`docs/failure-analysis.md`](docs/failure-analysis.md) — failure taxonomy and investigation queue;
- [`docs/controlled-experiments.md`](docs/controlled-experiments.md) — experiment protocol;
- [`docs/model-decision-review.md`](docs/model-decision-review.md) — why Variant A was retained;
- [`docs/external-evaluation-protocol.md`](docs/external-evaluation-protocol.md) — requirements for a future unseen test set;
- [`docs/reproducibility.md`](docs/reproducibility.md) — pinned CI reference environment and what remains unpinned.

## Privacy and data governance

The submitted report and original reflection files are not published here by default. The public repository contains reconstruction notes, synthetic fixtures, schemas, and code.

Future real external-evaluation material belongs under the git-ignored `data/external-evaluation/private/` area unless publication rights and consent are clear.

## Current limitations

This repository demonstrates a more disciplined analysis workflow; it does **not** establish that the classifier is production-ready or generally accurate.

Important limitations remain:

- the challenge benchmark is synthetic, self-authored, and used as project validation rather than independent test evidence;
- the retained classifier is a transparent lexical baseline, not contextual language understanding;
- LDA on a small corpus is exploratory and should not be treated as stable latent structure;
- NRC sentiment is lexical description, not psychological inference;
- no independently labelled unseen external dataset has yet been evaluated.

## Next evidence gate

The project should stop tuning against the 12 authored validation cases.

The next substantive step is to collect new reflections, obtain at least two independent first-round annotations per case, resolve disagreements through adjudication, freeze the final labels, and only then evaluate the retained baseline or a future candidate model.

## Historical preservation

This is a retrospective learning repository. The `original/` directory preserves what was attempted at the end of Year 1; corrected code lives separately under `R/` so the learning history is visible rather than overwritten.

## License

Source code and project documentation authored for this repository are released under the [MIT License](LICENSE). This does not grant rights to third-party course materials or private student data; those are not published here by default.
