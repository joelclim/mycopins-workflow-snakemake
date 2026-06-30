rule capture_organisms:
    input:
        complete_clusters_file = "results/tables/{batch}_complete_clusters.csv"
    output:
        output_file = "results/tables/{batch}_organisms.csv"
    log:
        "results/logs/{batch}_capture_organisms.log"
    benchmark:
        "results/benchmarks/{batch}_capture_organisms.tsv"
    params:
        batch = "{batch}"
    conda:
        "../envs/mycopins.yaml"
    resources:
        mem_mb=2000
    script:
        "../scripts/capture_organisms.R"

rule capture_sample_clusters:
    input:
        cleaned_counts_file = "results/tables/{batch}_cleaned_counts.csv",
        complete_clusters_file = "results/tables/{batch}_complete_clusters.csv"
    output:
        output_file = "results/tables/{batch}_sample_clusters.csv"
    log:
        "results/logs/{batch}_capture_sample_clusters.log"
    benchmark:
        "results/benchmarks/{batch}_capture_sample_clusters.tsv"
    params:
        batch = "{batch}"
    conda:
        "../envs/mycopins.yaml"
    resources:
        mem_mb=2000
    script:
        "../scripts/capture_sample_clusters.R"
