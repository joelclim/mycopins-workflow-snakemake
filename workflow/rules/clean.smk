rule clean_scata_counts:
    input:
        config_file="config/config.yaml"
    output:
        "results/tables/{transect}_cleaned_counts.csv"
    params:
        transect="{transect}"
    shell:
        "Rscript workflow/scripts/clean_scata_counts.R {params.transect} {input.config_file} {output}"

rule clean_scata_clusters:
    input:
        config_file="config/config.yaml"
    output:
        "results/tables/{transect}_cleaned_clusters.csv"
    params:
        transect="{transect}"
    shell:
        "Rscript workflow/scripts/clean_scata_clusters.R {params.transect} {input.config_file} {output}"