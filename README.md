# Mycopins Workflow (Snakemake)

This repository contains a Snakemake workflow for processing fungal DNA metabarcoding outputs from SCATA and BLAST into curated MycoPINS-compatible tables, then aggregating them by transect and location and finally generating GBIF IPT export files.

## Workflow Goals

The workflow is designed to:

1. Clean SCATA count and cluster files for each batch.
2. Join cleaned data with taxonomic identification results.
3. Produce standardized outputs for:
   - environment
   - community
   - organisms
   - sample-cluster relationships
4. Reduce per-batch outputs into transect-level products.
5. Reduce transect-level outputs into location-level (Oulanka) products.
6. Build GBIF IPT-ready text files (event core, occurrence, DNA-derived, occurrence-core mapping).

## Repository Layout

- config/: workflow configuration, including batch/transect mapping and source file paths.
- data/: input data per batch (SCATA exports, BLAST results, environmental metadata).
- resources/: reference databases used by R scripts (for example fungal traits and guild resources).
- workflow/: Snakemake and script logic.
  - workflow/Snakefile: entry point and default targets.
  - workflow/rules/: rule definitions grouped by processing stage.
  - workflow/scripts/: R scripts executed by rules.
  - workflow/envs/mycopins.yaml: conda environment specification.
- results/: generated outputs (tables, logs, reports, and GBIF IPT export files).

## Rule Groups

The workflow includes these rule groups.

### 1) Cleaning (workflow/rules/clean.smk)

- clean_scata_counts
- clean_scata_clusters

Purpose: clean raw SCATA count and cluster inputs for each batch.

### 2) Identification (workflow/rules/identify.smk)

- identify_clusters
- identify_counts

Purpose: enrich cleaned clusters/counts with taxonomic and MycoPINS-specific structure.

### 3) Capture (workflow/rules/capture.smk)

- capture_organisms
- capture_sample_clusters

Purpose: derive organisms and sample-cluster tables from complete/cleaned batch outputs.

### 4) Reduction (workflow/rules/reduce.smk)

- reduce_batches
- reduce_transects

Purpose: aggregate per-batch tables first to transect level, then to location level.

### 5) GBIF IPT Export (workflow/rules/gbif.smk)

- generate_gbif_event_core
- generate_gbif_event_occurrence
- generate_gbif_dna_derived
- generate_gbif_occurrence_core

Purpose: generate GBIF IPT-compatible files in results/report/ipt_gbif/.

## Raw Data Location and Important Components

Raw input data are stored in data/ and organized by batch folder (for example FA23-transectC, SP24-transectA-1, FA24-transectB-1).

Each batch folder typically contains these critical components:

1. SCATA count matrix
   - File used by config as counts_file (for example all_tag_by_cluster_counts.txt).
2. SCATA cluster table
   - File used by config as cluster_file (for example all_clusters_scataXXXX.txt).
3. BLAST consolidated results
   - blast_consolidated.csv
4. Environmental metadata
   - *-env.csv

The workflow resolves these source files from config/config.yaml under:

- batches.<batch>.counts_file
- batches.<batch>.cluster_file
- batches.<batch>.blast_results_file
- batches.<batch>.environnment_file

Important: the key is spelled environnment_file in the current config.

## R Scripts and Runtime Notes

Rules execute R scripts via Rscript from workflow/scripts/ and workflow/scripts/ipt_gbif/. Examples include:

- clean_scata_counts.R
- identify_counts.R
- reduce_batches.R
- ipt_gbif/generate_gbif_event_core.R

Because the workflow depends on R packages, make sure your conda environment includes the required R stack and is active when running Snakemake.

## Cross-Platform Setup (Windows, macOS, Linux)

This workflow is easiest and most reproducible with Miniconda.

### 1) Install Miniconda

- Windows: install Miniconda from the official installer and use Miniconda Prompt (or PowerShell with conda initialized).
- macOS: install Miniconda and initialize your shell.
- Linux: install Miniconda and initialize your shell.

Official docs: https://docs.conda.io/projects/miniconda/

### 2) Create and activate an environment

From repository root:

```bash
conda env create -f workflow/envs/mycopins.yaml
conda activate mycopins
```

### 3) Verify toolchain

```bash
snakemake --version
Rscript --version
```

### 4) Optional: use Snakemake with conda/singularity flags

The Snakefile defines a singularity base image and can be run with --use-singularity when needed.

## How to Execute the Workflow

Run from repository root.

### Dry run

```bash
snakemake -n --cores 1
```

### Full execution

```bash
snakemake --cores 4
```

Adjust --cores to your machine.

### Force rerun a rule

```bash
snakemake --cores 4 -R reduce_transects
```

### Target specific outputs

```bash
snakemake --cores 4 results/tables/oulanka_mycopins_community.csv
```

## How to Debug the Workflow

Useful commands for diagnosing issues:

```bash
snakemake -n -p --reason
snakemake --cores 1 -p --printshellcmds
snakemake --cores 1 --rerun-incomplete
snakemake --cores 1 --keep-going
```

Primary logs are written to results/logs/ by rule.

If an R step fails, run the same Rscript command from the corresponding log to reproduce the error outside Snakemake.

## How to Delete Outputs

Snakemake-managed cleanup:

```bash
snakemake --delete-all-output
```

Delete temporary outputs only:

```bash
snakemake --delete-temp-output
```

Manual cleanup (entire results directory):

- Linux/macOS:

```bash
rm -rf results/*
```

- Windows PowerShell:

```powershell
Remove-Item -Path results\* -Recurse -Force
```

## How to Show Workflow Summary

```bash
snakemake --summary
snakemake --detailed-summary
```

These commands show file status, freshness, and provenance for rule outputs.

## How to Create DAG, Rulegraph, and Filegraph Images

Graph rendering requires Graphviz (dot command).

### Install Graphviz

- Linux: use your distro package manager.
- macOS: brew install graphviz
- Windows: install Graphviz and ensure dot is in PATH.

### Generate graph source and PNG images

```bash
snakemake --dag | dot -Tpng > results/report/dag.png
snakemake --rulegraph | dot -Tpng > results/report/rulegraph.png
snakemake --filegraph | dot -Tpng > results/report/filegraph.png
```

For large workflows, SVG is often easier to inspect:

```bash
snakemake --dag | dot -Tsvg > results/report/dag.svg
```

## Authors

- Joel Lim
