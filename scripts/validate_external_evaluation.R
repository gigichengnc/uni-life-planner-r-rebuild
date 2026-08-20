# Validate a completed Phase 6 external-evaluation bundle.
#
# Usage:
#   Rscript scripts/validate_external_evaluation.R \
#     data/external-evaluation/private/dataset-register.csv \
#     data/external-evaluation/private/annotations.csv \
#     data/external-evaluation/private/adjudicated-labels.csv

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

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop(
    "Expected exactly three CSV paths: dataset registry, independent annotations, ",
    "and adjudicated labels."
  )
}

resolve_path <- function(path) {
  if (grepl("^(/|[A-Za-z]:)", path)) path else file.path(root, path)
}

paths <- vapply(args, resolve_path, character(1))
missing <- paths[!file.exists(paths)]
if (length(missing) > 0L) {
  stop("External-evaluation input files do not exist: ", paste(missing, collapse = ", "))
}

registry <- read.csv(paths[1L], stringsAsFactors = FALSE, check.names = FALSE)
annotations <- read.csv(paths[2L], stringsAsFactors = FALSE, check.names = FALSE)
adjudicated <- read.csv(paths[3L], stringsAsFactors = FALSE, check.names = FALSE)

validate_external_evaluation_bundle(registry, annotations, adjudicated)
agreement <- summarise_external_annotation_agreement(annotations)
queue <- build_external_adjudication_queue(annotations)

cat("External-evaluation bundle passed structural validation.\n")
cat("Reflections:", nrow(registry), "\n")
cat("Exact first-round agreement:", sum(agreement$exact_decision_agreement), "/", nrow(agreement), "\n")
cat("Cases requiring adjudication:", nrow(queue), "\n")

if (nrow(queue) > 0L) {
  print(queue)
}

cat(
  "Reminder: structural validation does not prove that the data were genuinely unseen, ",
  "that annotators were independent, or that publication rights exist.\n",
  sep = ""
)
