#!/usr/bin/env Rscript

# Identify the genus-species for each cluster based on the top BLAST match,
# and add this information to the cluster data frame.
# Usage:
#   Rscript identify_clusters.R <batch> <cleaned_clusters_file> <manual_blast_file> <output_file>
# Example:
#   Rscript workflow/scripts/identify_clusters.R
#           fa23_transectC
#           results/tables/fa23_transectC_cleaned_clusters.csv
#           data/blast/manual_blast.csv
#           results/tables/fa23_transectC_complete_clusters.csv

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

usage <- "Usage: Rscript identify_clusters.R <batch> <config file> <cleaned_clusters_file> <manual_blast_file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- get_script_args(
    c("batch", "cleaned_clusters_file", "manual_blast_file", "output_file"),
    usage
  )

  message("     Processing batch: ", args$batch)
  message("Cleaned clusters file: ", args$cleaned_clusters_file)
  message("   Blast results file: ", args$manual_blast_file)

  blast_results_df <- read_csv(args$manual_blast_file,
    show_col_types = FALSE,
    locale = locale(encoding = "UTF-8")
  )
  top_match_df <- top_blast_results_by_cluster(blast_results_df)

  cleaned_clusters_df <- read_csv(args$cleaned_clusters_file,
    show_col_types = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  result <- apply_top_match_to_clusters(top_match_df, cleaned_clusters_df)

  write.csv(result,
    file = args$output_file,
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  message("Done. Output written to: ", args$output_file)
}

main()
