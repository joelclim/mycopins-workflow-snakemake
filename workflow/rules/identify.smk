from pathlib import Path
from snakemake.exceptions import WorkflowError

def require_manual_blast_file(wildcards):
    path = Path(f"data/blast/manual_blast.csv")

    if not path.exists():
        raise WorkflowError(
            f"{str(path)} is missing.\n"
            f"[RUN MANUAL BLAST]\n"
            f"1. Run BLAST on **ALL of the FASTA files under the data/blast folder**.\n"
            f"2. Download the BLAST results in JSON format.\n"
            f"   Example FASTA file: `sequences.fasta`\n"
            f"   Example BLAST results file: `sequences.fasta.json`\n"
            f"3. When finished, run `consolidate_blast_results.R` to create {str(path)}\n:"
            f"   `$ Rscript workflow/scripts/consolidate_blast_results.R config/config.yaml data/blast/manual_blast.csv`\n"
            f"4. Then, re-run the workflow:\n"
            f"   Example: `$ snakemake --cores 1`"
        )

    return str(path)

rule identify_clusters:
    input:
        cleaned_clusters_file = "results/tables/{batch}_cleaned_clusters.csv",
        manual_blast_file = require_manual_blast_file
    output:
        complete_clusters_file = "results/tables/{batch}_complete_clusters.csv"
    log:
        "results/logs/{batch}_identify_clusters.log"
    params:
        batch ="{batch}"
    conda:
        "../envs/mycopins.yaml"
    shell:
        (
            "Rscript workflow/scripts/identify_clusters.R "
            "{params.batch} "
            "{input.cleaned_clusters_file} "
            "{input.manual_blast_file} "
            "{output.complete_clusters_file} "
            "2>&1 | tee {log}"
        )

rule identify_counts:
    input:
        cleaned_counts_file = "results/tables/{batch}_cleaned_counts.csv",
        complete_clusters_file = "results/tables/{batch}_complete_clusters.csv"
    output:
        complete_counts_file = "results/tables/{batch}_complete_counts.csv",
        mycopins_environment_file = "results/tables/{batch}_mycopins_environment.csv",
        mycopins_community_file = "results/tables/{batch}_mycopins_community.csv"
    log:
        "results/logs/{batch}_identify_counts.log"
    conda:
        "../envs/mycopins.yaml"
    shell:
        (
            "Rscript workflow/scripts/identify_counts.R "
            "{input.cleaned_counts_file} "
            "{input.complete_clusters_file} "
            "{output.complete_counts_file} "
            "{output.mycopins_environment_file} "
            "{output.mycopins_community_file} "
            "2>&1 | tee {log}"
        )