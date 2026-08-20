# Phase 4: failure diagnosis for the locked challenge benchmark
#
# This module analyses errors produced by the existing transparent classifier.
# It does NOT modify the classifier, the dictionary, thresholds, or the locked
# benchmark. The purpose is diagnosis before model escalation.

failure_mode_catalog <- function() {
  data.frame(
    failure_mode = c(
      "correct",
      "off_domain_false_positive",
      "lexicon_coverage_gap",
      "paraphrase_coverage_gap",
      "negation_blindness",
      "context_blindness",
      "purpose_vs_surface_signal",
      "primary_intent_weighting_failure",
      "mixed_signal_forced_single_label",
      "mixed_signal_coverage_gap",
      "mixed_signal_top_set_mismatch",
      "ambiguity_overtrigger",
      "top_category_mismatch",
      "theme_mismatch",
      "unexpected_clean_case_miss",
      "other_decision_error"
    ),
    diagnostic_family = c(
      "correct",
      "abstention_and_scope",
      "lexical_coverage",
      "lexical_coverage",
      "compositional_language",
      "semantic_context",
      "semantic_context",
      "intent_weighting",
      "multi_label_and_abstention",
      "multi_label_and_abstention",
      "multi_label_and_abstention",
      "calibration",
      "category_ranking",
      "decision_mapping",
      "baseline_integrity",
      "other"
    ),
    priority = c(
      "P0", "P1", "P2", "P2", "P1", "P1", "P1", "P1",
      "P1", "P2", "P1", "P2", "P2", "P2", "P1", "P3"
    ),
    complexity_hint = c(
      "none",
      "rule_or_threshold",
      "data_or_dictionary",
      "data_or_model",
      "transparent_rule",
      "rule_or_model",
      "rule_or_model",
      "rule_or_model",
      "threshold_or_multilabel",
      "data_or_multilabel",
      "multilabel",
      "threshold_calibration",
      "dictionary_or_model",
      "decision_logic",
      "debug_before_modelling",
      "manual_review"
    ),
    suggested_next_step = c(
      "No change required for this case.",
      "Strengthen abstention or out-of-domain handling; do not force a category from incidental keywords.",
      "Measure missing vocabulary on independent data before expanding the dictionary; keep the locked case unchanged.",
      "Collect independent paraphrase examples and compare dictionary expansion with a context-aware alternative.",
      "Add transparent local negation or phrase handling before term scoring, then retest the unchanged benchmark.",
      "Test phrase/context weighting or a supervised context-aware classifier if sufficient labelled data becomes available.",
      "Separate the reflection's primary purpose from supporting methods or surface vocabulary.",
      "Add an explicit way to represent primary versus secondary signals, or compare a model that can learn intent weighting.",
      "Permit multi-label or abstention behaviour when two domains have genuinely comparable evidence.",
      "Improve evidence coverage for mixed-domain cases without rewriting the locked benchmark.",
      "Represent the tied category set explicitly rather than collapsing a multi-domain case into the wrong top set.",
      "Review ambiguity thresholds and calibration using validation data, not by editing challenge cases.",
      "Inspect which dictionary evidence displaced the intended category before considering dictionary or model changes.",
      "Audit the mapping from scores/status to final decision before changing the underlying model.",
      "Treat a miss on a clean case as a baseline implementation/data issue and debug it before adding complexity.",
      "Inspect manually and create a new failure category only if the pattern recurs across independent cases."
    ),
    stringsAsFactors = FALSE
  )
}

diagnose_failure_mode <- function(case_row) {
  required <- c(
    "decision_correct", "expected_status", "status", "challenge_type",
    "top_score", "top_categories_correct", "theme_correct"
  )
  missing <- setdiff(required, names(case_row))
  if (length(missing) > 0L) {
    stop("Case row is missing required columns: ", paste(missing, collapse = ", "))
  }
  if (nrow(case_row) != 1L) {
    stop("diagnose_failure_mode() expects exactly one case row.")
  }

  if (isTRUE(case_row$decision_correct[1L])) {
    return("correct")
  }

  expected_status <- as.character(case_row$expected_status[1L])
  observed_status <- as.character(case_row$status[1L])
  challenge_type <- as.character(case_row$challenge_type[1L])
  top_score <- as.numeric(case_row$top_score[1L])
  top_categories_correct <- isTRUE(case_row$top_categories_correct[1L])
  theme_correct <- isTRUE(case_row$theme_correct[1L])

  if (expected_status == "unclassified" && observed_status != "unclassified") {
    return("off_domain_false_positive")
  }

  if (!is.na(top_score) && top_score <= 0 && expected_status != "unclassified") {
    return("lexicon_coverage_gap")
  }

  if (identical(challenge_type, "negation_context")) {
    return("negation_blindness")
  }

  if (grepl("^paraphrase_", challenge_type)) {
    return("paraphrase_coverage_gap")
  }

  if (identical(challenge_type, "context_over_keywords")) {
    return("context_blindness")
  }

  if (identical(challenge_type, "cross_domain_primary")) {
    return("purpose_vs_surface_signal")
  }

  if (identical(challenge_type, "mixed_primary")) {
    return("primary_intent_weighting_failure")
  }

  if (expected_status == "ambiguous" && observed_status == "classified") {
    return("mixed_signal_forced_single_label")
  }

  if (expected_status == "ambiguous" && observed_status == "unclassified") {
    return("mixed_signal_coverage_gap")
  }

  if (identical(challenge_type, "mixed_dual_domain") && !top_categories_correct) {
    return("mixed_signal_top_set_mismatch")
  }

  if (expected_status == "classified" && observed_status == "ambiguous") {
    return("ambiguity_overtrigger")
  }

  if (!top_categories_correct) {
    return("top_category_mismatch")
  }

  if (!theme_correct) {
    return("theme_mismatch")
  }

  if (identical(challenge_type, "clean_single")) {
    return("unexpected_clean_case_miss")
  }

  "other_decision_error"
}

