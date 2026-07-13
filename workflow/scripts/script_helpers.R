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

# Resolve named script arguments from the Snakemake S4 `snakemake` object when a
# rule runs the script via the `script:` directive, and fall back to positional
# command-line parsing for standalone `Rscript ...` runs. Each name is looked up
# across params, wildcards, input, and output slots (in that order), so a rule
# must expose a slot whose key matches each requested argument name.
get_script_args <- function(arg_names, usage, abort_fn = abort_script) {
  if (!exists("snakemake")) {
    return(parse_named_args(commandArgs(trailingOnly = TRUE), arg_names, usage, abort_fn))
  }

  sm <- get("snakemake")
  slots <- list(sm@params, sm@wildcards, sm@input, sm@output)

  lookup <- function(name) {
    for (slot in slots) {
      slot_names <- names(slot)
      if (!is.null(slot_names) && name %in% slot_names) {
        return(as.character(slot[[name]]))
      }
    }
    abort_fn(paste0("No Snakemake input/output/param/wildcard named '", name, "'."))
  }

  args <- lapply(arg_names, lookup)
  names(args) <- arg_names
  args
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

# Load a specific batch config section and resolve its fields using the global config context.
load_config <- function(config_file, key_group, key, fields, abort_fn = abort_script) {
  config <- load_yaml_config(config_file)
  key_config <- config[[key_group]][[key]]

  if (is.null(key_config)) {
    abort_fn(paste0("Unknown ", key_group, " in config: ", key))
  }

  if (is.null(fields)) {
    return(key_config)
  }

  context <- c(config[names(config) != key_group], key_config)
  resolved <- lapply(fields, function(field) {
    resolve_config_value(key_config[[field]], context, abort_fn)
  })

  names(resolved) <- fields
  resolved
}
