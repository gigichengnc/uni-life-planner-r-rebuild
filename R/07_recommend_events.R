# Phase 2 corrected implementation: transparent activity recommendation
#
# Recommendations are based on explicit interest-classification evidence and
# activity metadata. Sentiment and LDA topic numbers are intentionally excluded
# from recommendation scoring.

parse_matched_terms <- function(x) {
  if (length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    return(character())
  }

  terms <- trimws(unlist(strsplit(x, ",", fixed = TRUE), use.names = FALSE))
  sort(unique(tolower(terms[nzchar(terms)])))
}

validate_recommendation_inputs <- function(predictions, activities, dictionary) {
  prediction_required <- c(
    "reflection_id", "predicted_theme", "status", "top_score", "margin",
    "matched_terms"
  )
  activity_required <- c("event_id", "title", "category", "description")

  missing_predictions <- setdiff(prediction_required, names(predictions))
  missing_activities <- setdiff(activity_required, names(activities))

  if (length(missing_predictions) > 0L) {
    stop(
      "Prediction data is missing required columns: ",
      paste(missing_predictions, collapse = ", ")
    )
  }

  if (length(missing_activities) > 0L) {
    stop(
      "Activity data is missing required columns: ",
      paste(missing_activities, collapse = ", ")
    )
  }

  if (!exists("tokenize_text", mode = "function")) {
    stop("tokenize_text() is unavailable. Source R/02_preprocess.R first.")
  }

  if (!exists("normalise_category_dictionary", mode = "function")) {
    stop(
      "normalise_category_dictionary() is unavailable. ",
      "Source R/03_classify_interests.R first."
    )
  }

  dictionary <- normalise_category_dictionary(dictionary)

  unknown_categories <- setdiff(unique(activities$category), names(dictionary))
  if (length(unknown_categories) > 0L) {
    stop(
      "Activity data contains categories absent from the dictionary: ",
      paste(unknown_categories, collapse = ", ")
    )
  }

  invisible(TRUE)
}

