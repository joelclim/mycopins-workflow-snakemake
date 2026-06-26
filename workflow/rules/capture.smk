rule capture_organisms:
    input:
        complete_clusters_file = "results/tables/{batch}_complete_clusters.csv"
    output:
        organisms_file = "results/tables/{batch}_organisms.csv"
    log:
        "results/logs/{batch}_capture_organisms.log"
    params:
        batch = "{batch}"
    shell:
        (
            "Rscript workflow/scripts/capture_organisms.R "
            "{params.batch} "
            "{input.complete_clusters_file} "
            "{output.organisms_file} "
            "2>&1 | tee {log}"
        )

rule capture_sample_clusters:
    input:
        cleaned_counts_file = "results/tables/{batch}_cleaned_counts.csv",
        complete_clusters_file = "results/tables/{batch}_complete_clusters.csv"
    output:
        sample_clusters_file = "results/tables/{batch}_sample_clusters.csv"
    log:
        "results/logs/{batch}_capture_sample_clusters.log"
    params:
        batch = "{batch}"
    shell:
        (
            "Rscript workflow/scripts/capture_sample_clusters.R "
            "{params.batch} "
            "{input.cleaned_counts_file} "
            "{input.complete_clusters_file} "
            "{output.sample_clusters_file} "
            "2>&1 | tee {log}"
        )