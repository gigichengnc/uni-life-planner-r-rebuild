# Smoke test for the Phase 2 dictionary-classification baseline.
#
# Run with:
#   Rscript tests/smoke_test_classification.R
#
# The synthetic fixtures are intentionally simple and category-distinct. A
# perfect result here checks implementation consistency, not generalisation.

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
source(file.path(root, "R", "04_evaluate.R"))

sample_data <- load_sample_data(root = root)
tokens <- preprocess_reflections(sample_data$reflections)
classification <- classify_interest_categories(tokens, score_mode = "binary")
evaluation <- evaluate_interest_predictions(
  classification$predictions,
  sample_data$manifest
)

stopifnot(nrow(classification$predictions) == 5L)
stopifnot(all(classification$predictions$status == "classified"))
stopifnot(all(classification$predictions$margin > 0))
stopifnot(evaluation$summary$n == 5L)
stopifnot(evaluation$summary$n_classified == 5L)
stopifnot(evaluation$summary$n_correct == 5L)
stopifnot(evaluation$summary$strict_accuracy == 1)
stopifnot(evaluation$summary$coverage == 1)

cat("Phase 2 classification smoke test passed.\n")
print(evaluation$summary)
print(evaluation$confusion_matrix)
