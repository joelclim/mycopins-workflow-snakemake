#!/usr/bin/env Rscript

# Generate GBIF DNA derived records from MycoPins data.
# Usage:
#   Rscript generate_gbif_dna_derived.R <config file> <community file> <sample cluster file> <output_file>
# Example:
#   Rscript workflow/scripts/ipt-gbif/generate_gbif_dna_derived.R
#           config/config.yaml
#           results/tables/oulanka_mycopins_community.csv
#           results/tables/oulanka_mycopins_sample_cluster.csv
#           results/reports/gbif/dna_derived.txt

source("workflow/scripts/script_helpers.R")

generate_dna_derived <- function(
  lib_layout,
  target_gene,
  target_subfragment,
  seq_method,
  otu_db,
  pcr_primer_name_forward,
  pcr_primer_name_reverse,
  pcr_primer_reference,
  community_file,
  sample_cluster_file) {
  get_samp_taxon_id <- function(source, taxid) {
    if (source == "BLAST") {
      return(paste0("NCBI:tx", taxid))
    }

    # UNITE
    tax_id <- strsplit(taxid, split = "\\|")
    sh_id <- tax_id[[1]][1]
    seq_dataset <- tax_id[[1]][2]
    return(paste0("UNITE:", sh_id))
  }

  mycopins.community <- read_csv(community_file,
    show_col_types = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  mycopins.sample_cluster <- read_csv(sample_cluster_file,
    show_col_types = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  species <- unique(sort(names(mycopins.community)))

  gbif_dna_derived_df <- mycopins.sample_cluster %>%
    pivot_longer(
      cols = starts_with("Sequence"),
      names_to = "SeqRep",
      values_to = "DNA_sequence"
    ) %>%
    filter(
      (gbif_accepted_name %in% species) &
        !(gbif_accepted_name %in% c("Fungi", "Fungus", "mock")) &
        !(gbif.kingdom %in% c("Plantae")) &
        !is.na(DNA_sequence)
    ) %>%
    mutate(
      eventID = paste(Transect, Sample.Number, sep = "_"),
      occurrenceID = paste(paste(Transect, Sample.Number, sep = "_"), gbif.usage_key, sep = ":"),
      samp_taxon_id = mapply(get_samp_taxon_id, source, taxid),
      lib_layout = lib_layout,
      target_gene = target_gene,
      target_subfragment = target_subfragment,
      seq_meth = seq_method,
      otu_db = otu_db,
      pcr_primer_name_forward = pcr_primer_name_forward,
      pcr_primer_name_reverse = pcr_primer_name_reverse,
      pcr_primer_reference = pcr_primer_reference
    ) %>%
    select(eventID,
      occurrenceID,
      samp_name = Sample.Number,
      samp_taxon_id,
      lib_layout,
      target_gene,
      target_subfragment,
      seq_meth,
      otu_db,
      organism = gbif_accepted_name,
      pcr_primer_forward = Forward.Primer,
      pcr_primer_reverse = Reverse.Primer,
      pcr_primer_name_forward,
      pcr_primer_name_reverse,
      pcr_primer_reference,
      DNA_sequence
    )

  return(gbif_dna_derived_df)
}

# --------
# Imports
# --------
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(if (!require("tidyr")) install.packages("tidyr"))
suppressPackageStartupMessages(library(tidyr))

usage <- "Usage: Rscript generate_gbif_dna_derived.R <config file> <community file> <sample cluster file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- parse_named_args(
    commandArgs(trailingOnly = TRUE),
    c("config_file", "community_file", "sample_cluster_file", "output_file"),
    usage
  )
  config <- load_config(
    args$config_file,
    "ipt_gbif",
    args$location,
    c("lib_layout", "target_gene", "target_subfragment",
      "seq_method", "otu_db", "pcr_primer_name_forward",
      "pcr_primer_name_reverse", "pcr_primer_reference")
  )
  message("=== Configuration for GBIF DNA Derived generation ===")
  message("             Lib Layout: ", config$lib_layout)
  message("            Target Gene: ", config$target_gene)
  message("     Target Subfragment: ", config$target_subfragment)
  message("             Seq Method: ", config$seq_method)
  message("                 OTU DB: ", config$otu_db)
  message("PCR Primer Name Forward: ", config$pcr_primer_name_forward)
  message("PCR Primer Name Reverse: ", config$pcr_primer_name_reverse)
  message("   PCR Primer Reference: ", config$pcr_primer_reference)
  message("         Community file: ", args$community_file)
  message("    Sample cluster file: ", args$sample_cluster_file)
  message("            Output file: ", args$output_file)

  result <- generate_gbif_dna_derived(
    lib_layout = config$lib_layout,
    target_gene = config$target_gene,
    target_subfragment = config$target_subfragment,
    seq_method = config$seq_method,
    otu_db = config$otu_db,
    pcr_primer_name_forward = config$pcr_primer_name_forward,
    pcr_primer_name_reverse = config$pcr_primer_name_reverse,
    pcr_primer_reference = config$pcr_primer_reference,
    community_file = args$community_file,
    sample_cluster_file = args$sample_cluster_file
  )

  write.csv(result,
    file = args$output_file,
    row.names = FALSE, fileEncoding = "UTF-8"
  )

  message("Done. Output written to: ", args$output_file)
}

main()
