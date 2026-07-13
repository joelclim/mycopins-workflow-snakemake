#!/usr/bin/env Rscript --vanilla

# Generate GBIF event occurrence records from MycoPins data.
# Usage:
#   Rscript generate_gbif_event_occurrence.R <location> <config file> <environment file> <community file> <organisms file> <sample cluster file> <output_file>
# Example:
#   Rscript workflow/scripts/ipt_gbif/generate_gbif_event_occurrence.R
#           oulanka
#           config/config.yaml
#           results/tables/oulanka_mycopins_environment.csv
#           results/tables/oulanka_mycopins_community.csv
#           results/tables/oulanka_mycopins_organisms.csv
#           results/tables/oulanka_mycopins_sample_cluster.csv
#           results/report/ipt_gbif/occurrence.txt

source("workflow/scripts/script_helpers.R")

#
# Requires get_transects(), get_habitat(transect), get_latitude(transect), get_longitude(transect)
#          get_wood_type(site_letter), get_wood_texture(site_letter), get_match_source(source)
#
source("workflow/scripts/ipt_gbif/oulanka_helpers.R")

create_gbif_occurrence_dynamic_properties <- function(site_letter, sample_cluster, organism) {
  dynamic_properties_df <- data.frame(woodType = get_wood_type(site_letter),
                                      woodTexture = get_wood_texture(site_letter))

  if (nrow(sample_cluster) > 0) {
    match_df <- sample_cluster[, c("source", "percent_identity",
                                  "evalue", "bit_score",
                                  "accession", "taxid",
                                  "Count")]

    dynamic_properties_df$match <- list(match_df)
  }

  if (nrow(organism) > 0) {}
    if ('fungal_traits.primary_lifestyle' %in% colnames(organism)) {
      fungal_traits_df <- data.frame(
        primaryLifestyle = organism$fungal_traits.primary_lifestyle,
        secondaryLifestyle = organism$fungal_traits.secondary_lifestyle
      )
      dynamic_properties_df$fungalTraits <- fungal_traits_df
    }
    if ('is_saproxylic' %in% colnames(organism)) {
      dynamic_properties_df$isSaproxylic <- organism$is_saproxylic
    }

  return(dynamic_properties_df)
}

create_gbif_occurrence_record <- function(event_id, occurrence_id,
                                    basis_of_record, organism_quantity_type,
                                    site_letter, specie, sample_cluster,
                                    organism, occurrence_match) {
  get_data_generalizations <- function(organism) {
    if (organism$source == "BLAST") {
      return(paste0("Identified via BLASTn circa 2024-05-01 with ",
                  organism$bit_score, " bit score, ",
                  organism$evalue, " evalue, and ",
                  format(round(organism$percent_identity, 2), nsmall = 2), "% identity."))
    }
    return("Identified via UNITE Fungi 9.0 (2023-07-18) (https://doi.org/10.15156/BIO/2938068)")
  }

  get_taxon_id <- function(organism) {
    return(paste0("https://www.gbif.org/species/", organism$gbif.usage_key))
  }

  get_taxon_concept_id <- function(organism) {
    if (organism$source == "BLAST") {
      return(paste0("NCBI:tx", organism$taxid))
    }

    # UNITE
    tax_id <- strsplit(organism$taxid, split="\\|")
    sh_id <- tax_id[[1]][1]
    seq_dataset <- tax_id[[1]][2]
    return(paste0("UNITE:", sh_id))
  }

  taxon_id <- get_taxon_id(organism)
  taxon_concept_id <- get_taxon_concept_id(organism)
  data_generalizations <- get_data_generalizations(organism)

  organism_quantity <- 0
  if (nrow(occurrence_match) > 0) {
    organism_quantity <- occurrence_match[[ specie ]]
  }

  occurrence_status <- "absent"
  if (organism_quantity > 0) {
    occurrence_status <- "present"
  }

  dynamic_properties_df <- create_gbif_occurrence_dynamic_properties(site_letter, sample_cluster, organism)

  preparations <- paste("DNA extract from a", get_wood_type(site_letter), "MycoPin.")

  occurrence_record <- list(
    occurrenceID = occurrence_id,
    eventID = event_id,
    basisOfRecord = basis_of_record,
    dataGeneralizations = data_generalizations,
    taxonID = taxon_id,
    taxonConceptID = taxon_concept_id,
    organismQuantity = organism_quantity,
    organismQuantityType = organism_quantity_type,
    occurrenceStatus = occurrence_status,
    preparations = preparations,
    scientificName = organism$gbif.scientific_name,
    acceptedNameUsage = organism$gbif.accepted_name_usage,
    originalNameUsage = organism$gbif.original_name_usage,
    kingdom = organism$gbif.kingdom,
    phylum = organism$gbif.phylum,
    class = organism$gbif.class,
    order = organism$gbif.order,
    family = organism$gbif.family,
    genus = organism$gbif.genus,
    taxonRank = organism$gbif.taxon_rank,
    scientificNameAuthorship = organism$gbif.scientific_name_authorship,
    taxonomicStatus = organism$gbif.status,
    dynamicProperties = toJSON(dynamic_properties_df)
  )

  return(occurrence_record)
}

