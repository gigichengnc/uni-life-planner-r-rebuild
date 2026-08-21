# Reproducibility reference environment

This repository is a script-based R project rather than an R package. Its reproducibility target is therefore defined through the CI reference environment and executable smoke tests.

## CI reference environment

The GitHub Actions workflow uses:

- Ubuntu 24.04 (`ubuntu-24.04`)
- R 4.6.1
- Posit Public Package Manager CRAN snapshot dated `2026-08-20`
- `topicmodels` 0.2-17
- `syuzhet` 1.0.7
- the Ubuntu `libgsl-dev` system dependency required by `topicmodels`

The dated CRAN snapshot fixes the package repository state used by CI. The workflow also checks the two direct analytical package versions before running the test suite.

## What this does and does not pin

This is stronger than installing from a moving `latest` CRAN repository, but it is not a complete binary or operating-system lock.

In particular:

- there is currently no generated `renv.lock`;
- Ubuntu package versions installed through `apt` are not locked by a container image digest;
- the project is not packaged through `DESCRIPTION` / `NAMESPACE`;
- results that depend on external package behaviour should therefore be interpreted against the documented CI reference environment.

A future `renv.lock` should only be added if it is generated and validated from a real R environment. It should not be hand-written merely to make the repository look pinned.

## Evidence boundary

Reproducibility of the software pipeline is separate from evidence about model performance. Passing CI demonstrates that the documented code paths run consistently in the reference environment; it does not turn the self-authored synthetic validation benchmark into an external accuracy estimate.
