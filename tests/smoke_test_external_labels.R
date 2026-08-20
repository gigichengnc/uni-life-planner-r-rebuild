# Smoke test for Phase 6 external-evaluation labelling protocol validators.
#
# Uses in-memory synthetic annotation records only. It does not create or claim
# to test a real external dataset.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) > 0L) {
  script_path <- normalizePath(sub("^--file=", "", script_arg[1L]), winslash = "/", mustWork = TRUE)
  root_guess <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
} else {
  root_guess <- getwd()
}

source(file.path(root_guess, "R", "01_load_data.R"))
root <- find_project_root(start = root_guess)
source(file.path(root, "R", "03_classify_interests.R"))
source(file.path(root, "R", "12_validate_external_labels.R"))

registry <- data.frame(
  reflection_id = c("external_001", "external_002"),
  source_batch = c("batch_alpha", "batch_alpha"),
  split = c("external_test", "external_test"),
  first_seen_after_model_freeze = c(TRUE, TRUE),
  public_release_allowed = c(FALSE, FALSE),
  text_path = c(
    "data/external-evaluation/private/reflections/external_001.txt",
    "data/external-evaluation/private/reflections/external_002.txt"
  ),
  stringsAsFactors = FALSE
)

annotations <- data.frame(
  reflection_id = c("external_001", "external_001", "external_002", "external_002"),
  annotator_id = c("ann_a", "ann_b", "ann_a", "ann_b"),
  annotation_round = c(1L, 1L, 1L, 1L),
  status = c("classified", "classified", "classified", "ambiguous"),
  primary_category = c(
    "Future Skills & Intelligence",
    "Future Skills & Intelligence",
    "Humanity & Love",
    ""
  ),
  secondary_categories = c(
    "",
    "",
    "Temperance & Justice",
    "Humanity & Love|Temperance & Justice"
  ),
  confidence = c(3L, 2L, 2L, 2L),
  rationale = c(
    "The technical build is the clear primary focus.",
    "The reflection is primarily about building and debugging.",
    "Community support appears primary, with governance secondary.",
    "Community and governance appear genuinely co-primary."
  ),
  labelled_without_model_output = c(TRUE, TRUE, TRUE, TRUE),
  stringsAsFactors = FALSE
)

adjudicated <- data.frame(
  reflection_id = c("external_001", "external_002"),
  dataset_version = c("external-v1", "external-v1"),
  status = c("classified", "ambiguous"),
  primary_category = c("Future Skills & Intelligence", ""),
  secondary_categories = c("", "Humanity & Love|Temperance & Justice"),
  adjudication_method = c("discussion_consensus", "discussion_consensus"),
  adjudicator_id = c("review_panel", "review_panel"),
  rationale = c(
    "Independent annotators agreed on the primary technical category.",
    "The panel retained both domains because neither was clearly secondary."
  ),
  frozen = c(TRUE, TRUE),
  stringsAsFactors = FALSE
)

validate_external_dataset_registry(registry)
validate_external_annotations(annotations)
validate_adjudicated_external_labels(adjudicated)
validate_external_evaluation_bundle(registry, annotations, adjudicated)

agreement <- summarise_external_annotation_agreement(annotations)
queue <- build_external_adjudication_queue(annotations)

stopifnot(nrow(agreement) == 2L)
stopifnot(agreement$exact_decision_agreement[agreement$reflection_id == "external_001"])
stopifnot(!agreement$exact_decision_agreement[agreement$reflection_id == "external_002"])
stopifnot(nrow(queue) == 1L)
stopifnot(queue$reflection_id[1L] == "external_002")

bad_annotations <- annotations
bad_annotations$labelled_without_model_output[1L] <- FALSE
error_seen <- FALSE
tryCatch(
  validate_external_annotations(bad_annotations),
  error = function(e) error_seen <<- TRUE
)
stopifnot(error_seen)

cat("Phase 6 external labelling protocol smoke test passed.\n")
