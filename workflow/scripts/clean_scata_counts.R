#!/usr/bin/env Rscript

# Create a clean counts data frame for downstream analyses.
# Usage:
#   Rscript clean_scata_counts.R <batch> <config file> <output_file>
# Example:
#   Rscript clean_scata_counts.R fa23_transectC config/config.yaml results/tables/fa23_transectC_cleaned_counts.csv

source("workflow/scripts/script_helpers.R")

# ---------------------
# Function definitions
# ---------------------
clean_counts <- function(scata_counts_file,
                         env_file,
                         dataset_name,
                         cleaned_counts_qc_file,
                         minimum_count = 3,
                         sep_col_name = "_Splitter_") {
  # Start from the subset of counts/env rows that refer to the same tags,
  # with rows explicitly aligned so downstream sample metadata stays matched.
  aligned_data <- clean_counts.load_aligned_data(
    scata_counts_file = scata_counts_file,
    env_file = env_file,
    dataset_name = dataset_name
  )

  # Record QC information before clusters are removed so the report reflects
  # the original matched count matrix.
  counts <- clean_counts.mark_zero_count_tags(aligned_data$counts)
  qc_stats <- c(
    aligned_data$qc_stats,
    list(
      counts.tags_with_zero_counts = counts$tags_with_zero_counts,
      cluster_counts = clean_counts.cluster_column_count(counts$data)
    )
  )

  # Drop clusters triggered by positive controls, then repeat for negative
  # controls on the already-filtered matrix.
  pos_filter <- clean_counts.remove_control_clusters(
    counts = counts$data,
    env_df = aligned_data$env_df,
    control = "POS",
    minimum_count = minimum_count
  )

  neg_filter <- clean_counts.remove_control_clusters(
    counts = pos_filter$counts,
    env_df = pos_filter$env_df,
    control = "NEG",
    minimum_count = minimum_count
  )

  # Only the cluster abundance columns participate in small-cluster pruning.
  community_df <- clean_counts.community_matrix(neg_filter$counts)
  small_clusters <- clean_counts.get_small_clusters(community_df, minimum_count)
  community_df <- clean_counts.drop_columns(community_df, small_clusters)

  # Build the human-readable QC report from the accumulated stats and the
  # final filtered matrix that will be written out.
  qc_lines <- clean_counts.build_qc_lines(
    qc_stats = qc_stats,
    final_env_df = neg_filter$env_df,
    community_df = community_df,
    minimum_count = minimum_count,
    counts.cols_with_pos = pos_filter$removed_clusters,
    counts.cols_with_neg = neg_filter$removed_clusters,
    small_clusters = small_clusters
  )
  writeLines(qc_lines, cleaned_counts_qc_file)

  # Preserve the existing output shape: environment columns, separator column,
  # then the filtered community matrix.
  sep_df <- clean_counts.separator_column(nrow(neg_filter$env_df), sep_col_name)

  cbind(neg_filter$env_df, sep_df, community_df)
}

clean_counts.load_aligned_data <- function(scata_counts_file, env_file, dataset_name) {
  # Restrict the counts table to biologically valid tag pairs before comparing
  # it with the environment metadata.
  counts <- clean_counts.valid_tags(scata_counts_file, dataset_name)
  env_df <- read.csv(env_file)

  env.tags <- env_df$Tag
  counts.tags <- counts$Tag
  shared_tags <- intersect(env.tags, counts.tags)

  env_df <- clean_counts.align_rows_by_tag(env_df, shared_tags)
  counts <- clean_counts.align_rows_by_tag(counts, shared_tags)
  counts$Sample.Number <- env_df$Sample.Number

  list(
    counts = counts,
    env_df = env_df,
    qc_stats = list(
      env.tags = env.tags,
      counts.tags = counts.tags,
      env.tags_not_in_counts = setdiff(env.tags, counts.tags),
      counts.tags_not_in_env = setdiff(counts.tags, env.tags)
    )
  )
}

clean_counts.align_rows_by_tag <- function(df, tags) {
  if (length(tags) == 0) {
    return(df[0, , drop = FALSE])
  }

  # Reorder rows to a shared tag vector so related env/count records stay in sync.
  df[match(tags, df$Tag), , drop = FALSE]
}

