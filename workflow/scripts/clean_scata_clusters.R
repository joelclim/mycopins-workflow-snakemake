#!/usr/bin/env Rscript

# Create a clean clusters data frame for downstream analyses.
# Usage:
#   Rscript clean_scata_clusters.R <batch> <blast_fasta_folder> <config file> <output_file>
# Example:
#   Rscript clean_scata_clusters.R
#           fa23_transectC
#           results/blast/fa23_transectC/
#           config/config.yaml
#           results/tables/fa23_transectC_cleaned_clusters.csv

source("workflow/scripts/script_helpers.R")

clean_clusters <- function(in_all_clusters_file, out_all_clusters_file) {
  # Open the input file for reading
  in_con <- file(in_all_clusters_file, "r")

  # Open the output file for writing
  out_con <- file(out_all_clusters_file, "w")

  reference_count <- 0
  no_reference_count <- 0

  found_first_row <- FALSE
  # Read the input file line by line
  while (TRUE) {
    # Read a line from the input file
    line <- readLines(in_con, n = 1)

    # Check if the line is empty
    if (length(line) == 0) {
      break # Exit the loop if end of file is reached
    }

    # Check if the line contains strings delimited by semicolon
    if (grepl(";", line)) {
      if (startsWith(line, "Cluster ID;Cluster Size;")) {
        # Header found
        found_first_row <- TRUE
      }
      if (found_first_row) {
        record <- line

        tokens <- strsplit(line, ";")[[1]]
        if (length(tokens) > 13) {
          reference_count <- reference_count + 1

          start_reference <- tokens[4]
          end_reference <- NULL
          for (i in seq_along(tokens)) {
            token <- tokens[i]
            if (i > 4 & !is.na(suppressWarnings(as.numeric(token)))) {
              end_reference <- token
              break
            }
          }
          left_end_index <- gregexpr(start_reference, line)[[1]][1]
          left_substring <- substring(line, 1, left_end_index - 2)
          left_substring <- gsub(";", ",", left_substring)

          right_start_index <- gregexpr(end_reference, line)[[1]][1]
          right_substring <- substring(line, right_start_index, nchar(line))
          right_substring <- gsub(";", ",", right_substring)

          reference <- substring(line, left_end_index, right_start_index - 1)
          reference <- gsub(",", "/", reference)

          record <- paste0(left_substring, ",", reference, ",", right_substring)
        } else {
          no_reference_count <- no_reference_count + 1
          record <- gsub(";", ",", record)
        }

        # Write the line to the output file
        cat(record, sep = "\n", file = out_con)
      }
    }
  }

  # Close the input and output files
  close(in_con)
  close(out_con)

  suppressMessages(
    df <- read_csv(out_all_clusters_file,
      show_col_types = FALSE,
      locale = locale(encoding = "UTF-8")
    )
  )
  df <- select(df, -contains("..."))

  return(df)
}

create_fasta_files <- function(cleaned_clusters_df,
                               batch_path_prefix,
                               max_sequence_count = 100) {
  no_reference_df <- cleaned_clusters_df[is.na(cleaned_clusters_df$Reference), ]
  search_df <- no_reference_df

  out_files <- c()
  lines <- NULL
  sequence_batch <- 0
  sequence_count <- 0
  for (i in seq_len(nrow(search_df))) {
    row <- search_df[i, ]

    lines <- c(lines, paste0("> ", row["Cluster ID"], "_1"))
    lines <- c(lines, row$Sequence1)
    if (!is.na(row$Sequence2)) {
      lines <- c(lines, paste0("> ", row["Cluster ID"], "_2"))
      lines <- c(lines, row$Sequence2)
    }
    if (!is.na(row$Sequence3)) {
      lines <- c(lines, paste0("> ", row["Cluster ID"], "_3"))
      lines <- c(lines, row$Sequence3)
    }

    sequence_count <- sequence_count + 1

    if (max_sequence_count == sequence_count) {
      sequence_batch <- sequence_batch + 1

      # write a batch of sequences to a file.
      out_file <- paste0(batch_path_prefix, sequence_batch, ".fasta")
      file_con <- file(out_file)
      writeLines(lines, file_con)
      close(file_con)
      out_files <- c(out_files, out_file)

      lines <- NULL
      sequence_count <- 0
    }
  }

  if (sequence_count > 0) {
    # write the last remaining batch of sequences to a file.
    sequence_batch <- sequence_batch + 1
    out_file <- paste0(batch_path_prefix, sequence_batch, ".fasta")
    file_con <- file(out_file)
    writeLines(lines, file_con)
    close(file_con)
    out_files <- c(out_files, out_file)
  }

  return(out_files)
}


# --------
# Imports
# --------
suppressPackageStartupMessages(if (!require("dplyr")) install.packages("dplyr"))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))

usage <- "Usage: Rscript clean_scata_clusters.R <batch> <blast_fasta_folder> <config file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- get_script_args(
    c("batch", "blast_fasta_folder", "config_file", "output_file"),
    usage
  )
  batch_config <- load_config(
    args$config_file,
    "batches",
    args$batch,
    c("cluster_file")
  )

  message("   Processing batch: ", args$batch)
  message(" BLAST fasta folder: ", args$blast_fasta_folder)
  message("Scata clusters file: ", batch_config$cluster_file)

  # Create the output folder for fasta files if it doesn't exist
  dir.create(args$blast_fasta_folder, recursive = TRUE, showWarnings = FALSE)

  result <- clean_clusters(
    in_all_clusters_file = batch_config$cluster_file,
    out_all_clusters_file = args$output_file
  )

  fasta_files <- create_fasta_files(
    batch_path_prefix = paste0(args$blast_fasta_folder, args$batch, "-"),
    cleaned_clusters_df = result
  )

  write.csv(result,
    file = args$output_file,
    row.names = FALSE, fileEncoding = "UTF-8"
  )

  message("Done. Output written to: ", args$output_file,
    " and fasta files: ", paste(fasta_files, collapse = ", "))
}

main()
