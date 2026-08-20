# Phase 2 corrected implementation: transparent text preprocessing
#
# This module keeps preprocessing separate from modelling. It uses base R so
# the transformations are easy to inspect and reproduce.

default_stopwords <- c(
  "a", "an", "and", "are", "as", "at", "be", "been", "being", "but",
  "by", "for", "from", "had", "has", "have", "he", "her", "hers", "him",
  "his", "i", "if", "in", "into", "is", "it", "its", "me", "my", "of",
  "on", "or", "our", "ours", "she", "so", "than", "that", "the", "their",
  "theirs", "them", "then", "there", "they", "this", "to", "too", "us",
  "was", "we", "were", "what", "when", "where", "which", "who", "will",
  "with", "you", "your", "yours"
)

default_custom_stopwords <- c(
  "activity", "activities", "event", "events", "reflection", "journal",
  "student", "students", "university", "campus"
)

clean_text <- function(x) {
  if (length(x) != 1L || is.na(x)) {
    stop("clean_text() expects one non-missing character string.")
  }

  x <- iconv(x, from = "", to = "UTF-8", sub = " ")
  x <- tolower(x)
  x <- gsub("https?://\\S+|www\\.\\S+", " ", x, perl = TRUE)
  x <- gsub("[[:digit:]]+", " ", x)
  x <- gsub("[[:punct:]]+", " ", x)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}

tokenize_text <- function(
  x,
  stopwords = default_stopwords,
  custom_stopwords = default_custom_stopwords,
  min_chars = 2L
) {
  cleaned <- clean_text(x)

  if (!nzchar(cleaned)) {
    return(character())
  }

  tokens <- unlist(strsplit(cleaned, "\\s+"), use.names = FALSE)
  excluded <- unique(c(stopwords, custom_stopwords))

  tokens[
    nchar(tokens) >= min_chars &
      !(tokens %in% excluded)
  ]
}

preprocess_reflections <- function(
  reflections,
  stopwords = default_stopwords,
  custom_stopwords = default_custom_stopwords,
  min_chars = 2L
) {
  required <- c("reflection_id", "text")
  missing <- setdiff(required, names(reflections))

  if (length(missing) > 0L) {
    stop("Reflection data is missing required columns: ", paste(missing, collapse = ", "))
  }

  rows <- lapply(seq_len(nrow(reflections)), function(i) {
    tokens <- tokenize_text(
      reflections$text[i],
      stopwords = stopwords,
      custom_stopwords = custom_stopwords,
      min_chars = min_chars
    )

    if (length(tokens) == 0L) {
      return(NULL)
    }

    data.frame(
      reflection_id = rep(reflections$reflection_id[i], length(tokens)),
      token = tokens,
      stringsAsFactors = FALSE
    )
  })

  rows <- Filter(Negate(is.null), rows)

  if (length(rows) == 0L) {
    return(data.frame(
      reflection_id = character(),
      token = character(),
      stringsAsFactors = FALSE
    ))
  }

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

count_terms <- function(tokens) {
  required <- c("reflection_id", "token")
  missing <- setdiff(required, names(tokens))

  if (length(missing) > 0L) {
    stop("Token data is missing required columns: ", paste(missing, collapse = ", "))
  }

  if (nrow(tokens) == 0L) {
    return(data.frame(
      reflection_id = character(),
      token = character(),
      n = integer(),
      stringsAsFactors = FALSE
    ))
  }

  counts <- aggregate(
    x = list(n = rep.int(1L, nrow(tokens))),
    by = list(
      reflection_id = tokens$reflection_id,
      token = tokens$token
    ),
    FUN = sum
  )

  counts <- counts[order(counts$reflection_id, -counts$n, counts$token), ]
  row.names(counts) <- NULL
  counts
}

build_document_term_matrix <- function(tokens) {
  required <- c("reflection_id", "token")
  missing <- setdiff(required, names(tokens))

  if (length(missing) > 0L) {
    stop("Token data is missing required columns: ", paste(missing, collapse = ", "))
  }

  if (nrow(tokens) == 0L) {
    return(matrix(integer(), nrow = 0L, ncol = 0L))
  }

  as.matrix(xtabs(~ reflection_id + token, data = tokens))
}
