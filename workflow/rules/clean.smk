rule clean_scata_counts:
    input:
        "config/config.yaml"
    output:
        cleaned_counts_file = "results/tables/{batch}_cleaned_counts.csv",
        cleaned_counts_qc_file = "results/report/{batch}_cleaned_counts_qc.txt"
    log:
        "results/logs/{batch}_clean_scata_counts.log"
    params:
        batch = "{batch}"
    conda:
        "../envs/mycopins.yaml"
    shell:
        (
            "Rscript workflow/scripts/clean_scata_counts.R "
            "{params.batch} "
            "{input} "
            "{output.cleaned_counts_file} "
            "{output.cleaned_counts_qc_file} "
            "2>&1 | tee {log}"
        )

rule clean_scata_clusters:
    input:
        "config/config.yaml"
    output:
        cleaned_clusters_file = "results/tables/{batch}_cleaned_clusters.csv"
    log:
        "results/logs/{batch}_clean_scata_clusters.log"
    params:
        batch = "{batch}",
        blast_fasta_folder = "data/blast/{batch}/"
    conda:
        "../envs/mycopins.yaml"
    shell:
        (
            "Rscript workflow/scripts/clean_scata_clusters.R "
            "{params.batch} "
            "{params.blast_fasta_folder} "
            "{input} "
            "{output.cleaned_clusters_file} "
            "2>&1 | tee {log}"
        )