#!/usr/bin/env Rscript

# Generate GBIF occurrence core records from MycoPins data.
# Usage:
#   Rscript generate_gbif_occurrence_core.R <event core file> <event occurrence file> <output_file>
# Example:
#   Rscript workflow/scripts/ipt_gbif/generate_gbif_occurrence_core.R
#           results/report/ipt_gbif/event.txt
#           results/report/ipt_gbif/event_occurrence.txt
#           results/report/ipt_gbif/occurrence_core.txt

source("workflow/scripts/script_helpers.R")

generate_gbif_occurrence_core <- function(event_core_file, event_occurrence_file) {
  event_core_df <- read_csv(event_core_file, show_col_types = FALSE,
                                locale = locale(encoding = "UTF-8"))

  event_occurrence_df <- read_csv(event_occurrence_file, show_col_types = FALSE,
                            locale = locale(encoding = "UTF-8"))

  occurrence_core_df <- event_occurrence_df %>%
                        inner_join(event_core_df, by = "eventID")

  merge_dynamic_properties <- function(json_str1, json_str2) {
    list1 <- fromJSON(json_str1)
    list2 <- fromJSON(json_str2)

    # Combine the lists
    merged_list <- list1

    # Iterate through the keys of list2
    for (key in names(list2)) {
      if (!key %in% names(list1)) {
        merged_list[[key]] <- list2[[key]]
      }
    }

    # Convert the merged list back to JSON
    toJSON(merged_list, auto_unbox = TRUE)
  }

  occurrence_core_df$dynamicProperties <- mapply(merge_dynamic_properties,
                          occurrence_core_df$dynamicProperties.x,
                          occurrence_core_df$dynamicProperties.y)

  occurrence_core_df <- occurrence_core_df[,
    !(names(occurrence_core_df) %in% c("dynamicProperties.x", "dynamicProperties.y"))]

  return(occurrence_core_df)
}

# --------
# Imports
# --------
suppressPackageStartupMessages(if (!require("dplyr")) install.packages("dplyr"))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(if (!require("jsonlite")) install.packages("jsonlite"))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))

usage <- "Usage: Rscript generate_gbif_occurrence_core.R <event core file> <event occurrence file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- get_script_args(
    c("event_core_file", "event_occurrence_file", "output_file"),
    usage
  )
  message("=== Configuration for GBIF Event Core Occurrence generation ===")
  message("      Event core file: ", args$event_core_file)
  message("Event occurrence file: ", args$event_occurrence_file)
  message("          Output file: ", args$output_file)

  result <- generate_gbif_occurrence_core(
    event_core_file = args$event_core_file,
    event_occurrence_file = args$event_occurrence_file
  )

  write.csv(result,
    file = args$output_file,
    row.names = FALSE, fileEncoding = "UTF-8"
  )

  message("Done. Output written to: ", args$output_file)
}

main()
