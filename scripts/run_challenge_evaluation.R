# Run the locked synthetic challenge benchmark and write CSV outputs.
#
# Usage:
#   Rscript scripts/run_challenge_evaluation.R
#   Rscript scripts/run_challenge_evaluation.R output/examples/challenge

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

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args) >= 1L) args[1L] else file.path(root, "output", "examples", "challenge")
if (!grepl("^(/|[A-Za-z]:)", output_dir)) output_dir <- file.path(root, output_dir)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

challenge <- load_evaluation_data(root = root)
tokens <- preprocess_reflections(challenge$reflections)
classification <- classify_interest_categories(tokens, score_mode = "binary")
result <- evaluate_challenge_benchmark(classification, challenge$labels)

write.csv(result$summary, file.path(output_dir, "summary.csv"), row.names = FALSE)
write.csv(result$cases, file.path(output_dir, "cases.csv"), row.names = FALSE)
write.csv(result$failures, file.path(output_dir, "failures.csv"), row.names = FALSE)
write.csv(result$by_challenge_type, file.path(output_dir, "by-challenge-type.csv"), row.names = FALSE)

cat("Challenge benchmark outputs written to:", normalizePath(output_dir, winslash = "/", mustWork = TRUE), "\n")
print(result$summary)
