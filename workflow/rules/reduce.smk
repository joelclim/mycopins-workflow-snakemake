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
        organisms_file = "results/tables/mycopins_{transect}_organisms.csv",
        sample_clusters_file = "results/tables/mycopins_{transect}_sample_clusters.csv"
    log:
        "results/logs/{transect}_reduce_batches.log"
    conda:
        "../envs/mycopins.yaml"
    shell:
        (
            "Rscript workflow/scripts/reduce_batches.R "
            "{input.batch_environment_files} "
            "{input.batch_community_files} "
            "{input.batch_organisms_files} "
            "{input.batch_sample_clusters_files} "
            "{output.environment_file} "
            "{output.community_file} "
            "{output.organisms_file} "
            "{output.sample_clusters_file} "
            "2>&1 | tee {log}"
        )

rule reduce_transects:
    input:
        transect_environment_files = expand(
            "results/tables/mycopins_{transect}_environment.csv",
            transect=TRANSECTS
        ),
        transect_community_files = expand(
            "results/tables/mycopins_{transect}_community.csv",
            transect=TRANSECTS
        ),
        transect_organisms_files = expand(
            "results/tables/mycopins_{transect}_organisms.csv",
            transect=TRANSECTS
        ),
        transect_sample_clusters_files = expand(
            "results/tables/mycopins_{transect}_sample_clusters.csv",
            transect=TRANSECTS
        )
    output:
        environment_file = "results/tables/oulanka_mycopins_environment.csv",
        community_file = "results/tables/oulanka_mycopins_community.csv",
        organisms_file = "results/tables/oulanka_mycopins_organisms.csv",
        sample_clusters_file = "results/tables/oulanka_mycopins_sample_clusters.csv"
    log:
        "results/logs/oulanka_reduce_transects.log"
    conda:
        "../envs/mycopins.yaml"
    shell:
        (
            "Rscript workflow/scripts/reduce_batches.R "
            "{input.transect_environment_files} "
            "{input.transect_community_files} "
            "{input.transect_organisms_files} "
            "{input.transect_sample_clusters_files} "
            "{output.environment_file} "
            "{output.community_file} "
            "{output.organisms_file} "
            "{output.sample_clusters_file} "
            "2>&1 | tee {log}"
        )