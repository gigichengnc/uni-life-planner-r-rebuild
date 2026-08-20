# Phase 6: validation helpers for independently labelled external evaluation data
#
# This module validates process/schema consistency. It does not create labels,
# prove annotator independence, or prove that a dataset is genuinely unseen.

external_allowed_categories <- function() {
  if (!exists("default_category_dictionary", inherits = TRUE)) {
    stop("default_category_dictionary is unavailable. Source R/03_classify_interests.R first.")
  }
  names(default_category_dictionary)
}

normalise_external_bool <- function(x, field_name) {
  if (is.logical(x)) return(x)

  values <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(values))
  out[values %in% c("true", "t", "1", "yes", "y")] <- TRUE
  out[values %in% c("false", "f", "0", "no", "n")] <- FALSE

  if (anyNA(out)) {
    bad <- unique(values[is.na(out)])
    stop(field_name, " contains values that cannot be interpreted as TRUE/FALSE: ", paste(bad, collapse = ", "))
  }

  out
}

parse_external_category_set <- function(x) {
  if (length(x) != 1L || is.na(x) || !nzchar(trimws(x))) return(character())
  values <- trimws(unlist(strsplit(as.character(x), "|", fixed = TRUE), use.names = FALSE))
  sort(unique(values[nzchar(values)]))
}

collapse_external_category_set <- function(x) {
  x <- sort(unique(x[nzchar(x)]))
  paste(x, collapse = " | ")
}

validate_category_decision <- function(status, primary_category, secondary_categories, row_label = "row") {
  allowed_status <- c("classified", "ambiguous", "unclassified")
  allowed_categories <- external_allowed_categories()

  status <- trimws(as.character(status))
  primary_category <- ifelse(is.na(primary_category), "", trimws(as.character(primary_category)))
  secondary_set <- parse_external_category_set(secondary_categories)

  if (!status %in% allowed_status) {
    stop(row_label, " has unsupported status: ", status)
  }

  invalid_secondary <- setdiff(secondary_set, allowed_categories)
  if (length(invalid_secondary) > 0L) {
    stop(row_label, " has unsupported secondary categories: ", paste(invalid_secondary, collapse = ", "))
  }

  if (status == "classified") {
    if (!nzchar(primary_category) || !primary_category %in% allowed_categories) {
      stop(row_label, " is classified but does not contain exactly one valid primary_category.")
    }
    if (primary_category %in% secondary_set) {
      stop(row_label, " repeats the primary category inside secondary_categories.")
    }
  }

  if (status == "ambiguous") {
    if (nzchar(primary_category)) {
      stop(row_label, " is ambiguous, so primary_category must be blank.")
    }
    if (length(secondary_set) < 2L) {
      stop(row_label, " is ambiguous, so secondary_categories must contain at least two categories.")
    }
  }

  if (status == "unclassified") {
    if (nzchar(primary_category) || length(secondary_set) > 0L) {
      stop(row_label, " is unclassified, so primary_category and secondary_categories must both be blank.")
    }
  }

  invisible(TRUE)
}

validate_external_dataset_registry <- function(registry, allow_empty = FALSE) {
  required <- c(
    "reflection_id", "source_batch", "split", "first_seen_after_model_freeze",
    "public_release_allowed", "text_path"
  )
  missing <- setdiff(required, names(registry))
  if (length(missing) > 0L) {
    stop("Dataset registry is missing required columns: ", paste(missing, collapse = ", "))
  }

  if (nrow(registry) == 0L) {
    if (allow_empty) return(invisible(TRUE))
    stop("Dataset registry contains no rows.")
  }

  ids <- trimws(as.character(registry$reflection_id))
  if (any(!nzchar(ids)) || anyNA(ids)) stop("Dataset registry contains blank reflection_id values.")
  if (anyDuplicated(ids)) stop("Dataset registry must contain unique reflection_id values.")

  splits <- trimws(as.character(registry$split))
  if (any(splits != "external_test")) {
    stop("All Phase 6 registry rows must use split = external_test.")
  }

  first_seen <- normalise_external_bool(registry$first_seen_after_model_freeze, "first_seen_after_model_freeze")
  if (any(!first_seen)) {
    stop("Every external-test row must have first_seen_after_model_freeze = TRUE.")
  }

  normalise_external_bool(registry$public_release_allowed, "public_release_allowed")

  source_batch <- trimws(as.character(registry$source_batch))
  text_path <- trimws(as.character(registry$text_path))
  if (any(!nzchar(source_batch)) || any(!nzchar(text_path))) {
    stop("Dataset registry requires non-blank source_batch and text_path values.")
  }

  invisible(TRUE)
}

