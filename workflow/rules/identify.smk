rule identify_clusters:
    input:
        "config/config.yaml",
        "results/tables/{batch}_cleaned_clusters.csv"
    output:
        complete_clusters_file = "results/tables/{batch}_complete_clusters.csv"
    log:
        "results/logs/{batch}_identify_clusters.log"
    params:
        batch ="{batch}"
    shell:
        (
            "Rscript workflow/scripts/identify_clusters.R "
            "{params.batch} "
            "{input} "
            "{output.complete_clusters_file} "
            "2>&1 | tee {log}"
        )

rule identify_counts:
    input:
        "results/tables/{batch}_cleaned_counts.csv",
        "results/tables/{batch}_complete_clusters.csv"
    output:
        complete_counts_file = "results/tables/{batch}_complete_counts.csv",
        mycopins_environment_file = "results/tables/{batch}_mycopins_environment.csv",
        mycopins_community_file = "results/tables/{batch}_mycopins_community.csv"
    log:
        "results/logs/{batch}_identify_counts.log"
    shell:
        (
            "Rscript workflow/scripts/identify_counts.R "
            "{input} "
            "{output.complete_counts_file} "
            "{output.mycopins_environment_file} "
            "{output.mycopins_community_file} "
            "2>&1 | tee {log}"
        )