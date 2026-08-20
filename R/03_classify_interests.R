# Phase 2 corrected implementation: transparent interest classification
#
# This module provides a deliberately simple, inspectable baseline for the five
# predefined interest categories. It does NOT use LDA topic numbers as category
# labels. Topic discovery, if retained later, should remain a separate task.

default_category_dictionary <- list(
  "Aesthetics & Spirituality" = c(
    "art", "artistic", "creative", "creativity", "drawing", "culture",
    "cultural", "mindfulness", "meditation", "imagination", "breathing",
    "aesthetic", "wellness", "calm", "journaling"
  ),
  "Future Skills & Intelligence" = c(
    "hackathon", "coding", "code", "digital", "prototype", "technology",
    "technical", "debugging", "innovation", "data", "analysis", "interface",
    "automation", "programming", "software"
  ),
  "Humanity & Love" = c(
    "volunteer", "volunteering", "community", "outreach", "empathy",
    "service", "serving", "families", "support", "helping", "trust",
    "patience", "care", "charity", "needs"
  ),
  "Igniting & Sports" = c(
    "debate", "speaking", "arguments", "competitive", "competition",
    "performance", "pressure", "training", "strategic", "fitness", "sport",
    "sports", "athletic", "practice", "discipline"
  ),
  "Temperance & Justice" = c(
    "policy", "governance", "rules", "fairness", "accountability",
    "committee", "sustainability", "environmental", "stakeholder", "budgets",
    "evidence", "responsible", "decisions", "justice", "compromise"
  )
)

validate_category_dictionary <- function(dictionary) {
  if (!is.list(dictionary) || length(dictionary) == 0L) {
    stop("dictionary must be a non-empty named list.")
  }

  category_names <- names(dictionary)
  if (is.null(category_names) || any(!nzchar(category_names))) {
    stop("Every dictionary category must have a non-empty name.")
  }

  bad <- vapply(dictionary, function(x) {
    !is.character(x) || length(x) == 0L || anyNA(x)
  }, logical(1))

  if (any(bad)) {
    stop(
      "Every dictionary category must contain at least one non-missing character term: ",
      paste(category_names[bad], collapse = ", ")
    )
  }

  invisible(TRUE)
}

normalise_category_dictionary <- function(dictionary) {
  validate_category_dictionary(dictionary)
  lapply(dictionary, function(words) unique(tolower(trimws(words[nzchar(trimws(words))]))))
}

score_interest_categories <- function(
  tokens,
  dictionary = default_category_dictionary,
  score_mode = c("binary", "frequency")
) {
  required <- c("reflection_id", "token")
  missing <- setdiff(required, names(tokens))

  if (length(missing) > 0L) {
    stop("Token data is missing required columns: ", paste(missing, collapse = ", "))
  }

  score_mode <- match.arg(score_mode)
  dictionary <- normalise_category_dictionary(dictionary)
  ids <- unique(tokens$reflection_id)

  if (length(ids) == 0L) {
    return(data.frame(
      reflection_id = character(),
      category = character(),
      score = numeric(),
      matched_terms = character(),
      stringsAsFactors = FALSE
    ))
  }

  rows <- vector("list", length(ids) * length(dictionary))
  row_index <- 1L

  for (reflection_id in ids) {
    reflection_tokens <- tolower(tokens$token[tokens$reflection_id == reflection_id])
    term_counts <- table(reflection_tokens)
    observed_terms <- names(term_counts)

    for (category in names(dictionary)) {
      matched <- sort(intersect(observed_terms, dictionary[[category]]))

      score <- if (score_mode == "binary") {
        length(matched)
      } else if (length(matched) == 0L) {
        0
      } else {
        sum(as.numeric(term_counts[matched]))
      }

      rows[[row_index]] <- data.frame(
        reflection_id = reflection_id,
        category = category,
        score = as.numeric(score),
        matched_terms = paste(matched, collapse = ", "),
        stringsAsFactors = FALSE
      )
      row_index <- row_index + 1L
    }
  }

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

predict_interest_categories <- function(
  scores,
  unclassified_label = "Unclassified",
  ambiguous_label = "Ambiguous"
) {
  required <- c("reflection_id", "category", "score", "matched_terms")
  missing <- setdiff(required, names(scores))

  if (length(missing) > 0L) {
    stop("Score data is missing required columns: ", paste(missing, collapse = ", "))
  }

  ids <- unique(scores$reflection_id)
  if (length(ids) == 0L) {
    return(data.frame(
      reflection_id = character(),
      predicted_theme = character(),
      status = character(),
      top_score = numeric(),
      runner_up_score = numeric(),
      margin = numeric(),
      matched_terms = character(),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(ids, function(reflection_id) {
    part <- scores[scores$reflection_id == reflection_id, , drop = FALSE]
    top_score <- max(part$score)
    top_rows <- part[part$score == top_score, , drop = FALSE]

    runner_up_score <- if (nrow(part) <= 1L) {
      0
    } else {
      sorted_scores <- sort(part$score, decreasing = TRUE)
      sorted_scores[2L]
    }

    if (top_score <= 0) {
      predicted_theme <- unclassified_label
      status <- "unclassified"
      matched_terms <- ""
    } else if (nrow(top_rows) > 1L) {
      predicted_theme <- ambiguous_label
      status <- "ambiguous"
      matched_terms <- paste(
        paste0(top_rows$category, ": ", top_rows$matched_terms),
        collapse = " | "
      )
    } else {
      predicted_theme <- top_rows$category[1L]
      status <- "classified"
      matched_terms <- top_rows$matched_terms[1L]
    }

    data.frame(
      reflection_id = reflection_id,
      predicted_theme = predicted_theme,
      status = status,
      top_score = top_score,
      runner_up_score = runner_up_score,
      margin = top_score - runner_up_score,
      matched_terms = matched_terms,
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

classify_interest_categories <- function(
  tokens,
  dictionary = default_category_dictionary,
  score_mode = c("binary", "frequency")
) {
  score_mode <- match.arg(score_mode)
  scores <- score_interest_categories(
    tokens = tokens,
    dictionary = dictionary,
    score_mode = score_mode
  )

  list(
    scores = scores,
    predictions = predict_interest_categories(scores)
  )
}