prepare_activity_features <- function(
  activities,
  dictionary = default_category_dictionary
) {
  validate_recommendation_inputs(
    predictions = data.frame(
      reflection_id = "validation",
      predicted_theme = names(dictionary)[1L],
      status = "classified",
      top_score = 1,
      margin = 1,
      matched_terms = "validation",
      stringsAsFactors = FALSE
    ),
    activities = activities,
    dictionary = dictionary
  )

  dictionary <- normalise_category_dictionary(dictionary)

  rows <- lapply(seq_len(nrow(activities)), function(i) {
    text <- paste(activities$title[i], activities$description[i])
    tokens <- unique(tokenize_text(text))
    category <- activities$category[i]
    category_features <- sort(intersect(tokens, dictionary[[category]]))

    data.frame(
      event_id = activities$event_id[i],
      title = activities$title[i],
      category = category,
      description = activities$description[i],
      feature_terms = paste(category_features, collapse = ", "),
      feature_count = length(category_features),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

recommend_activities <- function(
  predictions,
  activities,
  dictionary = default_category_dictionary,
  top_n = 3L,
  min_top_score = 2,
  min_margin = 1,
  min_shared_evidence = 1L,
  category_weight = 5,
  classifier_score_weight = 0.5,
  evidence_weight = 2
) {
  validate_recommendation_inputs(predictions, activities, dictionary)

  if (length(top_n) != 1L || is.na(top_n) || top_n < 1L) {
    stop("top_n must be a positive integer.")
  }
  if (length(min_top_score) != 1L || is.na(min_top_score) || min_top_score < 0) {
    stop("min_top_score must be a non-negative number.")
  }
  if (length(min_margin) != 1L || is.na(min_margin) || min_margin < 0) {
    stop("min_margin must be a non-negative number.")
  }
  if (
    length(min_shared_evidence) != 1L || is.na(min_shared_evidence) ||
      min_shared_evidence < 0
  ) {
    stop("min_shared_evidence must be a non-negative integer.")
  }

  dictionary <- normalise_category_dictionary(dictionary)
  activity_features <- prepare_activity_features(activities, dictionary)

  recommendation_rows <- list()
  diagnostic_rows <- vector("list", nrow(predictions))
  rec_index <- 1L

  for (i in seq_len(nrow(predictions))) {
    prediction <- predictions[i, , drop = FALSE]
    reflection_id <- prediction$reflection_id
    theme <- prediction$predicted_theme

    eligible <- TRUE
    reason <- "eligible"

    if (!identical(prediction$status, "classified")) {
      eligible <- FALSE
      reason <- paste0("classification_status_", prediction$status)
    } else if (!(theme %in% names(dictionary))) {
      eligible <- FALSE
      reason <- "predicted_theme_not_in_dictionary"
    } else if (prediction$top_score < min_top_score) {
      eligible <- FALSE
      reason <- "classifier_score_below_threshold"
    } else if (prediction$margin < min_margin) {
      eligible <- FALSE
      reason <- "classification_margin_below_threshold"
    }

    candidates <- activity_features[activity_features$category == theme, , drop = FALSE]
    reflection_terms <- parse_matched_terms(prediction$matched_terms)

    if (eligible && nrow(candidates) == 0L) {
      eligible <- FALSE
      reason <- "no_activities_in_predicted_category"
    }

    scored <- NULL
    if (eligible) {
      scored_rows <- lapply(seq_len(nrow(candidates)), function(j) {
        activity_terms <- parse_matched_terms(candidates$feature_terms[j])
        shared_terms <- sort(intersect(reflection_terms, activity_terms))
        shared_count <- length(shared_terms)

        score <-
          category_weight +
          classifier_score_weight * prediction$top_score +
          evidence_weight * shared_count

        data.frame(
          reflection_id = reflection_id,
          event_id = candidates$event_id[j],
          title = candidates$title[j],
          category = candidates$category[j],
          recommendation_score = as.numeric(score),
          classifier_score = as.numeric(prediction$top_score),
          classification_margin = as.numeric(prediction$margin),
          shared_evidence_count = shared_count,
          shared_evidence_terms = paste(shared_terms, collapse = ", "),
          activity_feature_terms = candidates$feature_terms[j],
          reason = paste0(
            "same category; classifier score=", prediction$top_score,
            "; margin=", prediction$margin,
            "; shared evidence=", shared_count
          ),
          stringsAsFactors = FALSE
        )
      })

      scored <- do.call(rbind, scored_rows)
      scored <- scored[
        scored$shared_evidence_count >= as.integer(min_shared_evidence),
        ,
        drop = FALSE
      ]

      if (nrow(scored) == 0L) {
        eligible <- FALSE
        reason <- "no_activity_met_shared_evidence_threshold"
      }
    }

    if (eligible) {
      scored <- scored[
        order(
          -scored$recommendation_score,
          -scored$shared_evidence_count,
          scored$event_id
        ),
        ,
        drop = FALSE
      ]
      scored <- head(scored, as.integer(top_n))
      scored$rank <- seq_len(nrow(scored))
      scored <- scored[, c(
        "reflection_id", "rank", "event_id", "title", "category",
        "recommendation_score", "classifier_score", "classification_margin",
        "shared_evidence_count", "shared_evidence_terms",
        "activity_feature_terms", "reason"
      )]

      recommendation_rows[[rec_index]] <- scored
      rec_index <- rec_index + 1L
    }

    diagnostic_rows[[i]] <- data.frame(
      reflection_id = reflection_id,
      predicted_theme = theme,
      classification_status = prediction$status,
      classifier_score = prediction$top_score,
      classification_margin = prediction$margin,
      recommendation_status = if (eligible) "recommended" else "no_recommendation",
      reason = reason,
      stringsAsFactors = FALSE
    )
  }

  recommendations <- if (length(recommendation_rows) == 0L) {
    data.frame(
      reflection_id = character(),
      rank = integer(),
      event_id = character(),
      title = character(),
      category = character(),
      recommendation_score = numeric(),
      classifier_score = numeric(),
      classification_margin = numeric(),
      shared_evidence_count = integer(),
      shared_evidence_terms = character(),
      activity_feature_terms = character(),
      reason = character(),
      stringsAsFactors = FALSE
    )
  } else {
    do.call(rbind, recommendation_rows)
  }

  diagnostics <- do.call(rbind, diagnostic_rows)
  row.names(recommendations) <- NULL
  row.names(diagnostics) <- NULL

  list(
    recommendations = recommendations,
    diagnostics = diagnostics,
    activity_features = activity_features,
    settings = list(
      top_n = as.integer(top_n),
      min_top_score = min_top_score,
      min_margin = min_margin,
      min_shared_evidence = as.integer(min_shared_evidence),
      category_weight = category_weight,
      classifier_score_weight = classifier_score_weight,
      evidence_weight = evidence_weight,
      sentiment_used = FALSE,
      lda_topic_used = FALSE
    )
  )
}
