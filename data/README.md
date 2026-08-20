# Data policy

This repository is public-facing, so the reconstruction uses synthetic data by default and separates future real evaluation data from public source history.

## `sample/`

Public-safe synthetic examples used to demonstrate and test the corrected Phase 2 pipeline.

```text
sample/
├── activities.csv
├── manifest.csv
└── reflections/
    ├── reflection_01.txt
    ├── reflection_02.txt
    ├── reflection_03.txt
    ├── reflection_04.txt
    └── reflection_05.txt
```

The five reflections were newly written for this repository. They are **not** copied or paraphrased from the original student reflection journals.

`manifest.csv` gives each sample an intended test theme. These deliberately clear fixtures verify pipeline behaviour; they are not evidence of real-world accuracy.

`activities.csv` is also synthetic and provides ten example activities, two for each preserved category.

## `evaluation/`

A harder synthetic challenge benchmark used in Phases 3–5.

```text
evaluation/
├── README.md
├── labels.csv
└── reflections/
    ├── eval_01.txt
    ├── ...
    └── eval_12.txt
```

Benchmark version `v1-locked-2026-08-20` contains paraphrase, negation, mixed-domain, off-domain, and context-over-keyword cases. It was designed to expose weaknesses in the transparent dictionary baseline.

This benchmark is **synthetic and challenge-oriented, not independently collected or externally annotated**. It must not be presented as an unbiased held-out real-world test set.

After creation, v1 is treated as locked. Because Phases 4–5 inspected and experimented against it, it should now be treated as validation data rather than a fresh test set.

## `external-evaluation/`

Phase 6 provides public templates for a future independently labelled unseen evaluation set:

```text
external-evaluation/
├── README.md
├── dataset-register-template.csv
├── annotations-template.csv
├── adjudicated-labels-template.csv
└── private/
    └── .gitkeep
```

The public files are **empty schemas only**. They do not constitute an external dataset.

Real external reflection text, completed annotation exports, and adjudication records should be stored under `external-evaluation/private/`, which is ignored by Git. Follow [`../docs/external-evaluation-protocol.md`](../docs/external-evaluation-protocol.md) before collection or evaluation.

## `private/`

Original or identifiable student reflections, if retained for private local research. This directory is ignored by Git except for `.gitkeep`.

Do not commit personal student IDs, private contact information, annotator identities, or reflection text whose redistribution rights are unclear.
