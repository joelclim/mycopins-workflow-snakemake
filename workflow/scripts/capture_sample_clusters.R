#!/usr/bin/env Rscript

# Capture sample clusters and enrich with GBIF taxonomy, fungal traits,
# and saproxylic fungi information.
# Usage:
#   Rscript capture_sample_clusters.R <batch> <cleaned_counts_file> <complete_clusters_file> <output_file>
# Example:
#   Rscript workflow/scripts/capture_sample_clusters.R
#           su24_transectA-2
#           results/tables/su24_transectA-2_cleaned_counts.csv
#           results/tables/su24_transectA-2_complete_clusters.csv
#           results/tables/su24_transectA-2_sample_clusters.csv

source("workflow/scripts/script_helpers.R")
source("workflow/scripts/fungaltraits_db.R")
source("workflow/scripts/saproxylicfungi_db.R")

fungaltraits_db <- FungalTraitsDb$new()
saproxylicfungi_db <- SaproxylicFungiDb$new()

get_gbif_taxonomy_by_accepted_name <- function(gbif_accepted_name) {
  response <- name_backbone_verbose(name=gbif_accepted_name, kingdom="fungi")
  taxon <- response$data

  gbif_taxon_df <- data.frame(
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
        nchar(taxon$scientificName))), "")
  )

  return(gbif_taxon_df)
}

capture_sample_clusters <- function(cleaned_counts_file, complete_clusters_file) {
  cleaned_counts_df <- read_csv(cleaned_counts_file,
                                show_col_types = FALSE,
                                locale = locale(encoding = "UTF-8"))

  complete_clusters_df <- read_csv(complete_clusters_file,
                                  show_col_types = FALSE,
                                  locale = locale(encoding = "UTF-8"))

  pivot_cluster_id_df <- cleaned_counts_df %>%
    pivot_longer(
      cols = starts_with("scata"),  # Select columns to pivot
      names_to = "Cluster.ID",      # New column for column names
      values_to = "Count"           # New column for values
    ) %>%
    filter(Count > 0) %>%           # Retain only rows where count > 0
    select(Transect, Sample.Number, Forward.Primer, Reverse.Primer, Cluster.ID, Count, )

  sample_cluster_df <- pivot_cluster_id_df %>%
    inner_join(complete_clusters_df, by='Cluster.ID')

  #
  # GBIF Taxonomy
  #
  gbif_taxon_df <- t(apply(sample_cluster_df, 1,
    function(row) {
      gbif_taxon <- get_gbif_taxonomy_by_accepted_name(row['gbif_accepted_name'])
      return(c(
        gbif_taxon$gbif.match_type,
        gbif_taxon$gbif.usage_key,
        gbif_taxon$gbif.scientific_name,
        gbif_taxon$gbif.accepted_name_usage,
        gbif_taxon$gbif.original_name_usage,
        gbif_taxon$gbif.kingdom,
        gbif_taxon$gbif.phylum,
        gbif_taxon$gbif.class,
        gbif_taxon$gbif.order,
        gbif_taxon$gbif.family,
        gbif_taxon$gbif.genus,
        gbif_taxon$gbif.taxon_rank,
        gbif_taxon$gbif.status,
        gbif_taxon$gbif.scientific_name_authorship
      ))
    }))

  # Convert to data frame and give appropriate column names
  gbif_taxon_df <- data.frame(gbif_taxon_df)
  colnames(gbif_taxon_df) <- c(
    'gbif.match_type',
    'gbif.usage_key',
    'gbif.scientific_name',
    'gbif.accepted_name_usage',
    'gbif.original_name_usage',
    'gbif.kingdom',
    'gbif.phylum',
    'gbif.class',
    'gbif.order',
    'gbif.family',
    'gbif.genus',
    'gbif.taxon_rank',
    'gbif.status',
    'gbif.scientific_name_authorship'
  )

  # Bind the new columns to the original data frame
  sample_cluster_df <- cbind(sample_cluster_df, gbif_taxon_df)

  #
  # Fungal Traits
  #
  genus_traits_df <- t(apply(sample_cluster_df, 1,
    function(row) {
      genus_traits <- get_fungal_traits_by_genus(row['gbif.genus'], fungaltraits_db)
      return (c(
        ifelse(length(genus_traits) == 2, genus_traits[1], ""),
        ifelse(length(genus_traits) == 2 && !is.na(genus_traits[2]), genus_traits[2], "")
      ))
    }
  ))

  # Convert to data frame and give appropriate column names
  genus_traits_df <- data.frame(genus_traits_df)
  colnames(genus_traits_df) <- c(
    'fungal_traits.primary_lifestyle',
    'fungal_traits.secondary_lifestyle'
  )

  #
  # Saproxylic Fungi
  #
  saproxylic_df <- apply(sample_cluster_df, 1,
    function(row) {
      return (ifelse(saproxylicfungi_db$is_saproxylic(row['gbif_accepted_name']), "yes", "no"))
    }
  )

  # Convert to data frame and give appropriate column names
  saproxylic_df <- data.frame(saproxylic_df)
  colnames(saproxylic_df) <- c('is_saproxylic')

  # Bind the new columns to the original data frame
  sample_cluster_df <- cbind(sample_cluster_df, genus_traits_df, saproxylic_df)

  return(sample_cluster_df)
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
suppressPackageStartupMessages(if (!require("tidyr")) install.packages("tidyr"))
suppressPackageStartupMessages(library(tidyr))

usage <- "Usage: Rscript capture_sample_clusters.R <batch> <cleaned_counts_file> <complete_clusters_file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- get_script_args(
    c("batch", "cleaned_counts_file", "complete_clusters_file", "output_file"),
    usage
  )

  message("      Processing batch: ", args$batch)
  message("   Cleaned counts file: ", args$cleaned_counts_file)
  message("Complete clusters file: ", args$complete_clusters_file)
  message("           Output file: ", args$output_file)

  result <- capture_sample_clusters(args$cleaned_counts_file, args$complete_clusters_file)

  write.csv(result,
    file = args$output_file,
    row.names = FALSE, fileEncoding = "UTF-8"
  )

  message("Done. Output written to: ", args$output_file)
}

main()
