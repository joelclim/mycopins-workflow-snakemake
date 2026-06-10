#!/usr/bin/env Rscript

# Create a clean clusters data frame for downstream analyses.
# Usage:
#   Rscript clean_scata_clusters.R <transect> <config file> <output_file>
# Example:
#   Rscript clean_scata_clusters.R fa23_transectC config/config.yaml results/tables/fa23_transectC_cleaned_clusters.csv

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
      break  # Exit the loop if end of file is reached
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
          for(i in seq_along(tokens)) {
            token <- tokens[i]
            if (i > 4 & !is.na(suppressWarnings(as.numeric(token)))) {
              end_reference <- token
              break
            }
          }
          left_end_index <- gregexpr(start_reference, line)[[1]][1]
          left_substring <- substring(line, 1, left_end_index-2)
          left_substring <- gsub(";", ",", left_substring)

          right_start_index <- gregexpr(end_reference, line)[[1]][1]
          right_substring <- substring(line, right_start_index, nchar(line))
          right_substring <- gsub(";", ",", right_substring)

          reference <- substring(line, left_end_index, right_start_index-1)
          reference <- gsub(",", "/", reference)

          record <- paste0(left_substring, ",", reference, ",", right_substring)
        } else {
          no_reference_count <- no_reference_count + 1
          record <- gsub(";", ",", record)
        }

        # Write the line to the output file
        cat(record, sep="\n", file = out_con)
      }
    }
  }

  # Close the input and output files
  close(in_con)
  close(out_con)

  suppressMessages(
    df <- read_csv(out_all_clusters_file,
                   show_col_types = FALSE,
                   locale = locale(encoding = "UTF-8"))
  )
  df <- select(df, -contains("..."))

  return(df)
}

# -------------------------------
# Process command-line arguments
# -------------------------------
suppressPackageStartupMessages(if (!require("dplyr")) install.packages("dplyr"))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(if (!require("yaml")) install.packages("yaml"))
suppressPackageStartupMessages(library(yaml))

usage <- "Usage: Rscript clean_scata_clusters.R <transect> <config file> <output_file>"

abort <- function(message_text) {
  stop(message_text, call. = FALSE)
}

parse_args <- function(args) {
  if (length(args) != 3) {
    abort(usage)
  }

  list(
    transect = args[[1]],
    config_file = args[[2]],
    output_file = args[[3]]
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
    cluster_file = resolve_config_value(transect_config$cluster_file, context)
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

  message("Processing transect: ", args$transect)
  message("Scata clusters file: ", transect_config$cluster_file)

  result <- clean_clusters(
    in_all_clusters_file = transect_config$cluster_file,
    out_all_clusters_file = args$output_file
  )

  write.csv(result,
            file = args$output_file,
            row.names = FALSE, fileEncoding = "UTF-8")

  message("Done. Output written to: ", args$output_file)
}

main()