
#!/usr/bin/env Rscript --vanilla

#
# Consolidate BLAST results from multiple JSON files into a single CSV file.
# Usage:
#   Rscript consolidate_blast_results.R <config_file> <output_file>
# Example:
#   Rscript workflow/scripts/consolidate_blast_results.R
#           config/config.yaml
#           data/blast/manual_blast.csv
#
source("workflow/scripts/script_helpers.R")

################################################################################
## Convert a BLAST results JSON file to a data frame.
## Consolidates the results for each sequence (3 sequences) for a cluster to a
## a single group.
################################################################################
consolidate_batch_blast_result <- function(blast_result_json, scata_job_id) {
  # Read the JSON file
  json_data <- fromJSON(blast_result_json)

  # Select the desired data points (assuming JSON structure)
  searches <- json_data$BlastOutput2

  cluster_ids <- c()
  job_ids <- c()
  cluster_nums <- c()
  sequence_nums <- c()
  scinames <- c()
  taxids <- c()
  accessions <- c()
  hit_nums <- c()
  evalues <- c()
  evalue_coefficients <- c()
  evalue_exponents <- c()
  bit_scores <- c()
  identities <- c()
  align_lens <- c()
  percent_identities <- c()

  for (i in seq_len(nrow(searches$report$results$search))) {
    query_title <- searches$report$results$search$query_title[i]
    pattern <- paste0(scata_job_id, "_([^\\s]+)_([^\\s]+)")

    cluster_num <- sub(pattern, "\\1", query_title)
    cluster_id <- paste0(scata_job_id, "_", cluster_num)
    sequence_num <- sub(pattern, "\\2", query_title)

    hits <- data.frame(searches$report$results$search$hits[i])
    for (j in seq_len(nrow(hits))) {
      evalue <- hits$hsps[[j]]$evalue
      pattern <- "^([-+]?(?:\\d+\\.?\\d*|\\.\\d+))(?:[eE]([-+]?\\d+))$"

      coefficient <- as.numeric(sub(pattern, "\\1", evalue))
      exponent <- as.numeric(sub(pattern, "\\2", evalue))

      cluster_ids <- c(cluster_ids, cluster_id)
      job_ids <- c(job_ids, scata_job_id)
      cluster_nums <- c(cluster_nums, as.numeric(cluster_num))
      sequence_nums <- c(sequence_nums, as.numeric(sequence_num))
      scinames <- c(scinames, hits$description[[j]]$sciname[1])
      taxids <- c(taxids, hits$description[[j]]$taxid[1])
      accessions <- c(accessions, hits$description[[j]]$accession[1])
      hit_nums <- c(hit_nums, as.numeric(hits$num[[j]]))
      evalues <- c(evalues, as.numeric(evalue[1]))
      evalue_coefficients <- c(evalue_coefficients, as.numeric(coefficient[1]))
      evalue_exponents <- c(evalue_exponents, as.numeric(exponent[1]))
      bit_scores <- c(bit_scores, as.numeric(hits$hsps[[j]]$bit_score[1]))
      identities <- c(identities, as.numeric(hits$hsps[[j]]$identity[1]))
      align_lens <- c(align_lens, as.numeric(hits$hsps[[j]]$align_len[1]))
      percent_identities <- c(percent_identities,
                              (hits$hsps[[j]]$identity[1] /
                                 hits$hsps[[j]]$align_len[1]) * 100)
    }
  }

  blast_results_df <- data.frame(
    cluster_id = cluster_ids,
    job_id = job_ids,
    cluster_num = cluster_nums,
    sequence_num = sequence_nums,
    sciname = scinames,
    taxid = taxids,
    accession = accessions,
    hit_num = hit_nums,
    evalue = evalues,
    evalue_coefficient = evalue_coefficients,
    evalue_exponent = evalue_exponents,
    bit_score = bit_scores,
    identity = identities,
    align_len = align_lens,
    percent_identity = percent_identities
  )
  return(blast_results_df)
}

################################################################################
## Consolidates the BLAST results JSON file into a data frame and save it as a
## CSV file.
################################################################################
consolidate_blast_results <- function(batch_blast_result_dir, scata_job_id) {
  # List files with the specified extension inside the directory
  blast_result_files <- list.files(batch_blast_result_dir,
                                   pattern = ".*\\.fasta\\.json$",
                                   full.names = TRUE, recursive = TRUE)

  # Consolidate each blast results JSON file into a single data frame
  blast_results_df <- NULL
  for (blast_result_json in blast_result_files) {
    message("\t", blast_result_json)
    df <- consolidate_batch_blast_result(blast_result_json, scata_job_id)
    if (0 == length(blast_results_df)) {
      blast_results_df <- df
    } else {
      blast_results_df <- rbind(blast_results_df, df)
    }
  }

  return(blast_results_df)
}



# --------
# Imports
# --------
suppressPackageStartupMessages(if (!require("jsonlite")) install.packages("jsonlite"))
suppressPackageStartupMessages(library(jsonlite))

usage <- "Usage: Rscript consolidate_blast_results.R <config_file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- parse_named_args(
    commandArgs(trailingOnly = TRUE),
    c("config_file", "output_file"),
    usage
  )

  message("Starting BLAST results consolidation...")
  message("Config file: ", args$config_file)
  message("Output file: ", args$output_file)

  config <- load_yaml_config(args$config_file)
  manual_blast_dir <- config[["manual_blast_dir"]]
  message("Manual BLAST results directory: ", manual_blast_dir)

  message("Consolidating BLAST results...")
  result <- data.frame()
  batches <- config[["batches"]]
  for (batch_name in names(batches)) {
    batch_blast_result_dir <- paste0(manual_blast_dir, "/", batch_name)
    scata_job_id <- as.character(batches[[batch_name]]["scata_job_id"])[1]
    message("Batch: ", batch_name,
            "; blast_results_dir: ", batch_blast_result_dir,
            "; scata_job_id: ", scata_job_id)
    blast_results_df <- consolidate_blast_results(batch_blast_result_dir, scata_job_id)
    if (0 == length(result)) {
      result <- blast_results_df
    } else {
      result <- rbind(result, blast_results_df)
    }
  }

  write.csv(result, file = args$output_file, row.names = FALSE, fileEncoding = "UTF-8")

  message("Done. Output written to: ", args$output_file)
}

main()
