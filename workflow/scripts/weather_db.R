suppressPackageStartupMessages(if (!require("readr")) install.packages("readr"))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(if (!require("R6")) install.packages("R6"))
suppressPackageStartupMessages(library(R6))

WeatherDb <- R6Class(
  "WeatherDb",
  public = list(
    data = NULL,

    initialize = function(file_path = "resources/weatherstack_weather.csv") {
      if (!file.exists(file_path)) {
        stop(paste0("Weather DB file not found: ", file_path), call. = FALSE)
      }

      self$data <- read_csv(
        file_path,
        show_col_types = FALSE,
        locale = locale(encoding = "UTF-8")
      )
    },

    get_record = function(transect, collection_date) {
      if (is.null(transect) || length(transect) == 0 || is.na(transect)) {
        return(self$data[0, , drop = FALSE])
      }
      if (is.null(collection_date) || length(collection_date) == 0 || is.na(collection_date)) {
        return(self$data[0, , drop = FALSE])
      }

      target_date <- tryCatch(as.Date(collection_date, "%m/%d/%Y"), error = function(e) NA)
      if (is.na(target_date)) {
        return(self$data[0, , drop = FALSE])
      }
      main_record <- self$data %>%
        filter(transect == as.character(transect) & as.Date(date, "%m/%d/%Y") == target_date) %>%
        dplyr::slice(1) %>%
        select(mintemp, maxtemp, avgtemp, totalsnow, sunhour, uv_index)

      summary_record <- self$data %>%
        filter(as.Date(date, "%m/%d/%Y") == target_date) %>%
        summarise(
          minprecip = min(precip),
          maxprecip = max(precip),
          avgprecip = mean(precip),
          minhumidity = min(humidity),
          maxhumidity = max(humidity),
          avghumidity = mean(humidity),
          minpressure = min(pressure),
          maxpressure = max(pressure),
          avgpressure = mean(pressure),
          minheatindex = min(heatindex),
          maxheatindex = max(heatindex),
          avgheatindex = mean(heatindex),
          mindewpoint = min(dewpoint),
          maxdewpoint = max(dewpoint),
          avgdewpoint = mean(dewpoint),
          minfeelslike = min(feelslike),
          maxfeelslike = max(feelslike),
          avgfeelslike = mean(feelslike)
        )
      return(cbind(main_record, summary_record))
    }
  )
)
