# Data policy

This repository is public-facing, so the reconstruction uses synthetic data by default.

## `sample/`

Public-safe synthetic examples used to demonstrate and test the corrected pipeline.

Current Phase 2 foundation data:

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

`manifest.csv` gives each synthetic reflection an intended test theme corresponding to the five-category schema preserved from the Year 1 project. These labels are test fixtures, not evidence that the original classification method was accurate.

`activities.csv` is also synthetic. It provides ten example activities, two for each category, so future recommendation logic can be tested without publishing historical announcements.

## `private/`

Original or identifiable student reflections, if retained for private local research. This directory is ignored by Git except for `.gitkeep`.

Do not commit personal student IDs, private contact information, or reflection text whose redistribution rights are unclear.
