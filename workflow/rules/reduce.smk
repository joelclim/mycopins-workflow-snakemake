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
        )
    output:
        environment_file = "results/tables/mycopins_{transect}_environment.csv",
        community_file = "results/tables/mycopins_{transect}_community.csv"
    shell:
        (
            "Rscript workflow/scripts/reduce_batches.R "
            "{input.batch_environment_files} "
            "{input.batch_community_files} "
            "{output.environment_file} "
            "{output.community_file}"
        )