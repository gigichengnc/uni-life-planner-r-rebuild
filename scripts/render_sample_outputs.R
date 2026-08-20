# Render portfolio-friendly sample figures from the synthetic Phase 2 pipeline.
#
# Usage:
#   Rscript scripts/render_sample_outputs.R
#   Rscript scripts/render_sample_outputs.R --output=output/figures/custom

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
source(file.path(root, "R", "05_explore_topics.R"))
source(file.path(root, "R", "06_sentiment.R"))
source(file.path(root, "R", "07_recommend_events.R"))
source(file.path(root, "R", "08_visualise.R"))

args <- commandArgs(trailingOnly = TRUE)
output_arg <- grep("^--output=", args, value = TRUE)
output_dir <- if (length(output_arg) > 0L) {
  sub("^--output=", "", output_arg[1L])
} else {
  file.path("output", "figures", "sample")
}

is_absolute <- grepl("^/|^[A-Za-z]:[/\\\\]", output_dir)
if (!is_absolute) output_dir <- file.path(root, output_dir)

sample_data <- load_sample_data(root = root)
tokens <- preprocess_reflections(sample_data$reflections)
classification <- classify_interest_categories(tokens, score_mode = "binary")

evaluation <- evaluate_interest_predictions(
  classification$predictions,
  sample_data$manifest
)

topic_result <- suppressWarnings(run_topic_exploration(
  tokens = tokens,
  k = 2L,
  top_n = 5L,
  seed = 1234L,
  warn_small_corpus = TRUE
))

sentiment_result <- analyse_nrc_sentiment(sample_data$reflections)

recommendation_result <- recommend_activities(
  predictions = classification$predictions,
  activities = sample_data$activities,
  top_n = 3L
)

figure_paths <- render_analysis_figures(
  classification_result = classification,
  topic_result = topic_result,
  sentiment_result = sentiment_result,
  recommendation_result = recommendation_result,
  output_dir = output_dir
)

cat("Rendered sample figures to:\n")
cat(paste0("- ", unname(figure_paths), collapse = "\n"), "\n")
cat("\nSynthetic classification fixture summary:\n")
print(evaluation$summary)
