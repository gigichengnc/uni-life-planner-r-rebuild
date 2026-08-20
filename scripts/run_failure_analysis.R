# Run Phase 4 failure analysis for the locked synthetic challenge benchmark.
#
# Usage:
#   Rscript scripts/run_failure_analysis.R
#   Rscript scripts/run_failure_analysis.R output/examples/failure-analysis

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

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args) >= 1L) {
  args[1L]
} else {
  file.path(root, "output", "examples", "failure-analysis")
}
if (!grepl("^(/|[A-Za-z]:)", output_dir)) {
  output_dir <- file.path(root, output_dir)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

challenge <- load_evaluation_data(root = root)
tokens <- preprocess_reflections(challenge$reflections)
classification <- classify_interest_categories(tokens, score_mode = "binary")
benchmark <- evaluate_challenge_benchmark(classification, challenge$labels)
analysis <- analyse_challenge_failures(benchmark)

write.csv(
  analysis$benchmark_summary,
  file.path(output_dir, "benchmark-summary.csv"),
  row.names = FALSE
)
write.csv(
  analysis$case_diagnostics,
  file.path(output_dir, "case-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  analysis$failure_register,
  file.path(output_dir, "failure-register.csv"),
  row.names = FALSE
)
write.csv(
  analysis$failure_modes,
  file.path(output_dir, "failure-modes.csv"),
  row.names = FALSE
)
write.csv(
  analysis$failure_families,
  file.path(output_dir, "failure-families.csv"),
  row.names = FALSE
)
write.csv(
  analysis$improvement_queue,
  file.path(output_dir, "improvement-queue.csv"),
  row.names = FALSE
)

cat(
  "Failure-analysis outputs written to:",
  normalizePath(output_dir, winslash = "/", mustWork = TRUE),
  "\n"
)
print(analysis$benchmark_summary)

if (nrow(analysis$failure_register) == 0L) {
  cat("No benchmark decision failures were observed in this run.\n")
} else {
  cat("\nFailure modes:\n")
  print(analysis$failure_modes)
  cat("\nImprovement queue:\n")
  print(analysis$improvement_queue)
}
