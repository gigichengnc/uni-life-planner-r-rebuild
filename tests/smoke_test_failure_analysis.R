# Smoke test for Phase 4 failure analysis.
#
# The test verifies diagnosis/reporting structure. It intentionally does NOT
# require the locked benchmark to have either zero failures or a specific score.

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
source(file.path(root, "R", "03_classify_interests.R"))
source(file.path(root, "R", "09_evaluate_challenge.R"))
source(file.path(root, "R", "10_analyse_failures.R"))

challenge <- load_evaluation_data(root = root)
tokens <- preprocess_reflections(challenge$reflections)
classification <- classify_interest_categories(tokens, score_mode = "binary")
benchmark <- evaluate_challenge_benchmark(classification, challenge$labels)
analysis <- analyse_challenge_failures(benchmark)

stopifnot(nrow(analysis$case_diagnostics) == 12L)
stopifnot(nrow(analysis$failure_register) == sum(!benchmark$cases$decision_correct))
stopifnot(all(analysis$case_diagnostics$decision_correct == (analysis$case_diagnostics$failure_mode == "correct")))
stopifnot(all(analysis$failure_register$failure_mode != "correct"))
stopifnot(all(!is.na(analysis$case_diagnostics$diagnostic_family)))
stopifnot(all(!is.na(analysis$case_diagnostics$suggested_next_step)))
stopifnot(all(analysis$case_diagnostics$priority %in% c("P0", "P1", "P2", "P3")))
stopifnot(all(analysis$catalog$failure_mode == unique(analysis$catalog$failure_mode)))

if (nrow(analysis$failure_register) > 0L) {
  stopifnot(sum(analysis$failure_modes$n) == nrow(analysis$failure_register))
  stopifnot(sum(analysis$failure_families$n) == nrow(analysis$failure_register))
  stopifnot(nrow(analysis$improvement_queue) == nrow(analysis$failure_modes))
}

# Taxonomy probes ensure the diagnostic rules remain explicit even if the
# benchmark's future baseline happens to produce a different number of errors.
probe_off_domain <- data.frame(
  decision_correct = FALSE,
  expected_status = "unclassified",
  status = "classified",
  challenge_type = "off_domain",
  top_score = 2,
  top_categories_correct = FALSE,
  theme_correct = FALSE,
  stringsAsFactors = FALSE
)
probe_negation <- data.frame(
  decision_correct = FALSE,
  expected_status = "classified",
  status = "classified",
  challenge_type = "negation_context",
  top_score = 3,
  top_categories_correct = FALSE,
  theme_correct = FALSE,
  stringsAsFactors = FALSE
)
probe_ambiguity <- data.frame(
  decision_correct = FALSE,
  expected_status = "ambiguous",
  status = "classified",
  challenge_type = "mixed_equal",
  top_score = 3,
  top_categories_correct = FALSE,
  theme_correct = FALSE,
  stringsAsFactors = FALSE
)

stopifnot(identical(diagnose_failure_mode(probe_off_domain), "off_domain_false_positive"))
stopifnot(identical(diagnose_failure_mode(probe_negation), "negation_blindness"))
stopifnot(identical(diagnose_failure_mode(probe_ambiguity), "mixed_signal_forced_single_label"))

cat("Phase 4 failure-analysis smoke test passed.\n")
print(analysis$benchmark_summary)
print(analysis$failure_modes)
