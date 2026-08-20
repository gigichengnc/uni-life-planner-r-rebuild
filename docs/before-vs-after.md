# Before vs after: Year 1 project to reproducible rebuild

This document summarises the main technical and methodological differences between the reconstructed Year 1 **UNI LIFE PLANNER** implementation and the rebuilt repository.

The goal is not to present the original work as “bad code”. The original project is preserved because it shows the starting point. The rebuild makes the assumptions, evidence, uncertainty, and reproducibility requirements more explicit.

## One-page comparison

| Area | Year 1 implementation | Rebuilt project | Why the change matters |
| --- | --- | --- | --- |
| File paths | Hard-coded local Windows paths | Project-relative loading | The analysis can run outside one computer |
| Code structure | Setup, loading, modelling, plotting, and recommendation mixed in one script | Twelve focused R modules plus runners/tests | Components can be tested and reviewed separately |
| Package setup | Script installed packages during analysis | Dependencies are installed outside analytical functions; CI prepares the environment | Analysis code is less stateful and more reproducible |
| Interest classification | LDA topic index was mapped directly to a predefined category name | Transparent five-category dictionary baseline | A topic number is no longer treated as a category label without evidence |
| Topic modelling | LDA used as part of the category-selection path | LDA is optional corpus-level exploration only | Unsupervised topic discovery remains separate from supervised/rule-based labelling |
| Small-document modelling | LDA could be fitted to tiny individual reflection inputs | Topic modelling uses the corpus and validates minimum input structure | Reduces a major mismatch between LDA assumptions and the original usage |
| Uncertainty | Analysis pushed toward a selected category | `classified`, `ambiguous`, and `unclassified` are explicit outcomes | The system can abstain instead of forcing certainty |
| Evaluation | Human “matchness” was described as accuracy without a formal label protocol | Labels are separate from predictions; evaluation functions compute defined decision outcomes | Performance claims become auditable |
| Synthetic examples | Easy examples could be mistaken for validation | Easy fixtures are explicitly implementation checks | Passing a smoke test is not confused with model accuracy |
| Harder validation | No locked challenge set | A 12-case synthetic challenge benchmark is versioned and locked | Failure cases remain fixed during diagnosis |
| Failure handling | Errors could lead directly to rule changes | Failure taxonomy and investigation queue precede model changes | Reduces reactive benchmark-specific tuning |
| Model comparison | No paired before/after experiment protocol | Pre-declared A/B/C variants with paired improvement/regression analysis | A more complex rule is not promoted just because it sounds better |
| Model decision | No explicit promotion gate | Variant A retained because B adds no benefit and C trades one improvement for one regression | Complexity requires evidence |
| Sentiment | Sentiment was part of the broader interpretation pipeline | NRC sentiment is a separate descriptive output | Sentiment is not treated as personality or category evidence |
| Recommendation | Broad regex matching against LDA top terms | Recommendation requires explicit classification evidence and activity features | Recommendations have a traceable reason |
| Visualisation | Plotting was intertwined with the analysis script | Visualisation is a separate base-R layer | Plots do not silently change modelling logic |
| Testing | No automated regression checks | Smoke tests cover each major module | Later changes can expose breakage quickly |
| CI | No clean-environment execution | GitHub Actions installs dependencies, runs all required checks, and renders artifacts | Reproducibility is tested outside the developer machine |
| Privacy | Publishing original reflections would create privacy/redistribution risk | Real/private text is excluded by default; synthetic fixtures and public schemas are used | Public reproducibility does not require publishing sensitive source material |
| External validation | No independent unseen-test protocol | Two-annotator first round, disagreement/adjudication, freeze, and privacy rules are defined | Future accuracy claims have an evidence gate |

## 1. The most important conceptual correction

The largest methodological change is the separation of **topic discovery** from **interest classification**.

### Year 1 path

The historical implementation used LDA, selected a topic index, and then used that index to choose an entry from the predefined category names.

Conceptually, this behaves like:

```text
LDA Topic 1  -> Category 1
LDA Topic 2  -> Category 2
...
```

But unsupervised topic indices do not arrive with those predefined meanings.

### Rebuilt path

The rebuild separates the tasks:

```text
reflection tokens
      |
      +--> explicit dictionary evidence --> interest classification
      |
      +--> corpus DTM --> LDA --> anonymous exploratory topics
```

