#!/usr/bin/env Rscript

# Merge batches of the same transect into a single environment and community data frame.
# Usage:
#   Rscript reduce_batches.R <batch_environment_file...> <batch_community_file...> <batch_organisms_file...> <batch_sample_clusters_file...> <environment_file> <community_file> <organisms_file> <sample_clusters_file>
# Example:
#   Rscript workflow/scripts/reduce_batches.R results/tables/sp24_transectA-1_mycopins_environment.csv results/tables/sp24_transectA-2_mycopins_environment.csv results/tables/su24_transectA-1_mycopins_environment.csv results/tables/su24_transectA-2_mycopins_environment.csv results/tables/sp24_transectA-1_mycopins_community.csv results/tables/sp24_transectA-2_mycopins_community.csv results/tables/su24_transectA-1_mycopins_community.csv results/tables/su24_transectA-2_mycopins_community.csv results/tables/sp24_transectA-1_mycopins_organisms.csv results/tables/sp24_transectA-2_mycopins_organisms.csv results/tables/su24_transectA-1_mycopins_organisms.csv results/tables/su24_transectA-2_mycopins_organisms.csv results/tables/sp24_transectA-1_mycopins_sample_clusters.csv results/tables/sp24_transectA-2_mycopins_sample_clusters.csv results/tables/su24_transectA-1_mycopins_sample_clusters.csv results/tables/su24_transectA-2_mycopins_sample_clusters.csv results/tables/mycopins_transectA_environment.csv results/tables/mycopins_transectA_community.csv results/tables/mycopins_transectA_organisms.csv results/tables/mycopins_transectA_sample_clusters.csv

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

  return(merged_df[, (ncol(merged.env) + 1):ncol(merged_df)])
}

reduce_batches <- function(batch_env_dfs, batch_comm_dfs) {
  current_env_dfs <- batch_env_dfs
  current_comm_dfs <- batch_comm_dfs

  while (length(current_env_dfs) > 1) {
    next_env_dfs <- list()
    next_comm_dfs <- list()
    next_index <- 1

    for (index in seq(1, length(current_env_dfs), by = 2)) {
      if (index == length(current_env_dfs)) {
        if (next_index == 1) {
          next_env_dfs[[next_index]] <- current_env_dfs[[index]]
          next_comm_dfs[[next_index]] <- current_comm_dfs[[index]]
          next_index <- next_index + 1
          next
        }

        latest_index <- next_index - 1
        merged_env_df <- merge_environments(
          next_env_dfs[[latest_index]],
          current_env_dfs[[index]]
        )
        merged_comm_df <- merge_communities(
          merged_env_df,
          next_comm_dfs[[latest_index]],
          current_comm_dfs[[index]]
        )

        next_env_dfs[[latest_index]] <- merged_env_df
        next_comm_dfs[[latest_index]] <- merged_comm_df
      } else {
        merged_env_df <- merge_environments(
          current_env_dfs[[index]],
          current_env_dfs[[index + 1]]
        )
        merged_comm_df <- merge_communities(
          merged_env_df,
          current_comm_dfs[[index]],
          current_comm_dfs[[index + 1]]
        )

        next_env_dfs[[next_index]] <- merged_env_df
        next_comm_dfs[[next_index]] <- merged_comm_df
        next_index <- next_index + 1
      }
    }

    current_env_dfs <- next_env_dfs
    current_comm_dfs <- next_comm_dfs
  }

  list(
    environment_df = current_env_dfs[[1]],
    community_df = current_comm_dfs[[1]]
  )
}

merge_organisms <- function(first.organisms, second.organisms, fungi_only = FALSE) {
  merged.organisms <- rbind(first.organisms, second.organisms)
  merged.organisms <- cbind(rowId = rownames(merged.organisms), merged.organisms)

  organisms <- unique(merged.organisms$organism)
  if (fungi_only) {
    organisms <- unique(subset(merged.organisms, gbif.taxon_rank != "KINGDOM")$organism)
    organisms <- setdiff(organisms, c("alga",
                                      "fungi", "fungus",
                                      "Fungi", "Fungus",
                                      "mock", "uncultured organism"))
  }

  rows_to_keep <- c()
  for (organism_name in organisms) {
    search_matches <- merged.organisms %>%
      filter(organism == organism_name & match.bit_score >= 200) %>%
      arrange(desc(match.percent_identity), match.evalue)

    best_search_match <- NULL
    if (nrow(search_matches) > 0) {
      rows_to_keep <- c(rows_to_keep, search_matches[1,]$rowId)
    }
  }

  # Keep only best search match rows for each organism
  merged.organisms <- subset(merged.organisms, rowId %in% rows_to_keep)
  # Remove rowId column
  merged.organisms <- subset(merged.organisms, select = -rowId)
  # Sort based on organism
  merged.organisms <- merged.organisms[order(merged.organisms$organism), ]

  return(merged.organisms)
}

reduce_organisms <- function(batch_organisms_dfs, fungi_only = FALSE) {
  while (length(batch_organisms_dfs) > 1) {
    next_organisms_dfs <- list()
    next_index <- 1

    for (index in seq(1, length(batch_organisms_dfs), by = 2)) {
      if (index == length(batch_organisms_dfs)) {
        next_organisms_dfs[[next_index]] <- batch_organisms_dfs[[index]]
        next_index <- next_index + 1
        next
      }

      merged_organisms_df <- merge_organisms(
        batch_organisms_dfs[[index]],
        batch_organisms_dfs[[index + 1]],
        fungi_only = fungi_only
      )

      next_organisms_dfs[[next_index]] <- merged_organisms_df
      next_index <- next_index + 1
    }

    batch_organisms_dfs <- next_organisms_dfs
  }

  return(batch_organisms_dfs[[1]])
}

