rule clean_scata_counts:
    input:
        config_file = "config/config.yaml"
    output:
        cleaned_counts_file = "results/tables/{batch}_cleaned_counts.csv",
        cleaned_counts_qc_file = "results/report/{batch}_cleaned_counts_qc.txt"
    log:
        "results/logs/{batch}_clean_scata_counts.log"
    benchmark:
        "results/benchmarks/{batch}_clean_scata_counts.tsv"
    params:
        batch = "{batch}"
    conda:
        "../envs/mycopins.yaml"
    resources:
        mem_mb=2000
    script:
        "../scripts/clean_scata_counts.R"

rule clean_scata_clusters:
    input:
        config_file = "config/config.yaml"
    output:
        output_file = "results/tables/{batch}_cleaned_clusters.csv"
    log:
        "results/logs/{batch}_clean_scata_clusters.log"
    benchmark:
        "results/benchmarks/{batch}_clean_scata_clusters.tsv"
    params:
        batch = "{batch}",
        blast_fasta_folder = "data/blast/{batch}/"
    conda:
        "../envs/mycopins.yaml"
    resources:
        mem_mb=2000
    script:
        "../scripts/clean_scata_clusters.R"