The classifier and LDA can both analyse the same corpus, but they answer different questions.

## 2. From forced decisions to explicit uncertainty

The rebuilt classifier does not assume that every reflection must have one confident category.

Possible statuses are:

```text
classified
ambiguous
unclassified
```

This matters because a transparent baseline should expose when evidence is weak or tied rather than hide that uncertainty behind one output label.

## 3. From “does it look right?” to defined evaluation

The rebuild separates:

```text
prediction
    !=
reference label
    !=
evaluation metric
```

The clear sample fixtures are deliberately easy and primarily test whether the implementation is wired correctly.

A second, harder synthetic benchmark was then frozen as `v1-locked-2026-08-20`. It includes paraphrase, negation/context, mixed-domain, off-domain, and purpose-versus-surface-keyword cases.

Because that benchmark has already informed model-development decisions, it is now treated as **validation data**, not as an untouched external test set.

## 4. Failure analysis before model escalation

Instead of immediately expanding the dictionary after every wrong case, the rebuild records failure hypotheses such as:

- negation/context blindness;
- paraphrase or lexical coverage gaps;
- surface keyword dominance;
- mixed-domain forced decisions;
- off-domain false positives;
- purpose-versus-surface-signal conflicts.

These diagnoses are investigation aids, not proof of a causal mechanism.

The point is to decide whether a failure justifies a general modelling change or merely reveals a limitation that should be documented.

## 5. Controlled experiments and the decision to keep the simpler baseline

Three pre-declared variants were compared on the locked validation benchmark:

```text
A  current dictionary baseline
B  A + local three-token negation handling
C  B + minimum top score 2 + ambiguity margin 1
```

Repository definitions reproduce:

```text
A: 8/12
B: 8/12
C: 8/12
```

The aggregate totals are the same, but the paired behaviour is different:

- B changes no benchmark decisions;
- C fixes one previously wrong case;
- C also breaks one previously correct case.

The project therefore retains **Variant A**.

This is a deliberate model-development lesson: a more complicated rule is not automatically a better baseline.

## 6. Reproducibility became part of the project, not an afterthought

The rebuilt project includes:

- project-relative paths;
- synthetic public fixtures;
- modular R functions;
- smoke tests;
- reproducible runner scripts;
- GitHub Actions;
- CI dependency checks, including the Ubuntu GSL dependency required by `topicmodels`;
- artifact generation for figures and evaluation tables.

A clean-environment failure in the topic-modelling test also became part of the reconstruction process: the workflow initially installed the R package but could not load its namespace correctly in CI. The workflow was repaired to install the required system dependency, verify package loading explicitly, continue running independent tests, and fail only after reporting the full check matrix.

That incident is useful evidence for why clean-environment CI matters.

## 7. What the rebuild still does **not** prove

The rebuild improves the analysis process, but several claims remain unsupported:

- the dictionary classifier is not proven accurate on real students;
- 8/12 on an authored synthetic challenge benchmark is not external accuracy;
- LDA results on a small corpus are not stable evidence of latent student-interest structure;
- NRC sentiment is not a psychological assessment;
- the recommendation engine is an explainable baseline, not a validated recommender system;
- independent unseen external evaluation has not yet been completed.

These are intentionally left visible rather than replaced with stronger claims than the evidence supports.

## 8. The next evidence gate

The next meaningful step is not another benchmark-specific rule.

It is:

```text
new reflections
      ↓
2+ independent first-round annotators
      ↓
measure exact agreement
      ↓
adjudicate disagreements
      ↓
freeze final labels + dataset version
      ↓
run the retained baseline once
      ↓
report external performance honestly
```

The public templates and validator for that process live under `data/external-evaluation/` and `R/12_validate_external_labels.R`.

## What this project now demonstrates

The strongest portfolio story is not that the Year 1 classifier became highly accurate.

It is that one early text-analytics project was revisited and turned into a reproducible model-development case study:

```text
original implementation
      ↓
audit assumptions
      ↓
separate analytical tasks
      ↓
build a transparent baseline
      ↓
define evaluation
      ↓
lock harder cases
      ↓
study failures
      ↓
compare controlled variants
      ↓
reject unsupported complexity
      ↓
define the next external evidence gate
```

That progression is the main result of the rebuild.
