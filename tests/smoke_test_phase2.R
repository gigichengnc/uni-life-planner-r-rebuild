# Minimal Phase 2 smoke test.
# Run with Rscript from any working directory.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) == 0L) {
  stop("Run this test with Rscript so the script path can be detected.")
}

script_path <- sub("^--file=", "", file_arg[1])
script_dir <- dirname(normalizePath(script_path, winslash = "/", mustWork = TRUE))
root <- normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = TRUE)

source(file.path(root, "R", "01_load_data.R"))
source(file.path(root, "R", "02_preprocess.R"))

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