#
# Main function: generate_gbif_occurrence
#
generate_gbif_event_occurrence <- function(
  location,
  basis_of_record,
  organism_quantity_type,
  environment_file,
  community_file,
  organisms_file,
  sample_cluster_file
) {
  substrRight <- function(x, n){
    substr(x, nchar(x)-n+1, nchar(x))
  }
  transects <- get_transects()

  mycopins.environment <- read_csv(environment_file, show_col_types = FALSE,
                                  locale = locale(encoding = "UTF-8"))

  mycopins.community <- read_csv(community_file, show_col_types = FALSE,
                                locale = locale(encoding = "UTF-8"))
  mycopins <- cbind(mycopins.environment, mycopins.community)

  mycopins.organisms <- read_csv(organisms_file, show_col_types = FALSE,
                                locale = locale(encoding = "UTF-8"))

  mycopins.sample_cluster <- read_csv(sample_cluster_file, show_col_types = FALSE,
                                locale = locale(encoding = "UTF-8"))

  gbif_occurrences <- data.frame(
    occurrenceID = character(),
    eventID = character(),
    basisOfRecord = character(),
    dataGeneralizations = character(),
    taxonID = character(),
    taxonConceptID = character(),
    organismQuantity = numeric(),
    organismQuantityType = character(),
    occurrenceStatus = character(),
    preparations = character(),
    scientificName = character(),
    acceptedNameUsage = character(),
    originalNameUsage = character(),
    kingdom = character(),
    phylum = character(),
    class = character(),
    order = character(),
    family = character(),
    genus = character(),
    taxonRank = character(),
    scientificNameAuthorship = character(),
    taxonomicStatus = character()
  )

  species <- unique(sort(names(mycopins.community)))

  execution_time <- system.time({
    transect_count <- length(transects)
    for (i in 1:transect_count) {
      transect <- transects[i]
      collection_dates <- mycopins.environment$Date.Collected[
        mycopins.environment$Transect == transect
      ]
      collection_dates <- as.Date(collection_dates, "%m/%d/%Y")
      collection_dates <- sort(unique(collection_dates))

      collection_date_count <- length(collection_dates)
      for (j in 1:collection_date_count) {
        eventDate <- collection_dates[j]
        date_id <- format(eventDate, "%Y_%b_%d")

        samples <- mycopins.environment %>%
          filter(as.Date(Date.Collected, "%m/%d/%Y") == eventDate
                & Transect == transect) %>%
          arrange(Sample.Number) %>%
          pull(Sample.Number)

        # site = sample
        sample_count <- length(samples)
        for (k in 1:sample_count) {
          sample <- samples[k]
          event_id <- paste0(transect, "_", sample)

          # For wood type and wood texture classification
          site_letter <- substr(sample, nchar(sample), nchar(sample))

          species_count <- length(species)
          for (m in 1:species_count) {
            specie <- species[m]

            if (specie %in% c('mock')) {
              next
            }
            # if (specie %in% c('Fungi', 'Fungus', 'mock')) {
            #   next
            # }

            message(paste0("Transect(", i, "/", transect_count,
                        "); Date.Collected(", j, "/", collection_date_count,
                        "); Sample(", k, "/", sample_count,
                        "); Species(", m, "/", species_count, ")"))


            sample_cluster <- mycopins.sample_cluster %>%
              filter(Transect == transect &
                     Sample.Number == sample &
                     gbif_accepted_name == specie & gbif.kingdom == 'Fungi') %>%
              arrange(-Count)

            organism <- NULL
            if (nrow(sample_cluster) == 0) {
              # absent: first instance of the specie regardless of the transect
              organism <- mycopins.sample_cluster %>%
                            filter(gbif_accepted_name == specie & gbif.kingdom == 'Fungi') %>%
                            dplyr::slice(1)
            } else {
              # present: The most count of the selected sample_cluster records
              organism <- sample_cluster[1, ]
            }

            # absent, gbif.kingdom != 'Fungi'
            if (nrow(organism) != 1) {
              next
            }

            occurrence_id <- paste0(event_id, ":", organism$gbif.usage_key)
            occurrence_match <- mycopins %>%
              filter(Transect == transect
                    & Sample.Number == sample
                    & as.Date(Date.Collected, "%m/%d/%Y") == eventDate)

            occurrence_record <- create_gbif_occurrence_record(event_id, occurrence_id,
                                                          basis_of_record, organism_quantity_type,
                                                          site_letter, specie, sample_cluster,
                                                          organism, occurrence_match)
            gbif_occurrences <- rbind(gbif_occurrences,
                                      as.data.frame(occurrence_record, stringsAsFactors = FALSE))
          }
        }
      }
    }
  })

  message(execution_time)

  return(gbif_occurrences)
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

usage <- "Usage: Rscript generate_gbif_event_occurrence.R <location> <config file> "
         "<environment file> <community file> <organisms file> <sample cluster file> "
         "<output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- get_script_args(
    c("location",
      "config_file",
      "environment_file",
      "community_file",
      "organisms_file",
      "sample_cluster_file",
      "output_file"),
    usage
  )
  config <- load_config(
    args$config_file,
    "ipt_gbif",
    args$location,
    c("location", "basis_of_record", "organism_quantity_type")
  )

  message("=== Configuration for GBIF Event Occurrence generation ===")
  message("              Location: ", config$location)
  message("       Basis of record: ", config$basis_of_record)
  message("Organism quantity type: ", config$organism_quantity_type)
  message("      Environment file: ", args$environment_file)
  message("        Community file: ", args$community_file)
  message("        Organisms file: ", args$organisms_file)
  message("   Sample cluster file: ", args$sample_cluster_file)
  message("           Output file: ", args$output_file)

  result <- generate_gbif_event_occurrence(
    location = config$location,
    basis_of_record = config$basis_of_record,
    organism_quantity_type = config$organism_quantity_type,
    environment_file = args$environment_file,
    community_file = args$community_file,
    organisms_file = args$organisms_file,
    sample_cluster_file = args$sample_cluster_file
  )

  write.csv(result,
    file = args$output_file,
    row.names = FALSE, fileEncoding = "UTF-8"
  )

  message("Done. Output written to: ", args$output_file)
}

main()

# > print(execution_time)
# user  system elapsed
# 300.69    5.06  841.31

#    user  system elapsed
# 5243.58   66.36 5628.10