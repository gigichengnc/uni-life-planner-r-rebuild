# Run Phase 5 controlled validation experiments and write CSV outputs.
#
# Usage:
#   Rscript scripts/run_baseline_experiments.R
#   Rscript scripts/run_baseline_experiments.R output/examples/experiments

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

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args) >= 1L) args[1L] else file.path(root, "output", "examples", "experiments")
if (!grepl("^(/|[A-Za-z]:)", output_dir)) output_dir <- file.path(root, output_dir)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

challenge <- load_evaluation_data(root = root)
result <- run_controlled_baseline_experiments(
  reflections = challenge$reflections,
  labels = challenge$labels,
  score_mode = "binary",
  negation_window = 3L,
  calibrated_min_top_score = 2,
  calibrated_ambiguity_margin = 1
)

write.csv(result$settings, file.path(output_dir, "variant-settings.csv"), row.names = FALSE)
write.csv(result$variant_summary, file.path(output_dir, "variant-summary.csv"), row.names = FALSE)
write.csv(result$case_results, file.path(output_dir, "case-results.csv"), row.names = FALSE)
write.csv(result$by_challenge_type, file.path(output_dir, "by-challenge-type.csv"), row.names = FALSE)
write.csv(result$paired_comparison, file.path(output_dir, "paired-comparison.csv"), row.names = FALSE)
write.csv(result$paired_summary, file.path(output_dir, "paired-summary.csv"), row.names = FALSE)

cat("Controlled experiment outputs written to:", normalizePath(output_dir, winslash = "/", mustWork = TRUE), "\n")
print(result$variant_summary)
print(result$paired_summary)
