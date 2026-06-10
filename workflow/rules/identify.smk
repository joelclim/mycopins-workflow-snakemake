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

rule identify_counts:
    input:
        "results/tables/{transect}_cleaned_counts.csv",
        "results/tables/{transect}_complete_clusters.csv"
    output:
        complete_counts_file = "results/tables/{transect}_complete_counts.csv",
        mycopins_environment_file = "results/tables/{transect}_mycopins_environment.csv",
        mycopins_community_file = "results/tables/{transect}_mycopins_community.csv"
    params:
        transect="{transect}"
    shell:
        "Rscript workflow/scripts/identify_counts.R {input} {output.complete_counts_file} {output.mycopins_environment_file} {output.mycopins_community_file}"