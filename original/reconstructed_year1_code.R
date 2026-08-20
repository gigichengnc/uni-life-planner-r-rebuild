# Year 1 Baseline v1 — frozen historical reconstruction
# Reconstructed from Appendix 1A of the original STAT 2610SEF report.
# PDF line wrapping has been repaired, but methodological/programming issues
# are intentionally left in place and documented in docs/known-problems.md.
# Do not refactor this file; improvements belong in R/.

# List of required packages
packages <- c(
  "tm",
  "topicmodels",
  "dplyr",
  "crayon",
  "wordcloud",
  "ggplot2",
  "syuzhet",
  "ldatuning",
  "textTinyR",
  "rmarkdown",
  "knitr"
)

# Install missing packages
install_missing_packages <- function(pkg_list) {
  missing_packages <- pkg_list[!(pkg_list %in% installed.packages()[, "Package"])]
  if (length(missing_packages) > 0) {
    install.packages(missing_packages)
    cat("Installed the following packages:\n")
    print(missing_packages)
  } else {
    cat("All packages are already installed.\n")
  }
}

# Run the function
install_missing_packages(packages)

# Load the packages
lapply(packages, library, character.only = TRUE)

# Step 1: Define File Paths
file_paths <- c(
  "C:/Users/cnc_g/OneDrive/文件/HW/01.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/02.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/03.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/04.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/05.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/06.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/07.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/08.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/09.txt",
  "C:/Users/cnc_g/OneDrive/文件/HW/10.txt"
)

# Step 2: Read Announcements Heading from a Text File
announcements <- readLines(
  "C:/Users/cnc_g/OneDrive/文件/HW/Choices of activity.txt",
  warn = FALSE,
  encoding = "UTF-8"
)

# Step 3: Define Categories and Their Definitions
categories <- list(
  "Aesthetics & Spirituality" = c(
    "Art Exhibitions", "Literary Readings", "Film Screenings",
    "Yoga and Meditation Sessions", "Cultural Festivals"
  ),
  "Future Skills & Intelligence" = c(
    "Hackathons", "Tech Talks", "Coding Bootcamps",
    "Innovation Competitions", "Workshops and Training Sessions"
  ),
  "Humanity & Love" = c(
    "Charity Fundraisers", "Volunteer Programs", "Community Service Projects",
    "Outreach Programs", "Public Lectures"
  ),
  "Igniting & Sports" = c(
    "Sports Teams", "Fitness Classes", "Debate Clubs",
    "Drama Societies", "Music Ensembles"
  ),
  "Temperance & Justice" = c(
    "Student Council Meetings", "Advocacy Groups", "Committee Participation",
    "Campus Policy Discussions", "Environmental Initiatives"
  )
)

# Step 4: Define Custom Words to Remove
custom_words <- c(
  "example", "usual", "activity", "choices", "file", "journal", "s",
  "the", "and", "of", "to", "in"
)

# Step 5: Process Each File
for (i in seq_along(file_paths)) {
  # Read Text Data
  reflection_journal <- readLines(file_paths[i], warn = FALSE, encoding = "UTF-8")

  # Remove Empty Rows
  reflection_journal <- reflection_journal[reflection_journal != ""]

  # Skip processing if the file is empty
  if (length(reflection_journal) == 0) {
    cat(red(paste("File", i, "- The file is empty. Skipping...\n")))
    next
  }

  # Create a Corpus
  corpus <- Corpus(VectorSource(reflection_journal))

  # Preprocess Text
  corpus <- tm_map(corpus, content_transformer(tolower))
  corpus <- tm_map(corpus, content_transformer(removePunctuation))
  corpus <- tm_map(corpus, content_transformer(removeNumbers))
  corpus <- tm_map(corpus, removeWords, stopwords("en"))
  corpus <- tm_map(corpus, removeWords, custom_words)
  corpus <- tm_map(corpus, stripWhitespace)

  # Create Document-Term Matrix
  dtm <- DocumentTermMatrix(corpus)

  # Skip processing if the DTM is empty
  if (nrow(dtm) == 0 || ncol(dtm) == 0) {
    cat(red(paste("File", i, "- The document-term matrix is empty. Skipping...\n")))
    next
  }

  # Train LDA Model
  lda_model <- LDA(dtm, k = length(categories), control = list(seed = 1234))

  # Inspect the LDA Model
  topics <- terms(lda_model, 10)
  cat(blue(paste("File", i, "- Top terms for each topic:\n")))
  print(topics)

  # Automatically Identify the Most Relevant Topic
  topic_distribution <- posterior(lda_model)$topics
  most_relevant_topic <- which.max(colSums(topic_distribution))

  # Extract the category name
  category_name <- names(categories)[most_relevant_topic]
  cat(green(paste("File", i, "- The most relevant category is:", category_name, "\n")))

  # Extract Bag of Words for Identified Topic
  bag_of_words <- topics[, most_relevant_topic]
  cat(yellow(paste(
    "File", i, "- Bag of words for the identified topic:",
    paste(bag_of_words, collapse = ", "), "\n"
  )))

  # Print Related Rows
  related_rows <- announcements[
    grepl(paste(bag_of_words, collapse = "|"), announcements, ignore.case = TRUE)
  ]

  if (length(related_rows) == 0) {
    cat(red(paste("File", i, "- There are no relevant activities choices.\n")))
  } else {
    cat(magenta(paste("File", i, "- Related announcements:\n")))
    print(related_rows)
  }

  # Generate Word Cloud
  term_freq <- colSums(as.matrix(dtm))
  term_freq <- sort(term_freq, decreasing = TRUE)

  if (length(term_freq) > 0) {
    cat(blue(paste("File", i, "- Generating word cloud...\n")))
    wordcloud(
      names(term_freq), term_freq,
      max.words = min(100, length(term_freq)),
      random.order = FALSE,
      colors = brewer.pal(8, "Dark2")
    )
  } else {
    cat(red(paste("File", i, "- No terms available for word cloud. Skipping...\n")))
  }

  # Sentiment Analysis
  cat(blue(paste("File", i, "- Performing sentiment analysis...\n")))
  sentiments <- get_nrc_sentiment(reflection_journal)
  sentiment_summary <- colSums(sentiments)
  barplot(
    sentiment_summary,
    las = 2,
    col = rainbow(10),
    main = paste("Sentiment Analysis for File", i)
  )

  # PNG wordcloud / duplicated sentiment-analysis block in original report
  cat(blue(paste("File", i, "- Performing sentiment analysis...\n")))
  sentiments <- get_nrc_sentiment(reflection_journal)
  sentiment_summary <- colSums(sentiments)

  # Open a PNG graphics device
  png(
    filename = paste0("sentiment_analysis_file_", i, ".png"),
    width = 800,
    height = 600
  )

  # Create the barplot
  barplot(
    sentiment_summary,
    las = 2,
    col = rainbow(10),
    main = paste("Sentiment Analysis for File", i)
  )

  # Close the graphics device
  dev.off()

  # PNG wordcloud
  png(filename = paste0("wordcloud_", i, ".png"))
  wordcloud(
    names(term_freq), term_freq,
    max.words = 100,
    random.order = FALSE,
    colors = brewer.pal(8, "Dark2")
  )
  dev.off()

  # Add a separator for clarity
  cat(blue("------------------------------------------------------------\n"))
}

print("end")
