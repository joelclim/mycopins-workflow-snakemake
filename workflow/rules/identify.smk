rule identify_clusters:
    input:
        "config/config.yaml",
        "results/tables/{transect}_cleaned_clusters.csv"
    output:
        "results/tables/{transect}_complete_clusters.csv"
    params:
        transect="{transect}"
    shell:
        "Rscript workflow/scripts/identify_clusters.R {params.transect} {input} {output}"