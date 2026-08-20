# Smoke test for Phase 5 controlled validation experiments.
#
# This verifies experiment wiring and paired comparison structure. It does not
# require any experimental variant to outperform the baseline.

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
source(file.path(root, "R", "11_controlled_experiments.R"))

challenge <- load_evaluation_data(root = root)
result <- run_controlled_baseline_experiments(
  reflections = challenge$reflections,
  labels = challenge$labels,
  score_mode = "binary",
  negation_window = 3L,
  calibrated_min_top_score = 2,
  calibrated_ambiguity_margin = 1
)

stopifnot(identical(result$settings$variant_id, c("A", "B", "C")))
stopifnot(all(result$settings$benchmark_role == "validation"))
stopifnot(all(result$settings$threshold_search_used == FALSE))
stopifnot(all(result$settings$automatic_promotion == FALSE))
stopifnot(result$settings$min_top_score[result$settings$variant_id == "C"] == 2)
stopifnot(result$settings$ambiguity_margin[result$settings$variant_id == "C"] == 1)
stopifnot(result$settings$negation_window[result$settings$variant_id == "B"] == 3L)

stopifnot(nrow(result$variant_summary) == 3L)
stopifnot(nrow(result$case_results) == 36L)
stopifnot(nrow(result$paired_comparison) == 24L)
stopifnot(nrow(result$paired_summary) == 2L)
stopifnot(all(result$variant_summary$decision_accuracy >= 0 & result$variant_summary$decision_accuracy <= 1))
stopifnot(all(result$variant_summary$classification_coverage >= 0 & result$variant_summary$classification_coverage <= 1))

# Variant A must reproduce the existing classifier's status/theme decisions.
tokens <- preprocess_reflections(challenge$reflections)
current <- classify_interest_categories(tokens, score_mode = "binary")$predictions
variant_a <- result$predictions_by_variant$A
current <- current[match(variant_a$reflection_id, current$reflection_id), , drop = FALSE]
stopifnot(identical(as.character(variant_a$status), as.character(current$status)))
stopifnot(identical(as.character(variant_a$predicted_theme), as.character(current$predicted_theme)))
stopifnot(all(variant_a$top_score == current$top_score))
stopifnot(all(variant_a$runner_up_score == current$runner_up_score))

# The benchmark is allowed to expose failures and regressions.
stopifnot(all(result$paired_comparison$outcome %in% c(
  "improved", "regressed", "unchanged_correct", "unchanged_wrong"
)))

cat("Phase 5 controlled baseline experiment smoke test passed.\n")
print(result$variant_summary)
print(result$paired_summary)
