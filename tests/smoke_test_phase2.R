# Minimal Phase 2 smoke test.
# Run from anywhere inside the repository with:
#   Rscript tests/smoke_test_phase2.R

source(file.path("R", "01_load_data.R"))
source(file.path("R", "02_preprocess.R"))

root <- find_project_root()
sample_data <- load_sample_data(root)

tokens <- preprocess_reflections(sample_data$reflections)
counts <- count_terms(tokens)
dtm <- build_document_term_matrix(tokens)

stopifnot(nrow(sample_data$reflections) == 5L)
stopifnot(nrow(sample_data$manifest) == 5L)
stopifnot(nrow(sample_data$activities) == 10L)
stopifnot(nrow(tokens) > 0L)
stopifnot(nrow(counts) > 0L)
stopifnot(nrow(dtm) == 5L)
stopifnot(!("the" %in% tokens$token))

cat("Phase 2 foundation smoke test passed.\n")