clean_counts.mark_zero_count_tags <- function(counts) {
  community_df <- clean_counts.community_matrix(counts)
  row_sums <- rowSums(community_df)

  list(
    data = counts,
    tags_with_zero_counts = counts[row_sums == 0, "Tag"]
  )
}

clean_counts.cluster_column_count <- function(counts) {
  ncol(clean_counts.community_matrix(counts))
}

clean_counts.community_matrix <- function(counts) {
  counts[, !(names(counts) %in% c("Tag", "Sample.Number")), drop = FALSE]
}

clean_counts.drop_columns <- function(df, columns) {
  df[, !(names(df) %in% columns), drop = FALSE]
}

clean_counts.remove_control_clusters <- function(counts, env_df, control, minimum_count = 3) {
  if (!any(counts$Sample.Number == control)) {
    return(list(counts = counts, env_df = env_df, removed_clusters = character()))
  }

  # Remove any cluster that crosses the threshold in the control sample, then
  # remove the control row itself from both aligned tables.
  removed_clusters <- clean_counts.cols_with_control(counts, control, minimum_count)
  keep_rows <- counts$Sample.Number != control

  list(
    counts = clean_counts.drop_columns(counts, removed_clusters)[keep_rows, , drop = FALSE],
    env_df = env_df[keep_rows, , drop = FALSE],
    removed_clusters = removed_clusters
  )
}

clean_counts.build_qc_lines <- function(qc_stats,
                                        final_env_df,
                                        community_df,
                                        minimum_count,
                                        counts.cols_with_pos,
                                        counts.cols_with_neg,
                                        small_clusters) {
  # Keep QC rendering separate from filtering so the report logic is easy to
  # inspect or extend without touching the cleaning steps.
  divider <- paste(rep("=", 80), collapse = "")

  c(
    paste0("Final number of env tags (A - C - {POS, NEG}) = ", nrow(final_env_df)),
    paste0("Final number of clusters (E - F - G - H) = ", ncol(community_df)),
    divider,
    paste0("[A] Number of env tags: ", length(qc_stats$env.tags)),
    paste0("[B] Number of counts tags: ", length(qc_stats$counts.tags)),
    paste0("[C] Number of env tags not in counts: ", length(qc_stats$env.tags_not_in_counts)),
    paste0("[D] Number of counts tags not in env: ", length(qc_stats$counts.tags_not_in_env)),
    paste0("[E] Number of tags with zero cluster counts: ", length(qc_stats$counts.tags_with_zero_counts)),
    paste0("[F] Number of clusters: ", qc_stats$cluster_counts),
    paste0("[G] Number of clusters with pos control: ", length(counts.cols_with_pos)),
    paste0("[H] Number of clusters with neg control: ", length(counts.cols_with_neg)),
    paste0(
      "[I] Number of clusters with total counts less than ",
      minimum_count, ": ", length(small_clusters)
    ),
    divider,
    "Tags in env not in counts.",
    clean_counts.format_qc_message(
      qc_stats$env.tags_not_in_counts,
      prefix = "[ACTION REQUIRED] Please remove the following tags from env:"
    ),
    divider,
    "Tags in counts not in env. Excluded in final env tags.",
    clean_counts.format_qc_message(qc_stats$counts.tags_not_in_env),
    divider,
    "Tags with zero counts. Please remove from final env tags.",
    clean_counts.format_qc_message(
      qc_stats$counts.tags_with_zero_counts,
      prefix = "[ACTION REQUIRED] Please remove the following tags from env:"
    ),
    divider,
    "Clusters with POS control",
    clean_counts.format_qc_message(counts.cols_with_pos),
    divider,
    "Clusters with NEG control",
    clean_counts.format_qc_message(counts.cols_with_neg),
    divider,
    paste("Clusters with total counts less than", minimum_count),
    clean_counts.format_qc_message(small_clusters)
  )
}

clean_counts.format_qc_message <- function(values, prefix = NULL) {
  if (length(values) == 0) {
    return("None")
  }

  body <- paste(values, collapse = ", ")
  if (is.null(prefix)) {
    return(body)
  }

  paste0(prefix, body)
}

