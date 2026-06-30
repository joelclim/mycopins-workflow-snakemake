MycoPins workflow
=================

This workflow turns SCATA-clustered fungal ITS amplicon data from the Oulanka
MycoPins study into analysis-ready community tables and the Darwin Core archives
(Event core, Occurrence, DNA-derived data, Occurrence core) published to GBIF
via the IPT.

Per batch it cleans the SCATA counts and clusters, identifies clusters against
manual BLAST / UNITE matches, and enriches taxa with GBIF backbone taxonomy,
fungal traits, and saproxylic status. Batches are then reduced per transect and
across the whole site before the GBIF/IPT artifacts are generated.

The **Quality control** category lists the per-batch QC summaries to review
before trusting downstream tables; the **GBIF / IPT** category holds the final
publishable archive tables.
