suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(if (!require("R6")) install.packages("R6"))
suppressPackageStartupMessages(library(R6))

SaproxylicFungiDb <- R6Class(
  "SaproxylicFungiDb",
  public = list(
    data = NULL,

    initialize = function(file_path = "resources/kean_saproxylic_fungi_db.csv") {
      if (!file.exists(file_path)) {
        stop(paste0("Saproxylic fungi DB file not found: ", file_path), call. = FALSE)
      }

      self$data <- read_csv(
        file_path,
        show_col_types = FALSE,
        locale = locale(encoding = "UTF-8")
      )
    },

    get_record = function(taxon) {
      if (is.null(taxon) || length(taxon) == 0 || is.na(taxon)) {
        return(self$data[0, , drop = FALSE])
      }

      self$data[!is.na(self$data$taxon) & self$data$taxon == taxon, , drop = FALSE]
    },

    is_saproxylic = function(taxon) {
      if (is.null(taxon) || length(taxon) == 0 || is.na(taxon)) {
        return(FALSE)
      }

      records <- self$get_record(taxon)
      if (nrow(records) == 0 || !("saproxylic" %in% names(records))) {
        return(FALSE)
      }

      values <- tolower(trimws(as.character(records$saproxylic)))
      any(values %in% c("yes", "true", "1"))
    }
  )
)