clean_counts.separator_column <- function(n_rows, sep_col_name) {
  sep_df <- data.frame(rep("X", n_rows), stringsAsFactors = FALSE)
  names(sep_df) <- sep_col_name
  sep_df
}


clean_counts.valid_tags <- function(in_counts_file, dataset_name) {
  # Load the counts file
  df <- read.csv(in_counts_file, sep = ";")

  # Filter the dataset based on the pattern
  pattern <- paste(dataset_name, "tag([^\\s]+)([FR])_tag([^\\s]+)([FR])")
  df_tags <- df[grepl(pattern, df$Tag), ]

  # Extract group 2 and group 3 from the matched rows
  # ([^\\s]+)_([^\\s]+) groups 2 and 3
  df_tags$TagNum1 <- as.numeric(sub(pattern, "\\1", df_tags$Tag))
  df_tags$TagNum1FR <- sub(pattern, "\\2", df_tags$Tag)
  df_tags$TagNum2 <- as.numeric(sub(pattern, "\\3", df_tags$Tag))
  df_tags$TagNum2FR <- sub(pattern, "\\4", df_tags$Tag)

  # Sort by tag numbers
  sorted_df_tags <- df_tags[order(
    df_tags$TagNum1,
    df_tags$TagNum1FR,
    df_tags$TagNum2,
    df_tags$TagNum2FR
  ), ]

  # Remove entries where the forward tag num does not match
  # with the reverse tag num.
  df_valid_tags <- sorted_df_tags[
    sorted_df_tags$TagNum1 == sorted_df_tags$TagNum2,
  ]

  # Remove columns we no longer need
  df_valid_tags <- df_valid_tags[, !(names(df_valid_tags) %in%
    c(
      "Tag", "TagNum2",
      "TagNum1FR", "TagNum2FR"
    ))]

  # Move TagNum1 column as the first column.
  df_valid_tags <- df_valid_tags[, c(
    "TagNum1",
    setdiff(names(df_valid_tags), "TagNum1")
  )]

  # Rename TagNum1 as Tag
  names(df_valid_tags)[names(df_valid_tags) == "TagNum1"] <- "Tag"

  return(df_valid_tags)
}

clean_counts.get_small_clusters <- function(community_df, minimum_count = 3) {
  # Calculate the total value of each column
  col_sums <- colSums(community_df)

  # Find the names of columns where the total value is less than the minimum count
  small_clusters <- names(col_sums[col_sums < minimum_count])

  return(small_clusters)
}

clean_counts.cols_with_control <- function(counts, control, minimum_count = 3) {
  control_rows <- counts[
    counts$Sample.Number == control,
    !(colnames(counts) %in% c("Tag", "Sample.Number"))
  ]
  col_names <- colnames(control_rows)
  col_names_with_control <- col_names[apply(
    control_rows, 2,
    function(x) max(x) >= minimum_count
  )]

  return(col_names_with_control)
}

# -------------------------------
# Process command-line arguments
# -------------------------------
usage <- "Usage: Rscript clean_scata_counts.R <batch> <config file> <output_file>"

# ------------------
# The main function
# ------------------
main <- function() {
  args <- parse_named_args(
    commandArgs(trailingOnly = TRUE),
    c(
      "batch",
      "config_file",
      "cleaned_counts_file",
      "cleaned_counts_qc_file"
    ),
    usage
  )
  batch_config <- load_config(
    args$config_file,
    "batches",
    args$batch,
    c("dataset_name", "counts_file", "environnment_file")
  )
  names(batch_config)[names(batch_config) == "environnment_file"] <- "environment_file"

  message(" Processing batch: ", args$batch)
  message("Scata counts file: ", batch_config$counts_file)
  message("     Dataset name: ", batch_config$dataset_name)
  message(" Environment file: ", batch_config$environment_file)

  result <- clean_counts(
    scata_counts_file = batch_config$counts_file,
    env_file = batch_config$environment_file,
    dataset_name = batch_config$dataset_name,
    cleaned_counts_qc_file = args$cleaned_counts_qc_file
  )

  write.csv(result, file = args$cleaned_counts_file, row.names = FALSE, fileEncoding = "UTF-8")
  message("Done. Output written to: ", args$out_cleaned_counts_file)
}

main()
