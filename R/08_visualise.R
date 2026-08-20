# Phase 2 corrected implementation: interpretable visualisation
#
# These plots display already-computed analytical outputs. They do not add new
# modelling logic or change classification, topic, sentiment, or recommendation
# decisions.

visual_sentiment_dimensions <- c(
  "anger", "anticipation", "disgust", "fear", "joy",
  "sadness", "surprise", "trust", "negative", "positive"
)

require_columns <- function(data, required, object_name = "data") {
  if (!is.data.frame(data)) {
    stop(object_name, " must be a data.frame.")
  }
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(object_name, " is missing required columns: ", paste(missing, collapse = ", "))
  }
  invisible(TRUE)
}

open_png_device <- function(output_file, width = 1400L, height = 900L, res = 140L) {
  if (length(output_file) != 1L || is.na(output_file) || !nzchar(trimws(output_file))) {
    stop("A non-empty output file path is required.")
  }

  directory <- dirname(output_file)
  if (!dir.exists(directory)) {
    dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(directory)) {
    stop("Could not create output directory: ", directory)
  }

  grDevices::png(
    filename = output_file,
    width = as.integer(width),
    height = as.integer(height),
    res = as.integer(res)
  )
  output_file
}

plot_classification_scores <- function(scores, output_file) {
  require_columns(scores, c("reflection_id", "category", "score"), "classification scores")
  if (nrow(scores) == 0L) stop("classification scores must contain at least one row.")

  score_matrix <- stats::xtabs(score ~ category + reflection_id, data = scores)
  path <- open_png_device(output_file)
  on.exit(grDevices::dev.off())

  graphics::par(mar = c(9, 5, 4, 2) + 0.1)
  graphics::barplot(
    score_matrix,
    beside = TRUE,
    names.arg = colnames(score_matrix),
    las = 2,
    ylab = "Distinct dictionary terms matched",
    main = "Interest classification scores",
    cex.names = 0.85
  )
  graphics::legend("topright", legend = rownames(score_matrix), bty = "n", cex = 0.78)
  graphics::mtext(
    "Transparent dictionary baseline; scores are evidence counts, not probabilities.",
    side = 3, line = 0.25, cex = 0.75
  )

  invisible(path)
}

plot_classification_confidence <- function(predictions, output_file) {
  require_columns(
    predictions,
    c("reflection_id", "top_score", "runner_up_score", "margin"),
    "classification predictions"
  )
  if (nrow(predictions) == 0L) stop("classification predictions must contain at least one row.")

  values <- rbind(
    top_score = as.numeric(predictions$top_score),
    runner_up = as.numeric(predictions$runner_up_score)
  )

  path <- open_png_device(output_file)
  on.exit(grDevices::dev.off())

  graphics::par(mar = c(9, 5, 4, 2) + 0.1)
  positions <- graphics::barplot(
    values,
    beside = TRUE,
    names.arg = predictions$reflection_id,
    las = 2,
    ylab = "Dictionary score",
    main = "Classification evidence: top vs runner-up",
    cex.names = 0.85
  )
  graphics::legend("topright", legend = c("Top score", "Runner-up score"), bty = "n", cex = 0.82)

  group_x <- colMeans(positions)
  group_y <- pmax(values[1L, ], values[2L, ])
  offset <- max(c(group_y, 1), na.rm = TRUE) * 0.05
  graphics::text(
    group_x,
    group_y + offset,
    labels = paste0("margin=", format(predictions$margin, trim = TRUE)),
    cex = 0.72,
    xpd = TRUE
  )
  graphics::mtext(
    "Margin = top score - runner-up score; larger separation means clearer dictionary evidence.",
    side = 3, line = 0.25, cex = 0.72
  )

  invisible(path)
}

plot_topic_terms <- function(topic_result, output_file) {
  if (!is.list(topic_result) || is.null(topic_result$model) || is.null(topic_result$top_terms)) {
    stop("topic_result must be the output of run_topic_exploration().")
  }
  require_columns(topic_result$top_terms, c("topic", "rank", "term"), "topic_result$top_terms")
  if (!requireNamespace("topicmodels", quietly = TRUE)) {
    stop("Package 'topicmodels' is required to plot topic-term probabilities.")
  }

  top_terms <- topic_result$top_terms
  term_probabilities <- topicmodels::posterior(topic_result$model)$terms
  topic_index <- suppressWarnings(as.integer(sub("^Topic ", "", top_terms$topic)))
  if (anyNA(topic_index)) stop("Topic labels must use the form 'Topic N'.")

  probability <- vapply(seq_len(nrow(top_terms)), function(i) {
    term <- top_terms$term[i]
    topic <- topic_index[i]
    if (topic < 1L || topic > nrow(term_probabilities) || !(term %in% colnames(term_probabilities))) {
      return(NA_real_)
    }
    as.numeric(term_probabilities[topic, term])
  }, numeric(1))

  keep <- is.finite(probability)
  if (!any(keep)) stop("No topic-term probabilities could be matched for plotting.")

  plot_data <- top_terms[keep, , drop = FALSE]
  plot_data$probability <- probability[keep]
  plot_data$topic_index <- topic_index[keep]
  plot_data <- plot_data[order(plot_data$topic_index, plot_data$rank), , drop = FALSE]
  labels <- paste0(plot_data$topic, " · ", plot_data$term)

  path <- open_png_device(output_file, width = 1500L, height = 1000L)
  on.exit(grDevices::dev.off())

  graphics::par(mar = c(5, 12, 4, 2) + 0.1)
  graphics::barplot(
    rev(plot_data$probability),
    names.arg = rev(labels),
    horiz = TRUE,
    las = 1,
    xlab = "Posterior term probability within topic",
    main = "Exploratory LDA topic terms",
    cex.names = 0.75
  )
  graphics::mtext(
    "Topics remain neutral exploratory labels; they are not interest categories.",
    side = 3, line = 0.25, cex = 0.75
  )

  invisible(path)
}

