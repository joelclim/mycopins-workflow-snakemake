suppressPackageStartupMessages(if (!require("jsonlite")) install.packages("jsonlite"))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(if (!require("R6")) install.packages("R6"))
suppressPackageStartupMessages(library(R6))

FUNGuildDb <- R6Class(
  "FUNGuildDb",
  public = list(
    funguild_data = NULL,
    nemaguild_data = NULL,

    initialize = function(
      funguild_file = "resources/funguild/funguild_db.json",
      nemaguild_file = "resources/funguild/nemaguild_db.json"
    ) {
      if (!file.exists(funguild_file)) {
        stop(paste0("FUNGuild file not found: ", funguild_file), call. = FALSE)
      }
      if (!file.exists(nemaguild_file)) {
        stop(paste0("NemaGuild file not found: ", nemaguild_file), call. = FALSE)
      }

      funguild_df <- fromJSON(funguild_file, simplifyDataFrame = TRUE)
      nemaguild_df <- fromJSON(nemaguild_file, simplifyDataFrame = TRUE)

      self$funguild_data <- funguild_df
      self$nemaguild_data <- nemaguild_df
    },

    get_funguild_records = function(taxon) {
      if (is.null(taxon) || length(taxon) == 0 || is.na(taxon)) {
        return(self$funguild_data[0, , drop = FALSE])
      }

      self$funguild_data[!is.na(self$funguild_data$taxon) & self$funguild_data$taxon == taxon, , drop = FALSE]
    },

    get_nemaguild_records = function(taxon) {
      if (is.null(taxon) || length(taxon) == 0 || is.na(taxon)) {
        return(self$nemaguild_data[0, , drop = FALSE])
      }

      self$nemaguild_data[!is.na(self$nemaguild_data$taxon) & self$nemaguild_data$taxon == taxon, , drop = FALSE]
    }
  )
)