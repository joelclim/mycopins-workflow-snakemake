# snakemake -np results/tables/mycopins_transectC_environment.csv results/tables/mycopins_transectC_community.csv
rule merge_batches:
    input:
        config_file = "config/config.yaml",
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
    params:
        transect = "{transect}"
    shell:
        (
            "Rscript workflow/scripts/merge_batches.R "
            "{params.transect} "
            "{input.config_file} "
            "{output.environment_file} "
            "{output.community_file}"
        )