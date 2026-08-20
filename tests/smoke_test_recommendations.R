# Smoke test for the Phase 2 activity recommendation engine.
#
# Run with:
#   Rscript tests/smoke_test_recommendations.R

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
source(file.path(root, "R", "07_recommend_events.R"))

sample_data <- load_sample_data(root = root)
tokens <- preprocess_reflections(sample_data$reflections)
classification <- classify_interest_categories(tokens, score_mode = "binary")

recommendation <- recommend_activities(
  predictions = classification$predictions,
  activities = sample_data$activities,
  top_n = 2L
)

stopifnot(nrow(recommendation$diagnostics) == 5L)
stopifnot(all(recommendation$diagnostics$recommendation_status == "recommended"))
stopifnot(nrow(recommendation$recommendations) == 10L)
stopifnot(all(recommendation$recommendations$shared_evidence_count >= 1L))
stopifnot(all(recommendation$recommendations$rank %in% c(1L, 2L)))
stopifnot(identical(recommendation$settings$sentiment_used, FALSE))
stopifnot(identical(recommendation$settings$lda_topic_used, FALSE))

prediction_categories <- setNames(
  classification$predictions$predicted_theme,
  classification$predictions$reflection_id
)

recommended_categories <- prediction_categories[
  recommendation$recommendations$reflection_id
]

stopifnot(all(
  unname(recommended_categories) == recommendation$recommendations$category
))

weak_prediction <- classification$predictions[1L, , drop = FALSE]
weak_prediction$top_score <- 1

weak_result <- recommend_activities(
  predictions = weak_prediction,
  activities = sample_data$activities,
  top_n = 2L
)

stopifnot(nrow(weak_result$recommendations) == 0L)
stopifnot(weak_result$diagnostics$recommendation_status == "no_recommendation")
stopifnot(weak_result$diagnostics$reason == "classifier_score_below_threshold")

cat("Phase 2 recommendation smoke test passed.\n")
print(recommendation$diagnostics)
print(recommendation$recommendations)
