rule generate_gbif_event_core:
    input:
        config_file = "config/config.yaml",
        mycopins_environment_file = "results/tables/oulanka_mycopins_environment.csv",
    output:
        gbif_event_file = "results/report/ipt_gbif/event.txt"
    log:
        "results/logs/generate_gbif_event_core.log"
    params:
        location = {LOCATION}
    shell:
        (
            "Rscript workflow/scripts/ipt_gbif/generate_gbif_event_core.R "
            "{params.location} "
            "{input.config_file} "
            "{input.mycopins_environment_file} "
            "{output.gbif_event_file} "
            "2>&1 | tee {log}"
        )

rule generate_gbif_event_occurrence:
    input:
        config_file = "config/config.yaml",
        mycopins_environment_file = "results/tables/oulanka_mycopins_environment.csv",
        mycopins_community_file = "results/tables/oulanka_mycopins_community.csv",
        mycopins_organisms_file = "results/tables/oulanka_mycopins_organisms.csv",
        mycopins_sample_cluster_file = "results/tables/oulanka_mycopins_sample_clusters.csv",
    output:
        gbif_occurrence_file = "results/report/ipt_gbif/occurrence.txt"
    log:
        "results/logs/generate_gbif_event_occurrence.log"
    params:
        location = {LOCATION}
    shell:
        (
            "Rscript workflow/scripts/ipt_gbif/generate_gbif_event_occurrence.R "
            "{params.location} "
            "{input.config_file} "
            "{input.mycopins_environment_file} "
            "{input.mycopins_community_file} "
            "{input.mycopins_organisms_file} "
            "{input.mycopins_sample_cluster_file} "
            "{output.gbif_occurrence_file} "
            "2>&1 | tee {log}"
        )

rule generate_gbif_dna_derived:
    input:
        config_file = "config/config.yaml",
        mycopins_community_file = "results/tables/oulanka_mycopins_community.csv",
        mycopins_sample_cluster_file = "results/tables/oulanka_mycopins_sample_clusters.csv",
    output:
        gbif_occurrence_file = "results/report/ipt_gbif/dna-derived.txt"
    log:
        "results/logs/generate_gbif_dna_derived.log"
    params:
        location = {LOCATION}
    shell:
        (
            "Rscript workflow/scripts/ipt_gbif/generate_gbif_dna_derived.R "
            "{params.location} "
            "{input.config_file} "
            "{input.mycopins_community_file} "
            "{input.mycopins_sample_cluster_file} "
            "{output.gbif_occurrence_file} "
            "2>&1 | tee {log}"
        )

rule generate_gbif_occurrence_core:
    input:
        ipt_gbif_event_core_file = "results/report/ipt_gbif/event.txt",
        ipt_gbif_occurrence_file = "results/report/ipt_gbif/occurrence.txt",
    output:
        gbif_occurrence_core_file = "results/report/ipt_gbif/occurrence-core.txt"
    log:
        "results/logs/generate_gbif_occurrence_core.log"
    shell:
        (
            "Rscript workflow/scripts/ipt_gbif/generate_gbif_occurrence_core.R "
            "{input.ipt_gbif_event_core_file} "
            "{input.ipt_gbif_occurrence_file} "
            "{output.gbif_occurrence_core_file} "
            "2>&1 | tee {log}"
        )