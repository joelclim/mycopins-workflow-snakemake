# snakemake -np results/tables/mycopins_transectC_environment.csv results/tables/mycopins_transectC_community.csv
rule reduce_batches:
    input:
        batch_environment_files = lambda wildcards: expand(
            "results/tables/{batch}_mycopins_environment.csv",
            batch=TRANSECT_BATCHES(wildcards)
        ),
        batch_community_files = lambda wildcards: expand(
            "results/tables/{batch}_mycopins_community.csv",
            batch=TRANSECT_BATCHES(wildcards)
        ),
        batch_organisms_files = lambda wildcards: expand(
            "results/tables/{batch}_organisms.csv",
            batch=TRANSECT_BATCHES(wildcards)
        ),
        batch_sample_clusters_files = lambda wildcards: expand(
            "results/tables/{batch}_sample_clusters.csv",
            batch=TRANSECT_BATCHES(wildcards)
        )
    output:
        environment_file = "results/tables/mycopins_{transect}_environment.csv",
        community_file = "results/tables/mycopins_{transect}_community.csv",
        organism_file = "results/tables/mycopins_{transect}_organisms.csv",
        sample_clusters_file = "results/tables/mycopins_{transect}_sample_clusters.csv"
    log:
        "results/logs/{transect}_reduce_batches.log"
    conda:
        "../envs/mycopins.yaml"
    script:
        "../scripts/reduce_batches.R"

rule reduce_transects:
    input:
        batch_environment_files = expand(
            "results/tables/mycopins_{transect}_environment.csv",
            transect=TRANSECTS
        ),
        batch_community_files = expand(
            "results/tables/mycopins_{transect}_community.csv",
            transect=TRANSECTS
        ),
        batch_organisms_files = expand(
            "results/tables/mycopins_{transect}_organisms.csv",
            transect=TRANSECTS
        ),
        batch_sample_clusters_files = expand(
            "results/tables/mycopins_{transect}_sample_clusters.csv",
            transect=TRANSECTS
        )
    output:
        environment_file = "results/tables/oulanka_mycopins_environment.csv",
        community_file = "results/tables/oulanka_mycopins_community.csv",
        organism_file = "results/tables/oulanka_mycopins_organisms.csv",
        sample_clusters_file = "results/tables/oulanka_mycopins_sample_clusters.csv"
    log:
        "results/logs/oulanka_reduce_transects.log"
    conda:
        "../envs/mycopins.yaml"
    script:
        "../scripts/reduce_batches.R"
