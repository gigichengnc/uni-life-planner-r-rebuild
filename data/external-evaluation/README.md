# External evaluation workspace

This directory contains **public schema templates only** for a future independently labelled unseen evaluation set.

It does not currently contain a real external test dataset.

## Public files

- `dataset-register-template.csv` — process registry for unseen-test provenance and release status.
- `annotations-template.csv` — one row per independent annotator decision.
- `adjudicated-labels-template.csv` — one frozen final label per reflection after disagreements are resolved.

## Private files

Place real reflection text, completed annotation exports, and adjudication records under:

```text
private/
```

The folder contents are ignored by Git except for `.gitkeep`.

Do not publish reflection text or annotator/source identifiers merely because they are useful for evaluation. Confirm anonymisation, consent, and redistribution rights separately.

## Protocol

Follow [`../../docs/external-evaluation-protocol.md`](../../docs/external-evaluation-protocol.md) before collecting or evaluating new labels.

A dataset is not genuinely unseen if its cases have already been used to design model rules, dictionaries, thresholds, or failure-handling logic.
