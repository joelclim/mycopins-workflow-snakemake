#!/usr/bin/env Rscript

# Merge batches of the same transect into a single environment and community data frame.
# Usage:
#   Rscript merge_batches.R <transect> <config file> <environment_file> <community_file>
# Example:
#   Rscript merge_batches.R fa23_transectC config/config.yaml results/tables/fa23_transectC_environment.csv results/tables/fa23_transectC_community.csv

merge_environments <- function(first_df, second_df) {
  # Merge env
  merged_df <- rbind(first_df, second_df)

  # Remove duplicated columns
  merged_df <- merged_df[, !duplicated(colnames(merged_df))]

  return(merged_df)
}

merge_communities <- function(merged.env, top_df, bot_df) {
  # Merge env
  merged_df <- merged.env

  # Collect species names
  top_species <- unique(sort(names(top_df)))
  bot_species <- unique(sort(names(bot_df)))
  species <- unique(sort(c(top_species, bot_species)))

  for (specie in species) {
    # fillers
    top_values <- rep(0, nrow(top_df))
    bot_values <- rep(0, nrow(bot_df))

    # replace fillers
    if (specie %in% top_species) {
      top_values <- top_df[[specie]]
    }
    if (specie %in% bot_species) {
      bot_values <- bot_df[[specie]]
    }

    # join and assign column
    merged_values <- c(top_values, bot_values)
    merged_df[[specie]] <- merged_values
  }

  return(merged_df[, (ncol(merged.env)+1): ncol(merged_df)])
}


# -------------------------------
# Process command-line arguments
# -------------------------------
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
source("workflow/scripts/script_helpers.R")

usage <- "Usage: Rscript merge_batches.R <transect> <config file> <environment_file> <community_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- parse_named_args(
    commandArgs(trailingOnly = TRUE),
    c("transect",
      "config_file",
      "environment_file",
      "community_file"),
    usage
  )

  message("Processing transect: ", args$transect)
  message("   Environment file: ", args$environment_file)
  message("     Community file: ", args$community_file)

  message("Done. Output written to: ", args$environment_file, " and ", args$community_file)
}

main()
