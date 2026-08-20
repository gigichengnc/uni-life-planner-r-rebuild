# Phase 5: controlled baseline experiments on the locked validation benchmark
#
# These experiments compare small, pre-declared changes with the unchanged
# dictionary baseline. The locked benchmark is treated as validation data here,
# not as a fresh external test set. Predictions never consume benchmark labels.

experiment_category_set <- function(x) {
  if (length(x) != 1L || is.na(x) || !nzchar(trimws(x))) return(character())
  values <- trimws(unlist(strsplit(x, "|", fixed = TRUE), use.names = FALSE))
  sort(unique(values[nzchar(values)]))
}

collapse_experiment_categories <- function(x) {
  x <- sort(unique(x[nzchar(x)]))
  paste(x, collapse = " | ")
}

score_interest_categories_negation_aware <- function(
  tokens,
  dictionary = default_category_dictionary,
  score_mode = c("binary", "frequency"),
  negators = c("not", "no", "never", "without"),
  negation_window = 3L
) {
  required <- c("reflection_id", "token")
  missing <- setdiff(required, names(tokens))
  if (length(missing) > 0L) {
    stop("Token data is missing required columns: ", paste(missing, collapse = ", "))
  }
  if (!exists("normalise_category_dictionary", mode = "function")) {
    stop("normalise_category_dictionary() is unavailable. Source R/03_classify_interests.R first.")
  }
  if (length(negation_window) != 1L || is.na(negation_window) || negation_window < 1L) {
    stop("negation_window must be a positive integer.")
  }

  score_mode <- match.arg(score_mode)
  dictionary <- normalise_category_dictionary(dictionary)
  negators <- unique(tolower(trimws(negators[nzchar(trimws(negators))])))
  ids <- unique(tokens$reflection_id)

  if (length(ids) == 0L) {
    return(data.frame(
      reflection_id = character(), category = character(), score = numeric(),
      matched_terms = character(), ignored_negated_terms = character(),
      stringsAsFactors = FALSE
    ))
  }

  rows <- vector("list", length(ids) * length(dictionary))
  row_index <- 1L

  for (reflection_id in ids) {
    reflection_tokens <- tolower(tokens$token[tokens$reflection_id == reflection_id])
    n_tokens <- length(reflection_tokens)

    negated <- vapply(seq_len(n_tokens), function(i) {
      start <- max(1L, i - as.integer(negation_window))
      if (start >= i) return(FALSE)
      any(reflection_tokens[start:(i - 1L)] %in% negators)
    }, logical(1))

    for (category in names(dictionary)) {
      positions <- which(reflection_tokens %in% dictionary[[category]])
      kept_positions <- positions[!negated[positions]]
      ignored_positions <- positions[negated[positions]]

      matched <- sort(unique(reflection_tokens[kept_positions]))
      ignored <- sort(unique(reflection_tokens[ignored_positions]))

      score <- if (score_mode == "binary") {
        length(matched)
      } else {
        length(kept_positions)
      }

      rows[[row_index]] <- data.frame(
        reflection_id = reflection_id,
        category = category,
        score = as.numeric(score),
        matched_terms = paste(matched, collapse = ", "),
        ignored_negated_terms = paste(ignored, collapse = ", "),
        stringsAsFactors = FALSE
      )
      row_index <- row_index + 1L
    }
  }

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

predict_experiment_decisions <- function(
  scores,
  min_top_score = 1,
  ambiguity_margin = 0,
  unclassified_label = "Unclassified",
  ambiguous_label = "Ambiguous"
) {
  required <- c("reflection_id", "category", "score", "matched_terms")
  missing <- setdiff(required, names(scores))
  if (length(missing) > 0L) {
    stop("Score data is missing required columns: ", paste(missing, collapse = ", "))
  }
  if (length(min_top_score) != 1L || is.na(min_top_score) || min_top_score < 0) {
    stop("min_top_score must be one non-negative number.")
  }
  if (length(ambiguity_margin) != 1L || is.na(ambiguity_margin) || ambiguity_margin < 0) {
    stop("ambiguity_margin must be one non-negative number.")
  }

  ids <- unique(scores$reflection_id)
  if (length(ids) == 0L) {
    return(data.frame(
      reflection_id = character(), predicted_theme = character(), status = character(),
      predicted_categories = character(), top_score = numeric(),
      runner_up_score = numeric(), margin = numeric(), matched_terms = character(),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(ids, function(reflection_id) {
    part <- scores[scores$reflection_id == reflection_id, , drop = FALSE]
    top_score <- max(part$score)
    ordered_scores <- sort(part$score, decreasing = TRUE)
    runner_up_score <- if (length(ordered_scores) >= 2L) ordered_scores[2L] else 0
    margin <- top_score - runner_up_score

    if (top_score < min_top_score || top_score <= 0) {
      predicted_theme <- unclassified_label
      status <- "unclassified"
      predicted_categories <- ""
      evidence <- ""
    } else {
      contenders <- part[
        part$score > 0 & (top_score - part$score) <= ambiguity_margin,
        , drop = FALSE
      ]
      contenders <- contenders[order(contenders$category), , drop = FALSE]
      contender_categories <- contenders$category
      predicted_categories <- collapse_experiment_categories(contender_categories)

      if (length(contender_categories) > 1L) {
        predicted_theme <- ambiguous_label
        status <- "ambiguous"
        evidence <- paste(
          paste0(contenders$category, ": ", contenders$matched_terms),
          collapse = " | "
        )
      } else {
        predicted_theme <- contender_categories[1L]
        status <- "classified"
        evidence <- contenders$matched_terms[1L]
      }
    }

    data.frame(
      reflection_id = reflection_id,
      predicted_theme = predicted_theme,
      status = status,
      predicted_categories = predicted_categories,
      top_score = as.numeric(top_score),
      runner_up_score = as.numeric(runner_up_score),
      margin = as.numeric(margin),
      matched_terms = evidence,
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

evaluate_experiment_decisions <- function(predictions, labels, variant_id, variant_name) {
  prediction_required <- c(
    "reflection_id", "predicted_theme", "status", "predicted_categories",
    "top_score", "runner_up_score", "margin", "matched_terms"
  )
  label_required <- c(
    "reflection_id", "benchmark_version", "expected_status", "intended_theme",
    "expected_categories", "challenge_type", "label_rationale"
  )

  missing_predictions <- setdiff(prediction_required, names(predictions))
  missing_labels <- setdiff(label_required, names(labels))
  if (length(missing_predictions) > 0L) {
    stop("Predictions are missing required columns: ", paste(missing_predictions, collapse = ", "))
  }
  if (length(missing_labels) > 0L) {
    stop("Labels are missing required columns: ", paste(missing_labels, collapse = ", "))
  }

  cases <- merge(labels, predictions, by = "reflection_id", all.x = TRUE, sort = FALSE)
  cases <- cases[match(labels$reflection_id, cases$reflection_id), , drop = FALSE]
  if (anyNA(cases$predicted_theme) || anyNA(cases$status)) {
    bad <- cases$reflection_id[is.na(cases$predicted_theme) | is.na(cases$status)]
    stop("Missing experiment predictions for: ", paste(bad, collapse = ", "))
  }

  expected_sets <- lapply(cases$expected_categories, experiment_category_set)
  observed_sets <- lapply(cases$predicted_categories, function(x) {
    if (is.na(x) || !nzchar(trimws(x))) return(character())
    sort(unique(trimws(unlist(strsplit(x, "|", fixed = TRUE), use.names = FALSE))))
  })

  cases$status_correct <- cases$status == cases$expected_status
  cases$theme_correct <- cases$predicted_theme == cases$intended_theme
  cases$category_set_correct <- vapply(
    seq_len(nrow(cases)),
    function(i) setequal(expected_sets[[i]], observed_sets[[i]]),
    logical(1)
  )
  cases$decision_correct <-
    cases$status_correct & cases$theme_correct & cases$category_set_correct
  cases$variant_id <- variant_id
  cases$variant_name <- variant_name

  n <- nrow(cases)
  summary <- data.frame(
    variant_id = variant_id,
    variant_name = variant_name,
    benchmark_version = if (n == 0L) NA_character_ else paste(unique(cases$benchmark_version), collapse = "; "),
    n = n,
    n_correct = sum(cases$decision_correct),
    decision_accuracy = if (n == 0L) NA_real_ else mean(cases$decision_correct),
    classified_n = sum(cases$status == "classified"),
    ambiguous_n = sum(cases$status == "ambiguous"),
    unclassified_n = sum(cases$status == "unclassified"),
    classification_coverage = if (n == 0L) NA_real_ else mean(cases$status == "classified"),
    stringsAsFactors = FALSE
  )

  by_type <- do.call(rbind, lapply(split(cases, cases$challenge_type), function(part) {
    data.frame(
      variant_id = variant_id,
      variant_name = variant_name,
      challenge_type = part$challenge_type[1L],
      n = nrow(part),
      n_correct = sum(part$decision_correct),
      accuracy = mean(part$decision_correct),
      stringsAsFactors = FALSE
    )
  }))
  row.names(cases) <- NULL
  row.names(by_type) <- NULL

  list(summary = summary, cases = cases, by_challenge_type = by_type)
}

compare_variant_to_baseline <- function(baseline_cases, variant_cases) {
  required <- c(
    "reflection_id", "decision_correct", "status", "predicted_theme",
    "predicted_categories"
  )
  if (length(setdiff(required, names(baseline_cases))) > 0L ||
      length(setdiff(required, names(variant_cases))) > 0L) {
    stop("Case tables do not contain the columns required for paired comparison.")
  }

  baseline <- baseline_cases[, required, drop = FALSE]
  names(baseline)[-1L] <- paste0("baseline_", names(baseline)[-1L])
  variant <- variant_cases[, c(required, "variant_id", "variant_name"), drop = FALSE]
  names(variant)[2:5] <- paste0("variant_", names(variant)[2:5])

  paired <- merge(baseline, variant, by = "reflection_id", all = FALSE, sort = FALSE)
  paired$outcome <- ifelse(
    !paired$baseline_decision_correct & paired$variant_decision_correct,
    "improved",
    ifelse(
      paired$baseline_decision_correct & !paired$variant_decision_correct,
      "regressed",
      ifelse(paired$baseline_decision_correct, "unchanged_correct", "unchanged_wrong")
    )
  )
  paired$delta_correct <- as.integer(paired$variant_decision_correct) - as.integer(paired$baseline_decision_correct)
  paired
}

run_controlled_baseline_experiments <- function(
  reflections,
  labels,
  dictionary = default_category_dictionary,
  score_mode = c("binary", "frequency"),
  negation_window = 3L,
  calibrated_min_top_score = 2,
  calibrated_ambiguity_margin = 1
) {
  if (!exists("preprocess_reflections", mode = "function")) {
    stop("preprocess_reflections() is unavailable. Source R/02_preprocess.R first.")
  }
  if (!exists("score_interest_categories", mode = "function")) {
    stop("score_interest_categories() is unavailable. Source R/03_classify_interests.R first.")
  }

  score_mode <- match.arg(score_mode)
  tokens <- preprocess_reflections(reflections)

  settings <- data.frame(
    variant_id = c("A", "B", "C"),
    variant_name = c(
      "Current dictionary baseline",
      "Negation-aware dictionary",
      "Negation + calibrated ambiguity/abstention"
    ),
    scoring = c("current_dictionary", "negation_aware", "negation_aware"),
    negation_window = c(NA_integer_, as.integer(negation_window), as.integer(negation_window)),
    min_top_score = c(1, 1, calibrated_min_top_score),
    ambiguity_margin = c(0, 0, calibrated_ambiguity_margin),
    benchmark_role = "validation",
    threshold_search_used = FALSE,
    automatic_promotion = FALSE,
    stringsAsFactors = FALSE
  )

  scores_a <- score_interest_categories(tokens, dictionary = dictionary, score_mode = score_mode)
  scores_b <- score_interest_categories_negation_aware(
    tokens,
    dictionary = dictionary,
    score_mode = score_mode,
    negation_window = negation_window
  )
  scores_c <- scores_b

  scores_by_variant <- list(A = scores_a, B = scores_b, C = scores_c)
  predictions_by_variant <- list(
    A = predict_experiment_decisions(scores_a, min_top_score = 1, ambiguity_margin = 0),
    B = predict_experiment_decisions(scores_b, min_top_score = 1, ambiguity_margin = 0),
    C = predict_experiment_decisions(
      scores_c,
      min_top_score = calibrated_min_top_score,
      ambiguity_margin = calibrated_ambiguity_margin
    )
  )

  evaluations <- lapply(seq_len(nrow(settings)), function(i) {
    id <- settings$variant_id[i]
    evaluate_experiment_decisions(
      predictions_by_variant[[id]],
      labels,
      variant_id = id,
      variant_name = settings$variant_name[i]
    )
  })
  names(evaluations) <- settings$variant_id

  variant_summary <- do.call(rbind, lapply(evaluations, `[[`, "summary"))
  case_results <- do.call(rbind, lapply(evaluations, `[[`, "cases"))
  by_challenge_type <- do.call(rbind, lapply(evaluations, `[[`, "by_challenge_type"))
  row.names(variant_summary) <- NULL
  row.names(case_results) <- NULL
  row.names(by_challenge_type) <- NULL

  baseline_accuracy <- variant_summary$decision_accuracy[variant_summary$variant_id == "A"][1L]
  variant_summary$delta_vs_A <- variant_summary$decision_accuracy - baseline_accuracy

  paired_list <- lapply(c("B", "C"), function(id) {
    compare_variant_to_baseline(evaluations$A$cases, evaluations[[id]]$cases)
  })
  paired_comparison <- do.call(rbind, paired_list)
  row.names(paired_comparison) <- NULL

  paired_summary <- do.call(rbind, lapply(split(paired_comparison, paired_comparison$variant_id), function(part) {
    data.frame(
      variant_id = part$variant_id[1L],
      variant_name = part$variant_name[1L],
      improvements = sum(part$outcome == "improved"),
      regressions = sum(part$outcome == "regressed"),
      unchanged_correct = sum(part$outcome == "unchanged_correct"),
      unchanged_wrong = sum(part$outcome == "unchanged_wrong"),
      net_improvement = sum(part$delta_correct),
      stringsAsFactors = FALSE
    )
  }))
  row.names(paired_summary) <- NULL

  list(
    settings = settings,
    scores_by_variant = scores_by_variant,
    predictions_by_variant = predictions_by_variant,
    evaluations = evaluations,
    variant_summary = variant_summary,
    case_results = case_results,
    by_challenge_type = by_challenge_type,
    paired_comparison = paired_comparison,
    paired_summary = paired_summary
  )
}