merge_sample_clusters <- function(first.sample_clusters, second.sample_clusters) {
  merged.sample_clusters <- rbind(first.sample_clusters, second.sample_clusters)

  merged.sample_clusters$Sequence2[is.na(merged.sample_clusters$Sequence2)] <- ""
  merged.sample_clusters$Sequence3[is.na(merged.sample_clusters$Sequence3)] <- ""

  return(merged.sample_clusters)
}

reduce_sample_clusters <- function(batch_sample_clusters_dfs) {
  while (length(batch_sample_clusters_dfs) > 1) {
    next_sample_clusters_dfs <- list()
    next_index <- 1

    for (index in seq(1, length(batch_sample_clusters_dfs), by = 2)) {
      if (index == length(batch_sample_clusters_dfs)) {
        next_sample_clusters_dfs[[next_index]] <- batch_sample_clusters_dfs[[index]]
        next_index <- next_index + 1
        next
      }

      merged_sample_clusters_df <- merge_sample_clusters(
        batch_sample_clusters_dfs[[index]],
        batch_sample_clusters_dfs[[index + 1]]
      )

      next_sample_clusters_dfs[[next_index]] <- merged_sample_clusters_df
      next_index <- next_index + 1
    }

    batch_sample_clusters_dfs <- next_sample_clusters_dfs
  }

  return(batch_sample_clusters_dfs[[1]])
}

# -------------------------------
# Process command-line arguments
# -------------------------------
suppressPackageStartupMessages(if (!require("dplyr")) install.packages("dplyr"))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
source("workflow/scripts/script_helpers.R")

usage <- paste(
  "Usage: Rscript reduce_batches.R ",
  "<batch_environment_file...> <batch_community_file...> ",
  "<batch_organism_file...> <batch_sample_clusters_file...> ",
  "<environment_file> <community_file> <organism_file> <sample_clusters_file>"
)

get_args <- function(raw_args) {
  output_files <- raw_args[(length(raw_args) - 3):length(raw_args)]
  batch_args <- raw_args[1:(length(raw_args) - 4)]

  if (length(batch_args) == 0 || length(batch_args) %% 4 != 0) {
    abort_script(
      paste0(
        usage,
        "\nExpected a multiple of four batch file arguments before the four output files."
      )
    )
  }

  split_point <- length(batch_args) / 4
  list(
    batch_environment_files = batch_args[seq_len(split_point)],
    batch_community_files = batch_args[(split_point + 1):(split_point * 2)],
    batch_organisms_files = batch_args[(split_point * 2 + 1):(split_point * 3)],
    batch_sample_clusters_files = batch_args[(split_point * 3 + 1):length(batch_args)],
    environment_file = output_files[1],
    community_file = output_files[2],
    organism_file = output_files[3],
    sample_clusters_file = output_files[4]
  )
}

# ------------------
# The main function
# ------------------
main <- function() {
  if (exists("snakemake")) {
    # Run via Snakemake's `script:` directive: read the named file-list inputs
    # and scalar outputs directly from the `snakemake` object.
    args <- get_script_args(
      c(
        "batch_environment_files",
        "batch_community_files",
        "batch_organisms_files",
        "batch_sample_clusters_files",
        "environment_file",
        "community_file",
        "organism_file",
        "sample_clusters_file"
      ),
      usage
    )
  } else {
    raw_args <- commandArgs(trailingOnly = TRUE)
    if (length(raw_args) < 8) {
      abort_script(usage)
    }
    args <- get_args(raw_args)
  }

  batch_env_files <- args$batch_environment_files
  batch_comm_files <- args$batch_community_files
  batch_organisms_files <- args$batch_organisms_files
  batch_sample_clusters_files <- args$batch_sample_clusters_files
  message("    Batch environment files: ", paste(batch_env_files, collapse = ", "))
  message("      Batch community files: ", paste(batch_comm_files, collapse = ", "))
  message("      Batch organisms files: ", paste(batch_organisms_files, collapse = ", "))
  message("Batch sample clusters files: ", paste(batch_sample_clusters_files, collapse = ", "))
  message("           Environment file: ", args$environment_file)
  message("             Community file: ", args$community_file)
  message("             Organisms file: ", args$organism_file)
  message("       Sample clusters file: ", args$sample_clusters_file)

  batch_env_dfs <- lapply(batch_env_files, function(file) {
    read_csv(file, show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  })

  batch_comm_dfs <- lapply(batch_comm_files, function(file) {
    read_csv(file, show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  })

  batch_organisms_dfs <- lapply(batch_organisms_files, function(file) {
    read_csv(file, show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  })

  batch_sample_clusters_dfs <- lapply(batch_sample_clusters_files, function(file) {
    read_csv(file, show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  })

  merged_batches <- reduce_batches(batch_env_dfs, batch_comm_dfs)
  merged_env_df <- merged_batches$environment_df
  merged_comm_df <- merged_batches$community_df

  merged_organisms_df <- reduce_organisms(batch_organisms_dfs)
  merged_sample_clusters_df <- reduce_sample_clusters(batch_sample_clusters_dfs)

  write_csv(merged_env_df, args$environment_file)
  write_csv(merged_comm_df, args$community_file)
  write_csv(merged_organisms_df, args$organism_file)
  write_csv(merged_sample_clusters_df, args$sample_clusters_file)

  message(
    "Done. Output written to: ", args$environment_file, ", ",
    args$community_file, ", ", args$organism_file, ", ",
    args$sample_clusters_file
  )
}

main()
