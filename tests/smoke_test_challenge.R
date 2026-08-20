# Smoke test for the locked synthetic challenge benchmark.
#
# This verifies benchmark loading, classifier execution, and evaluation output
# structure. It intentionally does not require a perfect benchmark score.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) > 0L) {
  script_path <- normalizePath(sub("^--file=", "", script_arg[1L]), winslash = "/", mustWork = TRUE)
  root_guess <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
} else {
  root_guess <- getwd()
}

source(file.path(root_guess, "R", "01_load_data.R"))
root <- find_project_root(start = root_guess)
source(file.path(root, "R", "02_preprocess.R"))
source(file.path(root, "R", "03_classify_interests.R"))
source(file.path(root, "R", "09_evaluate_challenge.R"))

challenge <- load_evaluation_data(root = root)
stopifnot(nrow(challenge$reflections) == 12L)
stopifnot(nrow(challenge$labels) == 12L)
stopifnot(setequal(challenge$reflections$reflection_id, challenge$labels$reflection_id))
stopifnot(identical(unique(challenge$labels$benchmark_version), "v1-locked-2026-08-20"))

tokens <- preprocess_reflections(challenge$reflections)
classification <- classify_interest_categories(tokens, score_mode = "binary")
result <- evaluate_challenge_benchmark(classification, challenge$labels)

stopifnot(result$summary$n == 12L)
stopifnot(nrow(result$cases) == 12L)
stopifnot(length(unique(result$cases$challenge_type)) >= 6L)
stopifnot(all(!is.na(result$cases$decision_correct)))
stopifnot(all(result$summary$decision_accuracy >= 0 & result$summary$decision_accuracy <= 1))
stopifnot(all(result$summary$model_classification_coverage >= 0 & result$summary$model_classification_coverage <= 1))
stopifnot(is.data.frame(result$failures))
stopifnot(is.data.frame(result$by_challenge_type))

cat("Phase 3 locked challenge benchmark smoke test passed.\n")
print(result$summary)
print(result$failures[, c("reflection_id", "challenge_type", "expected_status", "intended_theme", "status", "predicted_theme", "error_type"), drop = FALSE])