summarise_failure_modes <- function(failures) {
  if (nrow(failures) == 0L) {
    return(data.frame(
      failure_mode = character(),
      diagnostic_family = character(),
      priority = character(),
      complexity_hint = character(),
      suggested_next_step = character(),
      n = integer(),
      reflection_ids = character(),
      challenge_types = character(),
      stringsAsFactors = FALSE
    ))
  }

  parts <- split(failures, failures$failure_mode)
  rows <- lapply(parts, function(part) {
    data.frame(
      failure_mode = part$failure_mode[1L],
      diagnostic_family = part$diagnostic_family[1L],
      priority = part$priority[1L],
      complexity_hint = part$complexity_hint[1L],
      suggested_next_step = part$suggested_next_step[1L],
      n = nrow(part),
      reflection_ids = paste(part$reflection_id, collapse = ", "),
      challenge_types = paste(sort(unique(part$challenge_type)), collapse = ", "),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  priority_rank <- match(out$priority, c("P0", "P1", "P2", "P3"))
  out[order(priority_rank, -out$n, out$failure_mode), , drop = FALSE]
}

summarise_failure_families <- function(failures) {
  if (nrow(failures) == 0L) {
    return(data.frame(
      diagnostic_family = character(),
      n = integer(),
      failure_modes = character(),
      reflection_ids = character(),
      stringsAsFactors = FALSE
    ))
  }

  parts <- split(failures, failures$diagnostic_family)
  rows <- lapply(parts, function(part) {
    data.frame(
      diagnostic_family = part$diagnostic_family[1L],
      n = nrow(part),
      failure_modes = paste(sort(unique(part$failure_mode)), collapse = ", "),
      reflection_ids = paste(part$reflection_id, collapse = ", "),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out[order(-out$n, out$diagnostic_family), , drop = FALSE]
}

build_improvement_queue <- function(failure_modes) {
  if (nrow(failure_modes) == 0L) {
    return(data.frame(
      priority = character(),
      failure_mode = character(),
      n = integer(),
      reflection_ids = character(),
      complexity_hint = character(),
      suggested_next_step = character(),
      stringsAsFactors = FALSE
    ))
  }

  out <- failure_modes[, c(
    "priority", "failure_mode", "n", "reflection_ids",
    "complexity_hint", "suggested_next_step"
  ), drop = FALSE]
  priority_rank <- match(out$priority, c("P0", "P1", "P2", "P3"))
  out[order(priority_rank, -out$n, out$failure_mode), , drop = FALSE]
}

analyse_challenge_failures <- function(challenge_result) {
  if (!is.list(challenge_result) || is.null(challenge_result$cases)) {
    stop("challenge_result must be the output of evaluate_challenge_benchmark().")
  }

  cases <- challenge_result$cases
  required <- c(
    "reflection_id", "benchmark_version", "challenge_type", "expected_status",
    "intended_theme", "expected_categories", "label_rationale", "status",
    "predicted_theme", "top_score", "runner_up_score", "margin",
    "observed_top_categories", "status_correct", "theme_correct",
    "top_categories_correct", "decision_correct", "error_type"
  )
  missing <- setdiff(required, names(cases))
  if (length(missing) > 0L) {
    stop("Challenge cases are missing required columns: ", paste(missing, collapse = ", "))
  }

  cases$failure_mode <- vapply(
    seq_len(nrow(cases)),
    function(i) diagnose_failure_mode(cases[i, , drop = FALSE]),
    character(1)
  )

  catalog <- failure_mode_catalog()
  catalog_match <- match(cases$failure_mode, catalog$failure_mode)
  if (anyNA(catalog_match)) {
    stop(
      "Failure-mode catalog is missing mappings for: ",
      paste(unique(cases$failure_mode[is.na(catalog_match)]), collapse = ", ")
    )
  }

  cases$diagnostic_family <- catalog$diagnostic_family[catalog_match]
  cases$priority <- catalog$priority[catalog_match]
  cases$complexity_hint <- catalog$complexity_hint[catalog_match]
  cases$suggested_next_step <- catalog$suggested_next_step[catalog_match]

  failures <- cases[!cases$decision_correct, , drop = FALSE]
  row.names(cases) <- NULL
  row.names(failures) <- NULL

  failure_modes <- summarise_failure_modes(failures)
  failure_families <- summarise_failure_families(failures)
  improvement_queue <- build_improvement_queue(failure_modes)

  list(
    benchmark_summary = challenge_result$summary,
    case_diagnostics = cases,
    failure_register = failures,
    failure_modes = failure_modes,
    failure_families = failure_families,
    improvement_queue = improvement_queue,
    catalog = catalog
  )
}
