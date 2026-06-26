#!/usr/bin/env Rscript

# Capture organism records from GBIF for a list of organisms.
# Usage:
#   Rscript capture_organisms.R <batch> <complete_clusters_file> <output_file>
# Example:
#   Rscript workflow/scripts/capture_organisms.R
#           sp24_transectA-1
#           results/tables/sp24_transectA-1_complete_clusters.csv
#           results/tables/sp24_transectA-1_organisms.csv
#

source("workflow/scripts/script_helpers.R")
source("workflow/scripts/fungaltraits_db.R")
source("workflow/scripts/saproxylicfungi_db.R")

fungaltraits_db <- FungalTraitsDb$new()
saproxylicfungi_db <- SaproxylicFungiDb$new()

# organisms is a list of gbif_accepted_names
capture_organisms <- function(complete_clusters_file) {
  complete_clusters_df <- read_csv(complete_clusters_file,
                                  show_col_types = FALSE,
                                  locale = locale(encoding = "UTF-8"))

  create_organism_record <- function(organism, complete_clusters_df) {
    response <- name_backbone_verbose(name=organism, kingdom="fungi")
    taxon <- response$data

    if (taxon$matchType == "NONE" | organism == "mock") {
      return(c(
        match.source = "",
        match.percent_identity = "",
        match.evalue = "",
        match.bit_score = "",
        match.accession = "",
        match.tax_id = "",
        gbif.match_type = taxon$matchType,
        gbif.usage_key = "",
        gbif.scientific_name = "",
        gbif.accepted_name_usage = "",
        gbif.original_name_usage = "",
        gbif.kingdom = "",
        gbif.phylum = "",
        gbif.class = "",
        gbif.order = "",
        gbif.family = "",
        gbif.genus = "",
        gbif.taxon_rank = "",
        gbif.status = "",
        gbif.scientific_name_authorship = "",
        fungal_traits.primary_lifestyle = "",
        fungal_traits.secondary_lifestyle = "",
        is_saproxylic = ""
      ))
    }

    # Match search results: UNITE or BLAST
    search_matches <- complete_clusters_df %>%
      filter(gbif_accepted_name == organism) %>%
      arrange(desc(percent_identity), evalue)

    best_search_match <- NULL
    if (nrow(search_matches) > 0) {
      best_search_match <- search_matches[1,]
    }

    # Fungal traits of the genus
    genus_traits <- NULL
    if ("genus" %in% names(taxon)) {
      genus_traits <- get_fungal_traits_by_genus(taxon$genus, fungaltraits_db)
    }

    organism_record <- c(
      match.source = ifelse(nrow(best_search_match) == 1,
                             best_search_match$source, ""),
      match.percent_identity = ifelse(nrow(best_search_match) == 1,
                                      best_search_match$percent_identity, ""),
      match.evalue = ifelse(nrow(best_search_match) == 1,
                             best_search_match$evalue, ""),
      match.bit_score = ifelse(nrow(best_search_match) == 1,
                               best_search_match$bit_score, ""),
      match.accession = ifelse(nrow(best_search_match) == 1,
                                best_search_match$accession, ""),
      match.tax_id = ifelse(nrow(best_search_match) == 1,
                             best_search_match$taxid, ""),
      gbif.match_type = ifelse("matchType" %in% names(taxon),
                         taxon$matchType, ""),
      gbif.usage_key = ifelse("usageKey" %in% names(taxon),
                         taxon$usageKey, ""),
      gbif.scientific_name = ifelse("scientificName" %in% names(taxon),
                              taxon$scientificName, ""),
      gbif.accepted_name_usage = ifelse("species" %in% names(taxon),
                                 taxon$species, ""),
      gbif.original_name_usage = ifelse("canonicalName" %in% names(taxon),
                                 taxon$canonicalName, ""),
      gbif.kingdom = ifelse("kingdom" %in% names(taxon), taxon$kingdom, ""),
      gbif.phylum = ifelse("phylum" %in% names(taxon), taxon$phylum, ""),
      gbif.class = ifelse("class" %in% names(taxon), taxon$class, ""),
      gbif.order = ifelse("order" %in% names(taxon), taxon$order, ""),
      gbif.family = ifelse("family" %in% names(taxon), taxon$family, ""),
      gbif.genus = ifelse("genus" %in% names(taxon), taxon$genus, ""),
      gbif.taxon_rank = ifelse("rank" %in% names(taxon), taxon$rank, ""),
      gbif.status = ifelse("status" %in% names(taxon), taxon$status, ""),
      gbif.scientific_name_authorship = ifelse(
        "scientificName" %in% names(taxon) &
        "canonicalName" %in% names(taxon),
        trimws(substring(
          taxon$scientificName,
          nchar(taxon$canonicalName)+1,
          nchar(taxon$scientificName))), ""),
      fungal_traits.primary_lifestyle = ifelse(length(genus_traits) == 2, genus_traits[1], ""),
      fungal_traits.secondary_lifestyle = ifelse(length(genus_traits) == 2 &&
                                                 !is.na(genus_traits[2]), genus_traits[2], ""),
      is_saproxylic = ifelse(saproxylicfungi_db$is_saproxylic(organism), "yes", "no")
    )

    return(organism_record)
  }

  organisms <- unique(sort(complete_clusters_df$gbif_accepted_name))
  organism_df <- data.frame(organism = organisms)

  match.source <- character(nrow(organism_df))
  match.percent_identity <- numeric(nrow(organism_df))
  match.evalue <- numeric(nrow(organism_df))
  match.bit_score <- numeric(nrow(organism_df))
  match.accession <- character(nrow(organism_df))
  match.tax_id <- character(nrow(organism_df))
  gbif.match_type <- character(nrow(organism_df))
  gbif.usage_key <- character(nrow(organism_df))
  gbif.scientific_name <- character(nrow(organism_df))
  gbif.accepted_name_usage <- character(nrow(organism_df))
  gbif.original_name_usage <- character(nrow(organism_df))
  gbif.kingdom <- character(nrow(organism_df))
  gbif.phylum <- character(nrow(organism_df))
  gbif.class <- character(nrow(organism_df))
  gbif.order <- character(nrow(organism_df))
  gbif.family <- character(nrow(organism_df))
  gbif.genus <- character(nrow(organism_df))
  gbif.taxon_rank <- character(nrow(organism_df))
  gbif.status <- character(nrow(organism_df))
  gbif.scientific_name_authorship <- character(nrow(organism_df))
  fungal_traits.primary_lifestyle <- character(nrow(organism_df))
  fungal_traits.secondary_lifestyle <- character(nrow(organism_df))
  is_saproxylic <- character(nrow(organism_df))

  for (i in 1:nrow(organism_df)) {
    taxon <- create_organism_record(organism_df[i, ], complete_clusters_df)
    match.source[i] <- taxon['match.source']
    match.percent_identity[i] <- taxon['match.percent_identity']
    match.evalue[i] <- taxon['match.evalue']
    match.bit_score[i] <- taxon['match.bit_score']
    match.accession[i] <- taxon['match.accession']
    match.tax_id[i] <- taxon['match.tax_id']
    gbif.match_type[i] <- taxon['gbif.match_type']
    gbif.usage_key[i] <- taxon['gbif.usage_key']
    gbif.scientific_name[i] <- taxon['gbif.scientific_name']
    gbif.accepted_name_usage[i] <- taxon['gbif.accepted_name_usage']
    gbif.original_name_usage[i] <- taxon['gbif.original_name_usage']
    gbif.kingdom[i] <- taxon['gbif.kingdom']
    gbif.phylum[i] <- taxon['gbif.phylum']
    gbif.class[i] <- taxon['gbif.class']
    gbif.order[i] <- taxon['gbif.order']
    gbif.family[i] <- taxon['gbif.family']
    gbif.genus[i] <- taxon['gbif.genus']
    gbif.taxon_rank[i] <- taxon['gbif.taxon_rank']
    gbif.status[i] <- taxon['gbif.status']
    gbif.scientific_name_authorship[i] <- taxon['gbif.scientific_name_authorship']
    fungal_traits.primary_lifestyle[i] <- taxon['fungal_traits.primary_lifestyle']
    fungal_traits.secondary_lifestyle[i] <- taxon['fungal_traits.secondary_lifestyle']
    is_saproxylic[i] <- taxon['is_saproxylic']
  }

  organism_df$match.source <- match.source
  organism_df$match.percent_identity <- match.percent_identity
  organism_df$match.evalue <- match.evalue
  organism_df$match.bit_score <- match.bit_score
  organism_df$match.accession <- match.accession
  organism_df$match.tax_id <- match.tax_id
  organism_df$gbif.match_type <- gbif.match_type
  organism_df$gbif.usage_key <- gbif.usage_key
  organism_df$gbif.scientific_name <- gbif.scientific_name
  organism_df$gbif.accepted_name_usage <- gbif.accepted_name_usage
  organism_df$gbif.original_name_usage <- gbif.original_name_usage
  organism_df$gbif.kingdom <- gbif.kingdom
  organism_df$gbif.phylum <- gbif.phylum
  organism_df$gbif.class <- gbif.class
  organism_df$gbif.order <- gbif.order
  organism_df$gbif.family <- gbif.family
  organism_df$gbif.genus <- gbif.genus
  organism_df$gbif.taxon_rank <- gbif.taxon_rank
  organism_df$gbif.status <- gbif.status
  organism_df$gbif.scientific_name_authorship <- gbif.scientific_name_authorship
  organism_df$fungal_traits.primary_lifestyle <- fungal_traits.primary_lifestyle
  organism_df$fungal_traits.secondary_lifestyle <- fungal_traits.secondary_lifestyle
  organism_df$is_saproxylic <- is_saproxylic

  return(organism_df)
}

# --------
# Imports
# --------
suppressPackageStartupMessages(if (!require("dplyr")) install.packages("dplyr"))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(if (!require("rgbif")) install.packages("rgbif"))
suppressPackageStartupMessages(library(rgbif))

usage <- "Usage: Rscript capture_organisms.R <batch> <config file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  options(warn = 2) # Reset warning level to default

  args <- parse_named_args(
    commandArgs(trailingOnly = TRUE),
    c("batch", "complete_clusters_file", "output_file"),
    usage
  )

  message("      Processing batch: ", args$batch)
  message("Complete clusters file: ", args$complete_clusters_file)
  message("           Output file: ", args$output_file)

  result <- capture_organisms(args$complete_clusters_file)

  write.csv(result,
    file = args$output_file,
    row.names = FALSE, fileEncoding = "UTF-8"
  )

  message("Done. Output written to: ", args$output_file)
}

main()
