# MycoPins Workflow (Snakemake)

This repository contains a Snakemake workflow for processing fungal DNA metabarcoding outputs from SCATA and BLAST into curated MycoPINS-compatible tables, then aggregating them by transect and location and finally generating GBIF IPT export files.

## Environment Setup
### 1) Install R
TODO

### 2) On Windows
1. Install WSL (Ubuntu) on your Windows PC.
```{code:cmd}
> wsl --install
```
2. Restart your computer when the installation completes. After restarting, a new black terminal window will pop up automatically. Follow the prompt to create a Linux username and password.
3. Switch from CMD shell or Powershell to WSL.
```{code:cmd}
> wsl
$
```
4. Set up Linux Miniconda inside WSL. Download the lightweight Linux installer `miniconda` [here|https://www.anaconda.com/download/success?reg=skipped]: `Miniconda3-latest-Linux-x86_64`
```{code:bash}
$ ./Miniconda3-latest-Linux-x86_64/sh
```

*** Visual Studio Code ***
Open `Command Palette` (Ctrl+Shift+P  / Cmd+Shift+P) >  Select `Preferences: Color Theme`. Select `Solarized Dark`.

Set `WSL (Ubuntu)` as the default terminal window. Open `Command Palette` (Ctrl+Shift+P  / Cmd+Shift+P) > Select `Preferences: Open User Settings (JSON)`. Add the following entry below:

``` {code:json}
    "terminal.integrated.defaultProfile.windows": "Ubuntu (WSL)",
```

### 2) On MacOS
TODO

### 2) On Linux
TODO

### 3) Configure `conda` channels
```{code:bash}
$ conda config --add channels defaults
$ conda config --add channels bioconda
$ conda config --add channels conda-forge
$ conda config --set channel_priority strict
```

### 4) Create and activate an environment
From repository root:

```bash
conda env create -f workflow/envs/mycopins.yaml
conda activate mycopins
```

### 5) Verify toolchain

```bash
snakemake --version
Rscript --version
```

## Workflow Commands
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

```bash
rm -rf results/*
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
```bash
sudo apt install graphiz
```

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

### Generate workflow report

```bash
snakemake --report report.html
```

## Authors

- Joel Lim
