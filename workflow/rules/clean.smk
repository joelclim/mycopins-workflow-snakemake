rule clean_scata_counts:
    input:
        "config/config.yaml"
    output:
        cleaned_counts_file = "results/tables/{batch}_cleaned_counts.csv",
        cleaned_counts_qc_file = "results/report/{batch}_cleaned_counts_qc.txt"
    params:
        batch = "{batch}"
    shell:
        (
            "Rscript workflow/scripts/clean_scata_counts.R "
            "{params.batch} "
            "{input} "
            "{output.cleaned_counts_file} "
            "{output.cleaned_counts_qc_file}"
        )

rule clean_scata_clusters:
    input:
        "config/config.yaml"
    output:
        cleaned_clusters_file = "results/tables/{batch}_cleaned_clusters.csv"
    params:
        batch = "{batch}"
    shell:
        (
            "Rscript workflow/scripts/clean_scata_clusters.R "
            "{params.batch} "
            "{input} "
            "{output.cleaned_clusters_file}"
        )