plot_sentiment_rates <- function(sentiment_result, output_file, reflection_id = NULL) {
  if (!is.list(sentiment_result) || is.null(sentiment_result$rates) || is.null(sentiment_result$rate_per)) {
    stop("sentiment_result must be the output of analyse_nrc_sentiment().")
  }

  rate_per <- sentiment_result$rate_per
  value_columns <- paste0(visual_sentiment_dimensions, "_per_", rate_per, "_words")
  require_columns(sentiment_result$rates, c("reflection_id", value_columns), "sentiment_result$rates")
  rates <- sentiment_result$rates

  if (is.null(reflection_id)) {
    values <- colMeans(rates[, value_columns, drop = FALSE], na.rm = TRUE)
    scope <- "corpus mean"
  } else {
    rows <- rates$reflection_id == reflection_id
    if (sum(rows) != 1L) stop("reflection_id must identify exactly one sentiment row.")
    values <- as.numeric(rates[rows, value_columns, drop = TRUE])
    scope <- reflection_id
  }
  values[!is.finite(values)] <- 0

  path <- open_png_device(output_file)
  on.exit(grDevices::dev.off())

  graphics::par(mar = c(8, 5, 4, 2) + 0.1)
  graphics::barplot(
    values,
    names.arg = visual_sentiment_dimensions,
    las = 2,
    ylab = paste0("Lexicon hits per ", rate_per, " words"),
    main = paste0("NRC lexical sentiment rates — ", scope),
    cex.names = 0.82
  )
  graphics::mtext(
    "Lexicon-based description only; not a psychological or personality measure.",
    side = 3, line = 0.25, cex = 0.75
  )

  invisible(path)
}

plot_recommendation_scores <- function(recommendation_result, output_file, reflection_id = NULL) {
  if (!is.list(recommendation_result) || is.null(recommendation_result$recommendations)) {
    stop("recommendation_result must be the output of recommend_activities().")
  }

  recommendations <- recommendation_result$recommendations
  require_columns(
    recommendations,
    c("reflection_id", "rank", "title", "recommendation_score", "shared_evidence_count"),
    "recommendations"
  )

  path <- open_png_device(output_file)
  on.exit(grDevices::dev.off())

  if (nrow(recommendations) == 0L) {
    graphics::plot.new()
    graphics::title(main = "Activity recommendations")
    graphics::text(0.5, 0.5, "No recommendations passed the evidence thresholds.")
    return(invisible(path))
  }

  if (is.null(reflection_id)) reflection_id <- recommendations$reflection_id[1L]
  selected <- recommendations[recommendations$reflection_id == reflection_id, , drop = FALSE]
  if (nrow(selected) == 0L) stop("No recommendations were found for reflection_id: ", reflection_id)

  selected <- selected[order(selected$rank), , drop = FALSE]
  labels <- paste0(
    "#", selected$rank, " ", selected$title,
    "  [evidence=", selected$shared_evidence_count, "]"
  )

  graphics::par(mar = c(5, 14, 4, 2) + 0.1)
  graphics::barplot(
    rev(selected$recommendation_score),
    names.arg = rev(labels),
    horiz = TRUE,
    las = 1,
    xlab = "Transparent recommendation score",
    main = paste0("Explainable activity recommendations — ", reflection_id),
    cex.names = 0.78
  )
  graphics::mtext(
    "Ranking uses classification evidence + activity features; sentiment and LDA topics are excluded.",
    side = 3, line = 0.25, cex = 0.72
  )

  invisible(path)
}

render_analysis_figures <- function(
  classification_result,
  output_dir,
  topic_result = NULL,
  sentiment_result = NULL,
  recommendation_result = NULL,
  recommendation_reflection_id = NULL
) {
  if (!is.list(classification_result) || is.null(classification_result$scores) || is.null(classification_result$predictions)) {
    stop("classification_result must be the output of classify_interest_categories().")
  }

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output_dir)) stop("Could not create output directory: ", output_dir)

  paths <- c(
    classification_scores = plot_classification_scores(
      classification_result$scores,
      file.path(output_dir, "01-classification-scores.png")
    ),
    classification_confidence = plot_classification_confidence(
      classification_result$predictions,
      file.path(output_dir, "02-classification-confidence.png")
    )
  )

  if (!is.null(topic_result)) {
    paths <- c(paths, topic_terms = plot_topic_terms(
      topic_result,
      file.path(output_dir, "03-topic-terms.png")
    ))
  }

  if (!is.null(sentiment_result)) {
    paths <- c(paths, sentiment_rates = plot_sentiment_rates(
      sentiment_result,
      file.path(output_dir, "04-sentiment-rates.png")
    ))
  }

  if (!is.null(recommendation_result)) {
    paths <- c(paths, recommendations = plot_recommendation_scores(
      recommendation_result,
      file.path(output_dir, "05-recommendations.png"),
      reflection_id = recommendation_reflection_id
    ))
  }

  paths
}
