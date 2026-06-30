Quality-control summary for batch ``{{ snakemake.wildcards.batch }}``.

Produced while cleaning the SCATA tag-by-cluster counts: lists tag/count
mismatches between the environment metadata and the counts matrix, tags with
zero counts, clusters removed via positive/negative controls, and clusters
dropped for falling below the minimum count threshold. Review the
``[ACTION REQUIRED]`` lines before trusting the downstream tables.
