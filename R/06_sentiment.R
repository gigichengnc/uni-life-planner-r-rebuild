# Phase 2 corrected implementation: descriptive NRC sentiment analysis
#
# Sentiment is treated as a separate descriptive task. It does NOT determine
# interest categories, topic labels, personality, or activity recommendations.

nrc_sentiment_columns <- c(
  "anger", "anticipation", "disgust", "fear", "joy",
  "sadness", "surprise", "trust", "negative", "positive"
)

nrc_core_emotions <- c(
  "anger", "anticipation", "disgust", "fear",
  "joy", "sadness", "surprise", "trust"
)

require_syuzhet <- function() {
  if (!requireNamespace("syuzhet", quietly = TRUE)) {
    stop(
      "Package 'syuzhet' is required for NRC sentiment analysis. Install it with ",
      "install.packages('syuzhet')."
    )
  }
  invisible(TRUE)
}

validate_sentiment_input <- function(reflections) {
  required <- c("reflection_id", "text")
  missing <- setdiff(required, names(reflections))

  if (length(missing) > 0L) {
    stop(
      "Reflection data is missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }

  if (anyNA(reflections$reflection_id) || any(!nzchar(trimws(reflections$reflection_id)))) {
    stop("Every reflection must have a non-missing, non-empty reflection_id.")
  }

  if (anyDuplicated(reflections$reflection_id)) {
    stop("reflection_id values must be unique for sentiment analysis.")
  }

  if (anyNA(reflections$text)) {
    stop("Reflection text must not contain missing values.")
  }

  invisible(TRUE)
}

count_sentiment_words <- function(text) {
  vapply(text, function(x) {
    x <- iconv(x, from = "", to = "UTF-8", sub = " ")
    x <- tolower(x)
    x <- gsub("https?://\\S+|www\\.\\S+", " ", x, perl = TRUE)
    x <- gsub("[^[:alpha:]']+", " ", x)
    x <- trimws(gsub("[[:space:]]+", " ", x))

    if (!nzchar(x)) {
      return(0L)
    }

    length(strsplit(x, "\\s+")[[1L]])
  }, integer(1))
}

analyse_nrc_sentiment <- function(
  reflections,
  rate_per = 100,
  language = "english"
) {
  validate_sentiment_input(reflections)
  require_syuzhet()

  if (length(rate_per) != 1L || is.na(rate_per) || rate_per <= 0) {
    stop("rate_per must be one positive number.")
  }

  sentiment <- syuzhet::get_nrc_sentiment(
    reflections$text,
    language = language
  )

  missing_columns <- setdiff(nrc_sentiment_columns, names(sentiment))
  if (length(missing_columns) > 0L) {
    stop(
      "NRC output is missing expected columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  sentiment <- sentiment[, nrc_sentiment_columns, drop = FALSE]

  if (nrow(sentiment) != nrow(reflections)) {
    stop("NRC output row count does not match the number of reflections.")
  }

  word_count <- count_sentiment_words(reflections$text)

  counts <- data.frame(
    reflection_id = reflections$reflection_id,
    word_count = word_count,
    sentiment,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  denominator <- ifelse(word_count > 0L, word_count, NA_real_)
  rates_matrix <- sweep(
    as.matrix(sentiment),
    MARGIN = 1L,
    STATS = denominator,
    FUN = "/"
  ) * rate_per

  colnames(rates_matrix) <- paste0(nrc_sentiment_columns, "_per_", rate_per, "_words")

  rates <- data.frame(
    reflection_id = reflections$reflection_id,
    word_count = word_count,
    rates_matrix,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  list(
    counts = counts,
    rates = rates,
    rate_per = rate_per,
    language = language
  )
}

summarise_nrc_sentiment <- function(sentiment_result) {
  if (!is.list(sentiment_result) || is.null(sentiment_result$counts)) {
    stop("sentiment_result must be the output of analyse_nrc_sentiment().")
  }

  counts <- sentiment_result$counts
  missing <- setdiff(c("reflection_id", nrc_sentiment_columns), names(counts))

  if (length(missing) > 0L) {
    stop(
      "Sentiment counts are missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }

  emotion_matrix <- as.matrix(counts[, nrc_core_emotions, drop = FALSE])

  rows <- lapply(seq_len(nrow(counts)), function(i) {
    values <- emotion_matrix[i, ]
    top_value <- max(values)

    if (top_value <= 0) {
      dominant_emotion <- "No emotion hits"
      emotion_status <- "no_hits"
      tied_emotions <- ""
    } else {
      winners <- names(values)[values == top_value]
      tied_emotions <- paste(winners, collapse = ", ")

      if (length(winners) == 1L) {
        dominant_emotion <- winners
        emotion_status <- "single"
      } else {
        dominant_emotion <- "Tied"
        emotion_status <- "tied"
      }
    }

    data.frame(
      reflection_id = counts$reflection_id[i],
      dominant_emotion = dominant_emotion,
      emotion_status = emotion_status,
      tied_emotions = tied_emotions,
      positive = counts$positive[i],
      negative = counts$negative[i],
      polarity_balance = counts$positive[i] - counts$negative[i],
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

sentiment_to_long <- function(
  sentiment_result,
  scale = c("count", "rate")
) {
  scale <- match.arg(scale)

  if (!is.list(sentiment_result)) {
    stop("sentiment_result must be the output of analyse_nrc_sentiment().")
  }

  if (scale == "count") {
    data <- sentiment_result$counts
    value_columns <- nrc_sentiment_columns
    suffix <- ""
  } else {
    data <- sentiment_result$rates
    suffix <- paste0("_per_", sentiment_result$rate_per, "_words")
    value_columns <- paste0(nrc_sentiment_columns, suffix)
  }

  missing <- setdiff(c("reflection_id", value_columns), names(data))
  if (length(missing) > 0L) {
    stop(
      "Sentiment result is missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }

  rows <- lapply(seq_len(nrow(data)), function(i) {
    data.frame(
      reflection_id = rep(data$reflection_id[i], length(nrc_sentiment_columns)),
      sentiment = nrc_sentiment_columns,
      value = as.numeric(data[i, value_columns]),
      scale = scale,
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}
