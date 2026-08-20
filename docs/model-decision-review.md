# Phase 5 Model Decision Review

## Decision

**Retain Variant A — the current transparent dictionary classifier — as the project baseline.**

Variants B and C remain documented experimental alternatives. Neither is promoted into `R/03_classify_interests.R`.

This decision is based on a deterministic re-evaluation of the locked Phase 3 validation benchmark using the repository's current preprocessing, dictionary, and Phase 5 experiment definitions. At the time of this review, a push-triggered GitHub Actions run was not available through the connected GitHub interface, so these numbers should be cross-checked against the R-generated `phase5-controlled-experiments` artifact before being described as runtime-verified.

## Validation summary

| Variant | Description | Correct | Decision accuracy | Classified | Ambiguous | Unclassified | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| A | Current dictionary baseline | 8 / 12 | 66.7% | 10 | 1 | 1 | **Retain baseline** |
| B | A + local three-token negation handling | 8 / 12 | 66.7% | 10 | 1 | 1 | Do not promote |
| C | B + minimum top score 2 + ambiguity margin 1 | 8 / 12 | 66.7% | 6 | 4 | 2 | Do not promote |

The benchmark is synthetic validation data, not an external test set. The percentages above therefore describe behaviour on the locked project benchmark only.

## Variant B review

Variant B produced the same decision as Variant A on all 12 validation cases.

The intended negation challenge, `eval_01`, contains the phrase **“reflective rather than competitive.”** Variant B only recognises the explicit negators `not`, `no`, `never`, and `without`, so its three-token rule does not remove `competitive` in this construction.

The result is useful even though the score did not improve: it falsifies the narrow hypothesis that the current local negator list is sufficient to address the observed negation/context failure.

**Decision:** keep Variant B as an experiment, not as a replacement baseline.

## Variant C review

Variant C changed four decisions relative to A:

| Case | Variant A | Variant C | Effect |
| --- | --- | --- | --- |
| `eval_01` | classified as Igniting & Sports | Unclassified | changed, still incorrect |
| `eval_08` | classified as Igniting & Sports | Ambiguous: Igniting & Sports + Temperance & Justice | changed, still incorrect |
| `eval_11` | correctly classified as Igniting & Sports | Ambiguous: Aesthetics & Spirituality + Igniting & Sports | **regression** |
| `eval_12` | classified as Temperance & Justice | Ambiguous: Humanity & Love + Temperance & Justice | **improvement** |

Paired against Variant A, Variant C therefore gives:

```text
improvements       = 1
regressions        = 1
unchanged correct  = 7
unchanged wrong    = 3
net improvement    = 0
```

The mechanism is also informative:

- `eval_12` shows that a one-point ambiguity margin can correctly preserve genuinely mixed-domain evidence.
- `eval_11` shows the same rule can over-trigger ambiguity when the reflection explicitly indicates a primary preference.
- `eval_08` moves closer to the expected semantic interpretation but still cannot distinguish surface competition vocabulary from the reflection's stated legal/justice purpose.
- `eval_01` shows that stronger abstention cannot recover a category when the dictionary has no positive evidence for the intended aesthetic/reflective theme.

**Decision:** do not promote Variant C. The threshold rule trades one gain for one regression and does not resolve the context or lexical-coverage failures that dominate the remaining errors.

## Why Variant A stays

Variant A is not considered “best” in a general sense. It is retained because:

1. neither intervention improves net validation correctness;
2. B adds logic without changing observed decisions;
3. C changes behaviour substantially without improving total correctness;
4. C introduces a clear regression on a case whose primary intent is explicit;
5. the 12-case benchmark has already been inspected and is now validation data, so further tuning against it would increase overfitting risk;
6. there is not yet enough independently labelled data to justify a supervised or context-aware classifier comparison.

Keeping A preserves the simplest reproducible reference point while the project gathers better evidence.

## Remaining failure themes

The decision review supports the Phase 4 diagnosis that the next bottleneck is not simply the threshold. The unresolved cases point to broader issues:

- lexical coverage and morphology (`gallery`, `sketchbook`, `visual`, `reflective`, `drawings` versus the current dictionary terms);
- phrase and compositional language (`rather than competitive`);
- primary-purpose versus surface-keyword weighting (`eval_08`);
- distinguishing genuine mixed-domain ambiguity from a near-tie with an explicit primary preference (`eval_11` versus `eval_12`).

These are not good reasons to keep adding hand-tuned rules against the same 12 authored cases.

## Next evidence gate

Before another classifier is promoted, create a new independently labelled dataset that is unseen during model design. The labelling protocol should define:

- one primary category where appropriate;
- optional secondary category / multi-label cases;
- explicit `Ambiguous` and `Unclassified` outcomes;
- a short rationale for each label;
- ideally at least two independent annotators for a subset so disagreement can be measured;
- a frozen test split that is not read while tuning future rules or models.

Only after that should the project compare the retained A baseline with phrase-aware rules, improved lexical coverage, or a supervised/context-aware model.

## Reproducibility note

The Phase 5 R experiment remains the canonical executable implementation:

```bash
Rscript scripts/run_baseline_experiments.R
```

The expected review inputs are:

```text
variant-summary.csv
paired-comparison.csv
paired-summary.csv
```

If the future R/CI artifact disagrees with this deterministic review, the R artifact takes precedence and this document should be corrected before any model decision is changed.
