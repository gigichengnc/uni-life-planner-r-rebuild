# Data policy

This repository is public-facing, so the reconstruction uses synthetic data by default.

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

A harder synthetic challenge benchmark used in Phase 3.

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

After creation, v1 is treated as locked: do not rewrite cases merely to improve classifier results. If future model development repeatedly uses these results, v1 becomes validation data and a new unseen test set is required for fresh performance claims. See [`evaluation/README.md`](evaluation/README.md).

## `private/`

Original or identifiable student reflections, if retained for private local research. This directory is ignored by Git except for `.gitkeep`.

Do not commit personal student IDs, private contact information, or reflection text whose redistribution rights are unclear.
