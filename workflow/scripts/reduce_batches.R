#!/usr/bin/env Rscript

# Merge batches of the same transect into a single environment and community data frame.
# Usage:
#   Rscript reduce_batches.R <batch_environment_file...> <batch_community_file...> <environment_file> <community_file>
# Example:
#   Rscript reduce_batches.R results/tables/batch1_environment.csv results/tables/batch2_environment.csv results/tables/batch1_community.csv results/tables/batch2_community.csv results/tables/fa23_transectC_environment.csv results/tables/fa23_transectC_community.csv

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

reduce_batches <- function(batch_env_dfs, batch_comm_dfs) {
  if (length(batch_env_dfs) != length(batch_comm_dfs)) {
    stop("Expected the same number of environment and community data frames.", call. = FALSE)
  }

  current_env_dfs <- batch_env_dfs
  current_comm_dfs <- batch_comm_dfs

  while (length(current_env_dfs) > 1) {
    next_env_dfs <- list()
    next_comm_dfs <- list()
    next_index <- 1

    for (index in seq(1, length(current_env_dfs), by = 2)) {
      if (index == length(current_env_dfs)) {
        next_env_dfs[[next_index]] <- current_env_dfs[[index]]
        next_comm_dfs[[next_index]] <- current_comm_dfs[[index]]
      } else {
        merged_env_df <- merge_environments(current_env_dfs[[index]],
                                            current_env_dfs[[index + 1]])
        merged_comm_df <- merge_communities(merged_env_df,
                                            current_comm_dfs[[index]],
                                            current_comm_dfs[[index + 1]])

        next_env_dfs[[next_index]] <- merged_env_df
        next_comm_dfs[[next_index]] <- merged_comm_df
      }

      next_index <- next_index + 1
    }

    current_env_dfs <- next_env_dfs
    current_comm_dfs <- next_comm_dfs
  }

  list(
    environment_df = current_env_dfs[[1]],
    community_df = current_comm_dfs[[1]]
  )
}


# -------------------------------
# Process command-line arguments
# -------------------------------
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
source("workflow/scripts/script_helpers.R")

usage <- paste(
  "Usage: Rscript reduce_batches.R <batch_environment_file...> <batch_community_file...> <environment_file> <community_file>",
  "<batch_environment_file...> <batch_community_file...>",
  "<environment_file> <community_file>"
)

get_args <- function(raw_args) {
  output_files <- raw_args[(length(raw_args) - 1):length(raw_args)]
  batch_args <- raw_args[1:(length(raw_args) - 2)]

  if (length(batch_args) == 0 || length(batch_args) %% 2 != 0) {
    abort_script(
      paste0(
        usage,
        "\nExpected an even number of batch file arguments before the two output files."
      )
    )
  }

  midpoint <- length(batch_args) / 2
  list(
    batch_environment_files = batch_args[seq_len(midpoint)],
    batch_community_files = batch_args[(midpoint + 1):length(batch_args)],
    environment_file = output_files[1],
    community_file = output_files[2]
  )
}

# ------------------
# The main function
# ------------------
main <- function() {
  raw_args <- commandArgs(trailingOnly = TRUE)
  if (length(raw_args) < 4) {
    abort_script(usage)
  }
  args <- get_args(raw_args)

  batch_env_files <- args$batch_environment_files
  batch_comm_files <- args$batch_community_files
  message("Batch environment files: ", paste(batch_env_files, collapse = ", "))
  message("  Batch community files: ", paste(batch_comm_files, collapse = ", "))
  message("       Environment file: ", args$environment_file)
  message("         Community file: ", args$community_file)

  batch_env_dfs <- lapply(batch_env_files, function(file) {
    read_csv(file, show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  })

  batch_comm_dfs <- lapply(batch_comm_files, function(file) {
    read_csv(file, show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  })

  merged_batches <- reduce_batches(batch_env_dfs, batch_comm_dfs)
  merged_env_df <- merged_batches$environment_df
  merged_comm_df <- merged_batches$community_df

  write_csv(merged_env_df, args$environment_file)
  write_csv(merged_comm_df, args$community_file)

  message("Done. Output written to: ", args$environment_file,
          " and ", args$community_file)
}

main()
