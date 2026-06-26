suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(if (!require("R6")) install.packages("R6"))
suppressPackageStartupMessages(library(R6))

FungalTraitsDb <- R6Class(
  "FungalTraitsDb",
  public = list(
    data = NULL,

    initialize = function(file_path = "resources/fungaltraits/fungal_traits_for_genera.csv") {
      if (!file.exists(file_path)) {
        stop(paste0("Fungal traits file not found: ", file_path), call. = FALSE)
      }

      self$data <- read_csv(
        file_path,
        show_col_types = FALSE,
        locale = locale(encoding = "UTF-8")
      )
    },

    get_record = function(genus) {
      if (is.null(genus) || length(genus) == 0 || is.na(genus)) {
        return(self$data[0, , drop = FALSE])
      }

      self$data[!is.na(self$data$GENUS) & self$data$GENUS == genus, , drop = FALSE]
    }
  )
)

get_fungal_traits_by_genus <- function(genus,
                                       fungal_traits = FungalTraitsDb$new()) {
  genus_traits <- fungal_traits$get_record(genus)
  if (nrow(genus_traits) == 1) {

    return (c(
      genus_traits$primary_lifestyle,
      # intentationally capitalized to match the column name in the CSV
      genus_traits$Secondary_lifestyle
    ))
  }
  return (c('', ''))
}
