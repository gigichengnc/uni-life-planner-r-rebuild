# Smoke test for the Phase 2 NRC sentiment layer.
#
# Run with:
#   Rscript tests/smoke_test_sentiment.R
#
# This checks implementation behaviour, not psychological validity.

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
source(file.path(root, "R", "06_sentiment.R"))

sample_data <- load_sample_data(root = root)
sentiment <- analyse_nrc_sentiment(sample_data$reflections)
summary <- summarise_nrc_sentiment(sentiment)
long_counts <- sentiment_to_long(sentiment, scale = "count")
long_rates <- sentiment_to_long(sentiment, scale = "rate")

stopifnot(nrow(sentiment$counts) == 5L)
stopifnot(nrow(sentiment$rates) == 5L)
stopifnot(nrow(summary) == 5L)
stopifnot(all(nrc_sentiment_columns %in% names(sentiment$counts)))
stopifnot(all(sentiment$counts$word_count > 0L))
stopifnot(nrow(long_counts) == 5L * length(nrc_sentiment_columns))
stopifnot(nrow(long_rates) == 5L * length(nrc_sentiment_columns))
stopifnot(!("predicted_theme" %in% names(sentiment$counts)))

probe <- data.frame(
  reflection_id = c("positive_probe", "negative_probe"),
  text = c(
    "I felt happy, joyful, grateful, and full of trust.",
    "I felt angry, fearful, sad, and deeply disappointed."
  ),
  stringsAsFactors = FALSE
)

probe_result <- analyse_nrc_sentiment(probe)
positive_row <- probe_result$counts[probe_result$counts$reflection_id == "positive_probe", ]
negative_row <- probe_result$counts[probe_result$counts$reflection_id == "negative_probe", ]

stopifnot(positive_row$positive > positive_row$negative)
stopifnot(negative_row$negative > negative_row$positive)

cat("Phase 2 sentiment smoke test passed.\n")
print(summary)
