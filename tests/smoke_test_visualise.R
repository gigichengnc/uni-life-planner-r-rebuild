# Smoke test for the Phase 2 visualisation layer.
#
# Run with:
#   Rscript tests/smoke_test_visualise.R
#
# The figures use synthetic fixtures only. Successful rendering verifies the
# plotting pipeline, not the substantive validity of the underlying models.

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
source(file.path(root, "R", "05_explore_topics.R"))
source(file.path(root, "R", "06_sentiment.R"))
source(file.path(root, "R", "07_recommend_events.R"))
source(file.path(root, "R", "08_visualise.R"))

sample_data <- load_sample_data(root = root)
tokens <- preprocess_reflections(sample_data$reflections)
classification <- classify_interest_categories(tokens, score_mode = "binary")

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

output_dir <- file.path(root, "output", "figures", "ci")
if (dir.exists(output_dir)) unlink(output_dir, recursive = TRUE, force = TRUE)

figure_paths <- render_analysis_figures(
  classification_result = classification,
  topic_result = topic_result,
  sentiment_result = sentiment_result,
  recommendation_result = recommendation_result,
  output_dir = output_dir
)

stopifnot(length(figure_paths) == 5L)
stopifnot(all(file.exists(figure_paths)))
stopifnot(all(file.info(figure_paths)$size > 1000L))
stopifnot(all(grepl("\\.png$", figure_paths)))

cat("Phase 2 visualisation smoke test passed.\n")
print(figure_paths)
