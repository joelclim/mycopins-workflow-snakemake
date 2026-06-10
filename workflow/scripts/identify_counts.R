#!/usr/bin/env Rscript

# Identify the genus-species for each count based on the identified clusters, and add this information to the counts data frame.
# Usage:
#   Rscript identify_counts.R <cleaned_counts_file> <complete_clusters_file> <output_file>
# Example:
#   Rscript identify_counts.R results/tables/fa23_transectC_cleaned_counts.csv
#                             results/tables/fa23_transectC_complete_clusters.csv
#                             results/tables/fa23_transectC_complete_counts.csv
#                             results/tables/fa23_transectC_mycopins_environment.csv
#                             results/tables/fa23_transectC_mycopins_community.csv

identify_counts <- function(counts_df,
                            clusters_df,
                            sep_col_name = "_Splitter_") {
  start_col <- which(names(counts_df) == sep_col_name)
  new_counts_df <- counts_df[, 1:start_col]

  names <- unique(sort(clusters_df$gbif_accepted_name))
  for (name in names) {
    # Get cluster ids with a given gbif accepted name
    clusters <- clusters_df$Cluster.ID[clusters_df$gbif_accepted_name == name]

    # Get the row sums of columns with the same name.
    # Add the abundance of the same species found in multiple clusters.
    row_sum <- rowSums(counts_df[names(counts_df) %in% clusters])
    if (sum(row_sum) > 0) {
      new_counts_df[[name]] <- row_sum
    }
  }

  return(new_counts_df)
}

# -------------------------------
# Process command-line arguments
# -------------------------------
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))

usage <- "Usage: Rscript identify_counts.R <cleaned_counts_file> <complete_clusters_file> <output_file>"

abort <- function(message_text) {
  stop(message_text, call. = FALSE)
}

parse_args <- function(args) {
  if (length(args) != 5) {
    abort(usage)
  }

  list(
    cleaned_counts_file = args[[1]],
    complete_clusters_file = args[[2]],
    out_complete_counts_file = args[[3]],
    out_mycopins_environment_file = args[[4]],
    out_mycopins_community_file = args[[5]]
  )
}

# ------------------
# The main function
# ------------------
main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))

  message("   Cleaned counts file: ", args$cleaned_counts_file)
  message("Complete clusters file: ", args$complete_clusters_file)

  cleaned_counts_df <- read_csv(args$cleaned_counts_file,
                                show_col_types = FALSE,
                                locale = locale(encoding = "UTF-8"))

  complete_clusters_df <- read_csv(args$complete_clusters_file,
                                   show_col_types = FALSE,
                                   locale = locale(encoding = "UTF-8"))
  complete_counts_df <- identify_counts(cleaned_counts_df, complete_clusters_df)

  write.csv(complete_counts_df, file = args$out_complete_counts_file,
            row.names = FALSE, fileEncoding = "UTF-8")

  sep_index <- which(names(complete_counts_df) == "_Splitter_")
  environment_df <- complete_counts_df[, 1:(sep_index-1)]
  write.csv(environment_df, file = args$out_mycopins_environment_file,
            row.names = FALSE, fileEncoding = "UTF-8")

  community_df <- complete_counts_df[, (sep_index+1):ncol(complete_counts_df)]
  write.csv(community_df, file = args$out_mycopins_community_file,
            row.names = FALSE, fileEncoding = "UTF-8")

  message("Done. Outputs written to: ",
          args$out_complete_counts_file, ", ",
          args$out_mycopins_environment_file, ", ",
          args$out_mycopins_community_file)
}

main()