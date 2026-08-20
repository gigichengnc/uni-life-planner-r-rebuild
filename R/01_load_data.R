# Phase 2 corrected implementation: portable data loading
#
# This file deliberately uses base R only. It replaces the hard-coded
# C:/Users/... paths in the Year 1 baseline with project-relative discovery.

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)

  repeat {
    has_readme <- file.exists(file.path(current, "README.md"))
    has_data_dir <- dir.exists(file.path(current, "data"))
    has_r_dir <- dir.exists(file.path(current, "R"))

    if (has_readme && has_data_dir && has_r_dir) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop(
        "Could not locate the project root. Start R from inside the repository ",
        "or pass an explicit project root to the loader functions."
      )
    }

    current <- parent
  }
}

read_utf8_text <- function(path) {
  if (!file.exists(path)) {
    stop("Text file does not exist: ", path)
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines))]
  paste(lines, collapse = "\n")
}

load_reflections <- function(
  root = find_project_root(),
  directory = file.path("data", "sample", "reflections")
) {
  reflection_dir <- file.path(root, directory)

  if (!dir.exists(reflection_dir)) {
    stop("Reflection directory does not exist: ", reflection_dir)
  }

  paths <- sort(list.files(
    reflection_dir,
    pattern = "\\.txt$",
    full.names = TRUE
  ))

  if (length(paths) == 0L) {
    stop("No .txt reflection files found in: ", reflection_dir)
  }

  text <- vapply(paths, read_utf8_text, character(1))

  data.frame(
    reflection_id = tools::file_path_sans_ext(basename(paths)),
    file = basename(paths),
    text = unname(text),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

load_activities <- function(
  root = find_project_root(),
  path = file.path("data", "sample", "activities.csv")
) {
  full_path <- file.path(root, path)

  if (!file.exists(full_path)) {
    stop("Activity file does not exist: ", full_path)
  }

  activities <- read.csv(
    full_path,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    check.names = FALSE
  )

  required <- c("event_id", "title", "category", "description")
  missing <- setdiff(required, names(activities))

  if (length(missing) > 0L) {
    stop("Activity file is missing required columns: ", paste(missing, collapse = ", "))
  }

  activities
}

load_manifest <- function(
  root = find_project_root(),
  path = file.path("data", "sample", "manifest.csv")
) {
  full_path <- file.path(root, path)

  if (!file.exists(full_path)) {
    stop("Manifest file does not exist: ", full_path)
  }

  manifest <- read.csv(
    full_path,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    check.names = FALSE
  )

  required <- c("reflection_id", "file", "intended_theme", "note")
  missing <- setdiff(required, names(manifest))

  if (length(missing) > 0L) {
    stop("Manifest is missing required columns: ", paste(missing, collapse = ", "))
  }

  manifest
}

load_sample_data <- function(root = find_project_root()) {
  list(
    reflections = load_reflections(root = root),
    activities = load_activities(root = root),
    manifest = load_manifest(root = root)
  )
}
