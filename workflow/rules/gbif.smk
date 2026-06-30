rule generate_gbif_event_core:
    input:
        config_file = "config/config.yaml",
        environment_file = "results/tables/oulanka_mycopins_environment.csv",
    output:
        output_file = "results/report/ipt_gbif/event.txt"
    log:
        "results/logs/generate_gbif_event_core.log"
    benchmark:
        "results/benchmarks/generate_gbif_event_core.tsv"
    params:
        location = LOCATION
    conda:
        "../envs/mycopins.yaml"
    resources:
        mem_mb=4000
    script:
        "../scripts/ipt_gbif/generate_gbif_event_core.R"

rule generate_gbif_event_occurrence:
    input:
        config_file = "config/config.yaml",
        environment_file = "results/tables/oulanka_mycopins_environment.csv",
        community_file = "results/tables/oulanka_mycopins_community.csv",
        organisms_file = "results/tables/oulanka_mycopins_organisms.csv",
        sample_cluster_file = "results/tables/oulanka_mycopins_sample_clusters.csv",
    output:
        output_file = "results/report/ipt_gbif/occurrence.txt"
    log:
        "results/logs/generate_gbif_event_occurrence.log"
    benchmark:
        "results/benchmarks/generate_gbif_event_occurrence.tsv"
    params:
        location = LOCATION
    conda:
        "../envs/mycopins.yaml"
    resources:
        mem_mb=8000
    script:
        "../scripts/ipt_gbif/generate_gbif_event_occurrence.R"

rule generate_gbif_dna_derived:
    input:
        config_file = "config/config.yaml",
        community_file = "results/tables/oulanka_mycopins_community.csv",
        sample_cluster_file = "results/tables/oulanka_mycopins_sample_clusters.csv",
    output:
        output_file = "results/report/ipt_gbif/dna-derived.txt"
    log:
        "results/logs/generate_gbif_dna_derived.log"
    benchmark:
        "results/benchmarks/generate_gbif_dna_derived.tsv"
    params:
        location = LOCATION
    conda:
        "../envs/mycopins.yaml"
    resources:
        mem_mb=4000
    script:
        "../scripts/ipt_gbif/generate_gbif_dna_derived.R"

rule generate_gbif_occurrence_core:
    input:
        event_core_file = "results/report/ipt_gbif/event.txt",
        event_occurrence_file = "results/report/ipt_gbif/occurrence.txt",
    output:
        output_file = "results/report/ipt_gbif/occurrence-core.txt"
    log:
        "results/logs/generate_gbif_occurrence_core.log"
    benchmark:
        "results/benchmarks/generate_gbif_occurrence_core.tsv"
    conda:
        "../envs/mycopins.yaml"
    resources:
        mem_mb=4000
    script:
        "../scripts/ipt_gbif/generate_gbif_occurrence_core.R"