validate_external_annotations <- function(annotations, require_two_annotators = TRUE, allow_empty = FALSE) {
  required <- c(
    "reflection_id", "annotator_id", "annotation_round", "status",
    "primary_category", "secondary_categories", "confidence", "rationale",
    "labelled_without_model_output"
  )
  missing <- setdiff(required, names(annotations))
  if (length(missing) > 0L) {
    stop("Annotation table is missing required columns: ", paste(missing, collapse = ", "))
  }

  if (nrow(annotations) == 0L) {
    if (allow_empty) return(invisible(TRUE))
    stop("Annotation table contains no rows.")
  }

  ids <- trimws(as.character(annotations$reflection_id))
  annotators <- trimws(as.character(annotations$annotator_id))
  rounds <- suppressWarnings(as.integer(annotations$annotation_round))
  confidence <- suppressWarnings(as.integer(annotations$confidence))

  if (any(!nzchar(ids)) || anyNA(ids)) stop("Annotation table contains blank reflection_id values.")
  if (any(!nzchar(annotators)) || anyNA(annotators)) stop("Annotation table contains blank annotator_id values.")
  if (anyNA(rounds) || any(rounds < 1L)) stop("annotation_round must contain positive integers.")
  if (anyNA(confidence) || any(!confidence %in% 1:3)) stop("confidence must be an integer from 1 to 3.")

  duplicate_key <- paste(ids, annotators, rounds, sep = "::")
  if (anyDuplicated(duplicate_key)) {
    stop("Each reflection_id / annotator_id / annotation_round combination must be unique.")
  }

  blinded <- normalise_external_bool(
    annotations$labelled_without_model_output,
    "labelled_without_model_output"
  )
  if (any(!blinded)) {
    stop("Every external annotation must have labelled_without_model_output = TRUE.")
  }

  rationale <- trimws(as.character(annotations$rationale))
  if (any(!nzchar(rationale)) || anyNA(rationale)) {
    stop("Every annotation requires a non-blank rationale.")
  }

  for (i in seq_len(nrow(annotations))) {
    validate_category_decision(
      annotations$status[i],
      annotations$primary_category[i],
      annotations$secondary_categories[i],
      row_label = paste0("annotation row ", i)
    )
  }

  if (require_two_annotators) {
    first_round <- annotations[rounds == 1L, , drop = FALSE]
    per_reflection <- split(first_round$annotator_id, first_round$reflection_id)
    counts <- vapply(per_reflection, function(x) length(unique(x)), integer(1))
    if (length(counts) == 0L || any(counts < 2L)) {
      bad <- names(counts)[counts < 2L]
      if (length(bad) == 0L) bad <- unique(ids)
      stop(
        "Each reflection requires at least two independent first-round annotators. Missing requirement for: ",
        paste(bad, collapse = ", ")
      )
    }
  }

  invisible(TRUE)
}

