# Smoke test for the Phase 2 exploratory corpus-level LDA module.
#
# Run with:
#   Rscript tests/smoke_test_topics.R
#
# This test verifies execution and output structure only. Five synthetic
# documents are not evidence of stable or generalisable latent topics.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)

if (length(script_arg) > 0L) {
  script_path <- normalizePath(
    sub("^--file=", "", script_arg[1L]),
    winslash = "/",
    mustWork = TRUE
  )
  root_guess <- normalizePath(
    file.path(dirname(script_path), ".."),
    winslash = "/",
    mustWork = TRUE
  )
} else {
  root_guess <- getwd()
}

source(file.path(root_guess, "R", "01_load_data.R"))
root <- find_project_root(start = root_guess)

source(file.path(root, "R", "02_preprocess.R"))
source(file.path(root, "R", "05_explore_topics.R"))

sample_data <- load_sample_data(root = root)
tokens <- preprocess_reflections(sample_data$reflections)

topic_result <- suppressWarnings(run_topic_exploration(
  tokens = tokens,
  k = 2L,
  top_n = 5L,
  seed = 1234L,
  warn_small_corpus = TRUE
))

stopifnot(is.matrix(topic_result$dtm))
stopifnot(nrow(topic_result$dtm) == 5L)
stopifnot(inherits(topic_result$model, "LDA"))
stopifnot(nrow(topic_result$top_terms) == 10L)
stopifnot(length(unique(topic_result$top_terms$topic)) == 2L)
stopifnot(nrow(topic_result$document_topics) == 5L)
stopifnot(nrow(topic_result$topic_probabilities) == 10L)
stopifnot(all(grepl("^Topic ", topic_result$document_topics$dominant_topic)))

probability_sums <- tapply(
  topic_result$topic_probabilities$probability,
  topic_result$topic_probabilities$reflection_id,
  sum
)
stopifnot(all(abs(probability_sums - 1) < 1e-8))

cat("Phase 2 topic exploration smoke test passed.\n")
print(topic_result$top_terms)
print(topic_result$document_topics)
