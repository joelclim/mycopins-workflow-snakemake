#!/usr/bin/env Rscript

# Identify the genus-species for each cluster based on the top BLAST match, and add this information to the cluster data frame.
# Usage:
#   Rscript identify_clusters.R <batch> <config file> <cleaned_clusters_file> <output_file>
# Example:
#   Rscript identify_clusters.R fa23_transectC config/config.yaml results/tables/fa23_transectC_cleaned_clusters.csv results/tables/fa23_transectC_complete_clusters.csv

source("workflow/scripts/normalize_name.R")
source("workflow/scripts/get_gbif_accepted_name.R")
source("workflow/scripts/top_blast_results_by_cluster.R")
source("workflow/scripts/apply_top_match_to_clusters.R")
source("workflow/scripts/script_helpers.R")

# -------------------------------
# Process command-line arguments
# -------------------------------
suppressPackageStartupMessages(if (!require("dplyr")) install.packages("dplyr"))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))

usage <- "Usage: Rscript identify_clusters.R <batch> <config file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- parse_named_args(
    commandArgs(trailingOnly = TRUE),
    c("batch", "config_file", "cleaned_clusters_file", "output_file"),
    usage
  )
  batch_config <- load_batch_config(
    args$config_file,
    args$batch,
    c("blast_results_file")
  )

  message("     Processing batch: ", args$batch)
  message("Cleaned clusters file: ", args$cleaned_clusters_file)
  message("   Blast results file: ", batch_config$blast_results_file)

  blast_results_df <- read_csv(batch_config$blast_results_file,
                               show_col_types = FALSE,
                               locale = locale(encoding = "UTF-8"))
  top_match_df <- top_blast_results_by_cluster(blast_results_df)

  cleaned_clusters_df <- read_csv(args$cleaned_clusters_file,
                                  show_col_types = FALSE,
                                  locale = locale(encoding = "UTF-8"))
  result <- apply_top_match_to_clusters(top_match_df, cleaned_clusters_df)

  write.csv(result,
            file = args$output_file,
            row.names = FALSE,
            fileEncoding = "UTF-8")
  message("Done. Output written to: ", args$output_file)
}

main()