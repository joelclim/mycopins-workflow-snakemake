#!/usr/bin/env Rscript

# Generate GBIF event core records from MycoPins data.
# Usage:
#   Rscript generate_gbif_event_core.R <location> <config file> <environment file> <output_file>
# Example:
#   Rscript workflow/scripts/ipt_gbif/generate_gbif_event_core.R
#           oulanka
#           config/config.yaml
#           results/tables/oulanka_mycopins_environment.csv
#           results/report/ipt_gbif/event.txt

source("workflow/scripts/script_helpers.R")

#
# Requires get_transects(), get_habitat(transect), get_latitude(transect), get_longitude(transect)
#
source("workflow/scripts/ipt_gbif/oulanka_helpers.R")

source("workflow/scripts/weather_db.R")
weather_db <- WeatherDb$new()

create_gbif_event_dynamic_properties <- function(site_letter, env_record) {
  dynamic_properties_df <- data.frame(
    woodType = get_wood_type(site_letter),
    woodTexture = get_wood_texture(site_letter)
  )

  transect <- env_record$Transect
  collection_date <- env_record$Date.Collected

  weather_record <- weather_db$get_record(transect, collection_date)
  if (nrow(weather_record) == 1) {
    dynamic_properties_df <- cbind(dynamic_properties_df, weather_record)
  }

  return(dynamic_properties_df)
}

generate_gbif_event_core <- function(
  location,
  samplingProtocol,
  locationID,
  countryCode,
  country,
  stateProvince,
  municipality,
  environment_file
) {
  message("=== Generating GBIF Event Core for location: ", location, " ===")
  transects <- get_transects()

  mycopins.environment <- read_csv(environment_file,
    show_col_types = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  gbif_events <- data.frame(
    eventID = character(),
    parentEventID = character(),
    samplingProtocol = character(),
    samplingEffort = character(),
    eventDate = character(),
    habitat = character(),
    fieldNotes = character(),
    locationID = character(),
    countryCode = character(),
    country = character(),
    stateProvince = character(),
    municipality = character(),
    decimalLatitude = character(),
    decimalLongitude = character()
  )

  for (i in 1:length(transects)) {
    transect <- transects[i]
    collection_dates <- mycopins.environment$Date.Collected[
      mycopins.environment$Transect == transect
    ]
    collection_dates <- as.Date(collection_dates, "%m/%d/%Y")
    collection_dates <- sort(unique(collection_dates))
    for (j in 1:length(collection_dates)) {
      eventDate <- collection_dates[j]
      message(paste("Transect:", transect, "; Date.Collected:", eventDate))

      date_id <- format(eventDate, "%Y_%b_%d")
      env_record <- mycopins.environment %>%
        filter(as.Date(Date.Collected, "%m/%d/%Y") == eventDate &
          Transect == transect) %>%
        dplyr::slice(1)
      if (nrow(env_record) == 1) { # exists
        parentEventID <- paste0(transect, "_", date_id)
        samplingEffort <- paste(env_record$Days.Elapsed, "days")
        fieldNotes <- env_record$Season
        decimalLatitude <- get_latitude(transect)
        decimalLongitude <- get_longitude(transect)

        sites <- mycopins.environment %>%
          filter(as.Date(Date.Collected, "%m/%d/%Y") == eventDate &
            Transect == transect) %>%
          arrange(Sample.Number) %>%
          pull(Sample.Number)

        for (k in 1:length(sites)) {
          site <- sites[k]
          eventID <- paste0(transect, "_", site)

          site_letter <- substr(site, nchar(site), nchar(site))
          wood_type <- get_wood_type(site_letter)
          wood_texture <- get_wood_texture(site_letter)
          habitat <- paste0(wood_type, "(", wood_texture, ") dowel ", get_habitat(transect))

          dynamic_properties_df <- create_gbif_event_dynamic_properties(site_letter, env_record)

          row <- list(
            eventID = eventID,
            parentEventID = parentEventID,
            samplingProtocol = samplingProtocol,
            samplingEffort = samplingEffort,
            eventDate = eventDate,
            habitat = habitat,
            fieldNotes = fieldNotes,
            locationID = locationID,
            countryCode = countryCode,
            country = country,
            stateProvince = stateProvince,
            municipality = municipality,
            decimalLatitude = decimalLatitude,
            decimalLongitude = decimalLongitude,
            dynamicProperties = toJSON(dynamic_properties_df)
          )
          gbif_events <- rbind(gbif_events, as.data.frame(row, stringsAsFactors = FALSE))
        }
      } else {
        message(paste("Transect", transect, "has nothing collected on", eventDate))
      }
    }
  }

  return(gbif_events)
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

usage <- "Usage: Rscript generate_gbif_event_core.R <location> <config file> <environment file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- get_script_args(
    c("location", "config_file", "environment_file", "output_file"),
    usage
  )
  config <- load_config(
    args$config_file,
    "ipt_gbif",
    args$location,
    c("location", "sampling_protocol", "location_id", "country_code", "country", "state_province", "municipality")
  )

  message("=== Configuration for GBIF Event Core generation ===")
  message("        Location: ", config$location)
  message(" Sample protocol: ", config$sampling_protocol)
  message("     Location ID: ", config$location_id)
  message("    Country code: ", config$country_code)
  message("         Country: ", config$country)
  message("  State/Province: ", config$state_province)
  message("    Municipality: ", config$municipality)
  message("Environment file: ", args$environment_file)
  message("     Output file: ", args$output_file)

  result <- generate_gbif_event_core(
    location = config$location,
    samplingProtocol = config$sampling_protocol,
    locationID = config$location_id,
    countryCode = config$country_code,
    country = config$country,
    stateProvince = config$state_province,
    municipality = config$municipality,
    environment_file = args$environment_file
  )

  write.csv(result,
    file = args$output_file,
    row.names = FALSE, fileEncoding = "UTF-8"
  )

  message("Done. Output written to: ", args$output_file)
}

main()
