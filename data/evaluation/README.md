# Locked synthetic challenge benchmark

This directory contains **benchmark version `v1-locked-2026-08-20`**.

It is deliberately harder than `data/sample/`. The cases include paraphrases, negation, mixed-domain reflections, an off-domain reflection, and examples where surface keywords can conflict with the intended semantic reading.

## Important status

This is a **synthetic challenge benchmark**, not an independently collected or externally annotated test set. It was authored specifically to probe known weaknesses of the transparent dictionary baseline. Therefore it must not be presented as unbiased evidence of real-world accuracy.

After this version is created, the text and labels are treated as **locked**. Do not rewrite a case merely because a later classifier performs poorly on it. If the benchmark itself needs correction, create a new documented benchmark version rather than silently editing v1.

If a future model is tuned repeatedly against this benchmark, v1 should be treated as validation data from that point onward. A genuinely new unseen test set would then be required for fresh performance claims.

## Structure

```text
evaluation/
├── README.md
├── labels.csv
└── reflections/
    ├── eval_01.txt
    ├── ...
    └── eval_12.txt
```

`labels.csv` records the expected decision (`classified`, `ambiguous`, or `unclassified`), the intended theme where applicable, expected tied categories for ambiguous cases, a challenge type, and a short rationale.
