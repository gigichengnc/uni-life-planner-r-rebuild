# Phase 3: locked synthetic challenge benchmark evaluation
#
# This module evaluates the transparent classifier on a harder, fixed benchmark.
# It does not tune or modify the classifier.

parse_category_set <- function(x) {
  if (length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    return(character())
  }
  values <- trimws(unlist(strsplit(x, "|", fixed = TRUE), use.names = FALSE))
  sort(unique(values[nzchar(values)]))
}

collapse_category_set <- function(x) {
  x <- sort(unique(x[nzchar(x)]))
  paste(x, collapse = " | ")
}

derive_top_categories <- function(scores, reflection_id) {
  required <- c("reflection_id", "category", "score")
  missing <- setdiff(required, names(scores))
  if (length(missing) > 0L) {
    stop("Classification scores are missing required columns: ", paste(missing, collapse = ", "))
  }

  part <- scores[scores$reflection_id == reflection_id, , drop = FALSE]
  if (nrow(part) == 0L) {
    stop("No classification scores found for reflection_id: ", reflection_id)
  }

  top_score <- max(part$score)
  if (top_score <= 0) return(character())
  sort(part$category[part$score == top_score])
}

validate_challenge_labels <- function(labels) {
  required <- c(
    "reflection_id", "benchmark_version", "expected_status", "intended_theme",
    "expected_categories", "challenge_type", "label_rationale"
  )
  missing <- setdiff(required, names(labels))
  if (length(missing) > 0L) {
    stop("Challenge labels are missing required columns: ", paste(missing, collapse = ", "))
  }

  allowed_status <- c("classified", "ambiguous", "unclassified")
  bad_status <- setdiff(unique(labels$expected_status), allowed_status)
  if (length(bad_status) > 0L) {
    stop("Unsupported expected_status values: ", paste(bad_status, collapse = ", "))
  }

  if (anyDuplicated(labels$reflection_id)) {
    stop("Challenge labels must contain unique reflection_id values.")
  }

  invisible(TRUE)
}

evaluate_challenge_benchmark <- function(classification_result, labels) {
  if (!is.list(classification_result) ||
      is.null(classification_result$scores) ||
      is.null(classification_result$predictions)) {
    stop("classification_result must be the output of classify_interest_categories().")
  }

  validate_challenge_labels(labels)
  predictions <- classification_result$predictions
  scores <- classification_result$scores

  prediction_required <- c(
    "reflection_id", "predicted_theme", "status", "top_score",
    "runner_up_score", "margin", "matched_terms"
  )
  missing <- setdiff(prediction_required, names(predictions))
  if (length(missing) > 0L) {
    stop("Predictions are missing required columns: ", paste(missing, collapse = ", "))
  }

  cases <- merge(
    labels,
    predictions,
    by = "reflection_id",
    all.x = TRUE,
    sort = FALSE
  )
  cases <- cases[match(labels$reflection_id, cases$reflection_id), , drop = FALSE]

  if (anyNA(cases$predicted_theme) || anyNA(cases$status)) {
    missing_ids <- cases$reflection_id[is.na(cases$predicted_theme) | is.na(cases$status)]
    stop("Missing predictions for challenge IDs: ", paste(missing_ids, collapse = ", "))
  }

  observed_top <- lapply(cases$reflection_id, function(id) derive_top_categories(scores, id))
  expected_top <- lapply(cases$expected_categories, parse_category_set)

  cases$observed_top_categories <- vapply(observed_top, collapse_category_set, character(1))
  cases$status_correct <- cases$status == cases$expected_status
  cases$theme_correct <- cases$predicted_theme == cases$intended_theme
  cases$top_categories_correct <- vapply(
    seq_len(nrow(cases)),
    function(i) setequal(observed_top[[i]], expected_top[[i]]),
    logical(1)
  )
  cases$decision_correct <-
    cases$status_correct & cases$theme_correct & cases$top_categories_correct

  cases$error_type <- ifelse(
    cases$decision_correct,
    "correct",
    ifelse(
      !cases$status_correct,
      "status_error",
      ifelse(!cases$top_categories_correct, "top_category_error", "theme_error")
    )
  )

  n <- nrow(cases)
  classified_expected <- cases$expected_status == "classified"
  ambiguous_expected <- cases$expected_status == "ambiguous"
  unclassified_expected <- cases$expected_status == "unclassified"

  safe_accuracy <- function(mask) {
    if (!any(mask)) return(NA_real_)
    mean(cases$decision_correct[mask])
  }

  summary <- data.frame(
    benchmark_version = if (n == 0L) NA_character_ else paste(unique(cases$benchmark_version), collapse = "; "),
    n = n,
    n_decision_correct = sum(cases$decision_correct),
    decision_accuracy = if (n == 0L) NA_real_ else mean(cases$decision_correct),
    expected_classified_n = sum(classified_expected),
    single_label_accuracy = safe_accuracy(classified_expected),
    expected_ambiguous_n = sum(ambiguous_expected),
    ambiguity_handling_accuracy = safe_accuracy(ambiguous_expected),
    expected_unclassified_n = sum(unclassified_expected),
    unclassified_handling_accuracy = safe_accuracy(unclassified_expected),
    model_classification_coverage = if (n == 0L) NA_real_ else mean(cases$status == "classified"),
    stringsAsFactors = FALSE
  )

  by_challenge_type <- do.call(
    rbind,
    lapply(split(cases, cases$challenge_type), function(part) {
      data.frame(
        challenge_type = part$challenge_type[1L],
        n = nrow(part),
        n_correct = sum(part$decision_correct),
        accuracy = mean(part$decision_correct),
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(by_challenge_type) <- NULL
  by_challenge_type <- by_challenge_type[order(by_challenge_type$challenge_type), , drop = FALSE]

  failures <- cases[!cases$decision_correct, , drop = FALSE]
  row.names(cases) <- NULL
  row.names(failures) <- NULL

  list(
    summary = summary,
    cases = cases,
    failures = failures,
    by_challenge_type = by_challenge_type
  )
}
