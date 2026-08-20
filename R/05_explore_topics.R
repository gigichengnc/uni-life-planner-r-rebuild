# Phase 2 corrected implementation: exploratory corpus-level topic modelling
#
# LDA is retained only as an OPTIONAL exploratory tool. It is fitted across the
# corpus and never used to map Topic 1 -> Category 1 (or any other predefined
# interest category). Category classification remains a separate task.

require_topicmodels <- function() {
  if (requireNamespace("topicmodels", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  namespace_error <- tryCatch(
    {
      loadNamespace("topicmodels")
      NULL
    },
    error = function(e) conditionMessage(e)
  )

  installed <- "topicmodels" %in% rownames(installed.packages())

  if (isTRUE(installed)) {
    stop(
      "Package 'topicmodels' is installed but its namespace could not be loaded. ",
      "Underlying error: ", namespace_error, ". ",
      "On Linux CI, verify that the GNU Scientific Library (GSL) runtime and ",
      "development libraries are available.",
      call. = FALSE
    )
  }

  stop(
    "Package 'topicmodels' is required for LDA exploration but is not available. ",
    "Install it with install.packages('topicmodels'). ",
    "Namespace lookup error: ", namespace_error,
    call. = FALSE
  )
}

prepare_topic_dtm <- function(
  tokens,
  min_document_frequency = 1L,
  min_total_frequency = 1L,
  max_document_proportion = 1
) {
  required <- c("reflection_id", "token")
  missing <- setdiff(required, names(tokens))

  if (length(missing) > 0L) {
    stop("Token data is missing required columns: ", paste(missing, collapse = ", "))
  }

  if (!exists("build_document_term_matrix", mode = "function")) {
    stop("build_document_term_matrix() is unavailable. Source R/02_preprocess.R first.")
  }

  if (length(min_document_frequency) != 1L || min_document_frequency < 1L) {
    stop("min_document_frequency must be a positive integer.")
  }

  if (length(min_total_frequency) != 1L || min_total_frequency < 1L) {
    stop("min_total_frequency must be a positive integer.")
  }

  if (
    length(max_document_proportion) != 1L ||
      is.na(max_document_proportion) ||
      max_document_proportion <= 0 ||
      max_document_proportion > 1
  ) {
    stop("max_document_proportion must be in (0, 1].")
  }

  dtm <- build_document_term_matrix(tokens)

  if (nrow(dtm) == 0L || ncol(dtm) == 0L) {
    stop("The document-term matrix is empty after preprocessing.")
  }

  document_frequency <- colSums(dtm > 0)
  total_frequency <- colSums(dtm)
  document_proportion <- document_frequency / nrow(dtm)

  keep <-
    document_frequency >= as.integer(min_document_frequency) &
    total_frequency >= as.integer(min_total_frequency) &
    document_proportion <= max_document_proportion

  if (!any(keep)) {
    stop("No terms remain after topic-modelling frequency filters.")
  }

  dtm <- dtm[, keep, drop = FALSE]

  non_empty_documents <- rowSums(dtm) > 0
  dropped_documents <- rownames(dtm)[!non_empty_documents]

  if (any(!non_empty_documents)) {
    warning(
      "Dropping documents with no terms after filtering: ",
      paste(dropped_documents, collapse = ", ")
    )
    dtm <- dtm[non_empty_documents, , drop = FALSE]
  }

  storage.mode(dtm) <- "integer"
  attr(dtm, "dropped_documents") <- dropped_documents
  dtm
}

validate_topic_model_input <- function(dtm, k) {
  if (!is.matrix(dtm)) {
    stop("dtm must be a matrix of non-negative integer term counts.")
  }

  if (nrow(dtm) < 3L) {
    stop("At least three non-empty documents are required for this exploratory LDA wrapper.")
  }

  if (ncol(dtm) < 2L) {
    stop("At least two retained terms are required for topic exploration.")
  }

  if (anyNA(dtm) || any(dtm < 0) || any(dtm != floor(dtm))) {
    stop("dtm must contain non-negative integer counts only.")
  }

  if (any(rowSums(dtm) == 0L)) {
    stop("Every document must contain at least one retained term.")
  }

  if (length(k) != 1L || is.na(k) || k != as.integer(k) || k < 2L) {
    stop("k must be one integer of at least 2.")
  }

  if (k >= nrow(dtm)) {
    stop(
      "For this small-corpus exploration, k must be smaller than the number ",
      "of documents."
    )
  }

  invisible(TRUE)
}

fit_lda_topics <- function(
  dtm,
  k = 2L,
  seed = 1234L,
  method = c("Gibbs", "VEM"),
  control = NULL,
  warn_small_corpus = TRUE
) {
  require_topicmodels()
  method <- match.arg(method)
  k <- as.integer(k)
  validate_topic_model_input(dtm, k)

  if (isTRUE(warn_small_corpus) && nrow(dtm) < 20L) {
    warning(
      "This corpus has fewer than 20 documents. Treat LDA output as a ",
      "demonstration/exploratory result, not stable evidence of latent topics."
    )
  }

  if (is.null(control)) {
    control <- if (method == "Gibbs") {
      list(
        seed = as.integer(seed),
        burnin = 200L,
        iter = 1000L,
        thin = 50L,
        verbose = 0L
      )
    } else {
      list(seed = as.integer(seed), verbose = 0L)
    }
  }

  topicmodels::LDA(
    x = dtm,
    k = k,
    method = method,
    control = control
  )
}

extract_top_topic_terms <- function(model, n = 8L) {
  require_topicmodels()

  if (length(n) != 1L || is.na(n) || n < 1L) {
    stop("n must be a positive integer.")
  }

  terms_matrix <- topicmodels::terms(model, as.integer(n))

  rows <- lapply(seq_len(ncol(terms_matrix)), function(topic_index) {
    data.frame(
      topic = paste0("Topic ", topic_index),
      rank = seq_len(nrow(terms_matrix)),
      term = terms_matrix[, topic_index],
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

extract_document_topic_distribution <- function(model) {
  require_topicmodels()
  probabilities <- topicmodels::posterior(model)$topics

  document_ids <- rownames(probabilities)
  if (is.null(document_ids)) {
    document_ids <- paste0("document_", seq_len(nrow(probabilities)))
  }

  rows <- lapply(seq_len(nrow(probabilities)), function(i) {
    ordered <- order(probabilities[i, ], decreasing = TRUE)
    top <- ordered[1L]
    runner_up <- if (length(ordered) >= 2L) ordered[2L] else ordered[1L]

    data.frame(
      reflection_id = document_ids[i],
      dominant_topic = paste0("Topic ", top),
      dominant_probability = probabilities[i, top],
      runner_up_topic = paste0("Topic ", runner_up),
      runner_up_probability = probabilities[i, runner_up],
      margin = probabilities[i, top] - probabilities[i, runner_up],
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

extract_topic_probability_table <- function(model) {
  require_topicmodels()
  probabilities <- topicmodels::posterior(model)$topics

  document_ids <- rownames(probabilities)
  if (is.null(document_ids)) {
    document_ids <- paste0("document_", seq_len(nrow(probabilities)))
  }

  rows <- lapply(seq_len(nrow(probabilities)), function(i) {
    data.frame(
      reflection_id = document_ids[i],
      topic = paste0("Topic ", seq_len(ncol(probabilities))),
      probability = as.numeric(probabilities[i, ]),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

run_topic_exploration <- function(
  tokens,
  k = 2L,
  top_n = 8L,
  seed = 1234L,
  min_document_frequency = 1L,
  min_total_frequency = 1L,
  max_document_proportion = 1,
  warn_small_corpus = TRUE
) {
  dtm <- prepare_topic_dtm(
    tokens = tokens,
    min_document_frequency = min_document_frequency,
    min_total_frequency = min_total_frequency,
    max_document_proportion = max_document_proportion
  )

  model <- fit_lda_topics(
    dtm = dtm,
    k = k,
    seed = seed,
    method = "Gibbs",
    warn_small_corpus = warn_small_corpus
  )

  list(
    dtm = dtm,
    model = model,
    top_terms = extract_top_topic_terms(model, n = top_n),
    document_topics = extract_document_topic_distribution(model),
    topic_probabilities = extract_topic_probability_table(model)
  )
}
