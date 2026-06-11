# Stop execution without printing the call stack so script errors stay readable.
abort_script <- function(message_text) {
  stop(message_text, call. = FALSE)
}

# Map positional command-line arguments to named fields and validate arity.
parse_named_args <- function(args, arg_names, usage, abort_fn = abort_script) {
  if (length(args) != length(arg_names)) {
    abort_fn(usage)
  }

  parsed_args <- as.list(args)
  names(parsed_args) <- arg_names
  parsed_args
}

# Load the workflow YAML config, installing the package when needed.
load_yaml_config <- function(config_file) {
  suppressPackageStartupMessages(if (!require("yaml")) install.packages("yaml"))
  yaml::yaml.load_file(config_file)
}

# Replace ${key} placeholders in a config value using the merged config context.
resolve_config_value <- function(value, context, abort_fn = abort_script) {
  if (!is.character(value) || length(value) != 1) {
    return(value)
  }

  matches <- gregexpr("\\$\\{[^}]+\\}", value, perl = TRUE)
  placeholders <- regmatches(value, matches)[[1]]

  if (length(placeholders) == 0) {
    return(value)
  }

  resolved <- value
  for (placeholder in placeholders) {
    key <- sub("^\\$\\{([^}]+)\\}$", "\\1", placeholder)
    replacement <- context[[key]]
    if (is.null(replacement)) {
      abort_fn(paste0("Unknown config placeholder: ", placeholder))
    }
    resolved <- gsub(placeholder, replacement, resolved, fixed = TRUE)
  }

  resolved
}

# Resolve the requested transect fields against top-level and transect-local config values.
load_transect_config <- function(config_file, transect, fields, abort_fn = abort_script) {
  config <- load_yaml_config(config_file)
  transect_config <- config$transects[[transect]]

  if (is.null(transect_config)) {
    abort_fn(paste0("Unknown transect in config: ", transect))
  }

  context <- c(config[names(config) != "transects"], transect_config)
  resolved <- lapply(fields, function(field) {
    resolve_config_value(transect_config[[field]], context, abort_fn)
  })

  names(resolved) <- fields
  resolved
}