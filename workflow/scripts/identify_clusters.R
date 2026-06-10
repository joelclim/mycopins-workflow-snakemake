#!/usr/bin/env Rscript

# Identify the genus-species for each cluster based on the top BLAST match, and add this information to the cluster data frame.
# Usage:
#   Rscript identify_clusters.R <transect> <config file> <cleaned_clusters_file> <output_file>
# Example:
#   Rscript identify_clusters.R fa23_transectC config/config.yaml results/tables/fa23_transectC_cleaned_clusters.csv, results/tables/fa23_transectC_complete_clusters.csv

source("workflow/scripts/normalize_name.R")
source("workflow/scripts/get_gbif_accepted_name.R")
source("workflow/scripts/top_blast_results_by_cluster.R")
source("workflow/scripts/apply_top_match_to_clusters.R")

# -------------------------------
# Process command-line arguments
# -------------------------------
suppressPackageStartupMessages(if (!require("dplyr")) install.packages("dplyr"))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(if (!require("yaml")) install.packages("yaml"))
suppressPackageStartupMessages(library(yaml))

usage <- "Usage: Rscript identify_clusters.R <transect> <config file> <output_file>"

abort <- function(message_text) {
  stop(message_text, call. = FALSE)
}

parse_args <- function(args) {
  if (length(args) != 4) {
    abort(usage)
  }

  list(
    transect = args[[1]],
    config_file = args[[2]],
    cleaned_clusters_file = args[[3]],
    output_file = args[[4]]
  )
}

load_transect_config <- function(config_file, transect) {
  config <- yaml::yaml.load_file(config_file)
  transect_config <- config$transects[[transect]]

  if (is.null(transect_config)) {
    abort(paste0("Unknown transect in config: ", transect))
  }

  context <- c(config[names(config) != "transects"], transect_config)

  list(
    blast_results_file = resolve_config_value(transect_config$blast_results_file, context)
  )
}

resolve_config_value <- function(value, context) {
  if (!is.character(value) || length(value) != 1) {
    return(value)
  }

  matches <- gregexpr("\\$\\{[^}]+\\}", value, perl = TRUE)
  placeholders <- regmatches(value, matches)[[1]]

  if (length(placeholders) == 0) {
    return(value)
  }

  resolved <- value
  for (placeholder in placeholders) {
    key <- sub("^\\$\\{([^}]+)\\}$", "\\1", placeholder)
    replacement <- context[[key]]
    if (is.null(replacement)) {
      abort(paste0("Unknown config placeholder: ", placeholder))
    }
    resolved <- gsub(placeholder, replacement, resolved, fixed = TRUE)
  }

  resolved
}

# ------------------
# The main function
# ------------------
main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  transect_config <- load_transect_config(args$config_file, args$transect)

  message("  Processing transect: ", args$transect)
  message("Cleaned clusters file: ", args$cleaned_clusters_file)
  message("   Blast results file: ", transect_config$blast_results_file)

  blast_results_df <- read_csv(transect_config$blast_results_file,
                                  show_col_types = FALSE,
                                  locale = locale(encoding = "UTF-8"))
  top_match_df <- top_blast_results_by_cluster(blast_results_df)

  cleaned_clusters_df <- read_csv(args$cleaned_clusters_file,
                                  show_col_types = FALSE,
                                  locale = locale(encoding = "UTF-8"))
  result <- apply_top_match_to_clusters(top_match_df, cleaned_clusters_df)

  write.csv(result, file = args$output_file, row.names = FALSE, fileEncoding = "UTF-8")
  message("Done. Output written to: ", args$output_file)
}

main()