validate_adjudicated_external_labels <- function(labels, allow_empty = FALSE) {
  required <- c(
    "reflection_id", "dataset_version", "status", "primary_category",
    "secondary_categories", "adjudication_method", "adjudicator_id",
    "rationale", "frozen"
  )
  missing <- setdiff(required, names(labels))
  if (length(missing) > 0L) {
    stop("Adjudicated labels are missing required columns: ", paste(missing, collapse = ", "))
  }

  if (nrow(labels) == 0L) {
    if (allow_empty) return(invisible(TRUE))
    stop("Adjudicated label table contains no rows.")
  }

  ids <- trimws(as.character(labels$reflection_id))
  if (any(!nzchar(ids)) || anyNA(ids)) stop("Adjudicated labels contain blank reflection_id values.")
  if (anyDuplicated(ids)) stop("Adjudicated labels must contain one row per reflection_id.")

  dataset_version <- trimws(as.character(labels$dataset_version))
  method <- trimws(as.character(labels$adjudication_method))
  adjudicator <- trimws(as.character(labels$adjudicator_id))
  rationale <- trimws(as.character(labels$rationale))

  if (any(!nzchar(dataset_version)) || any(!nzchar(method)) || any(!nzchar(adjudicator)) || any(!nzchar(rationale))) {
    stop("Adjudicated labels require dataset_version, adjudication_method, adjudicator_id, and rationale.")
  }

  frozen <- normalise_external_bool(labels$frozen, "frozen")
  if (any(!frozen)) stop("Every adjudicated external label must have frozen = TRUE before evaluation.")

  for (i in seq_len(nrow(labels))) {
    validate_category_decision(
      labels$status[i],
      labels$primary_category[i],
      labels$secondary_categories[i],
      row_label = paste0("adjudicated label row ", i)
    )
  }

  invisible(TRUE)
}

external_decision_signature <- function(status, primary_category, secondary_categories) {
  status <- trimws(as.character(status))
  primary <- ifelse(is.na(primary_category), "", trimws(as.character(primary_category)))
  secondary <- collapse_external_category_set(parse_external_category_set(secondary_categories))
  paste(status, primary, secondary, sep = "::")
}

summarise_external_annotation_agreement <- function(annotations) {
  validate_external_annotations(annotations, require_two_annotators = TRUE)

  first_round <- annotations[suppressWarnings(as.integer(annotations$annotation_round)) == 1L, , drop = FALSE]
  first_round$decision_signature <- mapply(
    external_decision_signature,
    first_round$status,
    first_round$primary_category,
    first_round$secondary_categories,
    USE.NAMES = FALSE
  )

  parts <- split(first_round, first_round$reflection_id)
  rows <- lapply(parts, function(part) {
    signatures <- unique(part$decision_signature)
    primary <- ifelse(is.na(part$primary_category), "", trimws(as.character(part$primary_category)))

    data.frame(
      reflection_id = part$reflection_id[1L],
      n_annotators = length(unique(part$annotator_id)),
      exact_decision_agreement = length(signatures) == 1L,
      primary_category_agreement = length(unique(primary)) == 1L,
      decision_signatures = paste(sort(signatures), collapse = " || "),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out[order(out$reflection_id), , drop = FALSE]
}

build_external_adjudication_queue <- function(annotations) {
  agreement <- summarise_external_annotation_agreement(annotations)
  queue <- agreement[!agreement$exact_decision_agreement, , drop = FALSE]
  row.names(queue) <- NULL
  queue
}

validate_external_evaluation_bundle <- function(registry, annotations, adjudicated_labels) {
  validate_external_dataset_registry(registry)
  validate_external_annotations(annotations, require_two_annotators = TRUE)
  validate_adjudicated_external_labels(adjudicated_labels)

  registry_ids <- sort(unique(as.character(registry$reflection_id)))
  annotation_ids <- sort(unique(as.character(annotations$reflection_id)))
  adjudicated_ids <- sort(unique(as.character(adjudicated_labels$reflection_id)))

  if (!identical(registry_ids, annotation_ids) || !identical(registry_ids, adjudicated_ids)) {
    stop("Registry, annotation, and adjudicated-label reflection_id sets must match exactly.")
  }

  invisible(TRUE)
}
