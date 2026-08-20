# Phase 2 corrected implementation: explicit evaluation
#
# The manifest used in this repository contains intended labels for synthetic
# fixtures. These metrics verify pipeline behaviour; they are NOT evidence of
# real-world model accuracy.

evaluate_interest_predictions <- function(predictions, manifest) {
  prediction_required <- c("reflection_id", "predicted_theme", "status")
  manifest_required <- c("reflection_id", "intended_theme")

  missing_predictions <- setdiff(prediction_required, names(predictions))
  missing_manifest <- setdiff(manifest_required, names(manifest))

  if (length(missing_predictions) > 0L) {
    stop(
      "Prediction data is missing required columns: ",
      paste(missing_predictions, collapse = ", ")
    )
  }

  if (length(missing_manifest) > 0L) {
    stop(
      "Manifest data is missing required columns: ",
      paste(missing_manifest, collapse = ", ")
    )
  }

  cases <- merge(
    manifest[, manifest_required, drop = FALSE],
    predictions,
    by = "reflection_id",
    all.x = TRUE,
    sort = FALSE
  )

  if (anyNA(cases$predicted_theme)) {
    missing_ids <- cases$reflection_id[is.na(cases$predicted_theme)]
    stop(
      "Missing predictions for reflection IDs: ",
      paste(missing_ids, collapse = ", ")
    )
  }

  cases$correct <- cases$predicted_theme == cases$intended_theme
  cases$is_classified <- cases$status == "classified"

  n <- nrow(cases)
  n_classified <- sum(cases$is_classified)
  n_correct <- sum(cases$correct)

  strict_accuracy <- if (n == 0L) NA_real_ else n_correct / n
  coverage <- if (n == 0L) NA_real_ else n_classified / n
  classified_accuracy <- if (n_classified == 0L) {
    NA_real_
  } else {
    sum(cases$correct[cases$is_classified]) / n_classified
  }

  confusion <- table(
    expected = cases$intended_theme,
    predicted = cases$predicted_theme,
    useNA = "ifany"
  )

  summary <- data.frame(
    n = n,
    n_classified = n_classified,
    n_correct = n_correct,
    strict_accuracy = strict_accuracy,
    coverage = coverage,
    classified_accuracy = classified_accuracy,
    stringsAsFactors = FALSE
  )

  list(
    summary = summary,
    cases = cases,
    confusion_matrix = confusion
  )
}
