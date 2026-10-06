# Supplementary Figure 9. GO over-representation analysis of the temporal expression clusters

**Status:** Reproducible (resubmission draft) – see `Supplementary_Figure_09_temporal_cluster_ORA.Rmd`

![Supplementary Figure 9](Supplementary_Figure_09.png)

## Legend

**Supplementary Figure 9. GO over-representation analysis of the temporal expression clusters.** Time-responsive genes (likelihood-ratio test padj < 0.05 in rich or minimal medium) were grouped into 8 clusters by hierarchical clustering of their z-scored mean expression in each medium and time point (Figure 4B). A) Expression pattern of each cluster in rich and minimal medium: median z-score (line) and interquartile range (band); n, genes per cluster. Time is on a log2 scale and the shaded area marks the quiescent phase (24–72 h). B) GO biological process terms over-represented in each cluster (hypergeometric test against the expressed, annotated genes; Benjamini–Hochberg adjusted p < 0.05). The 5 most significant terms of each cluster are shown, together with their enrichment in any other cluster. Dot size is the fraction of the cluster's annotated genes in the term (gene ratio) and colour the adjusted p-value (values below 10^-20 are shown at 10^-20). The shaded block in each column marks the terms selected for that cluster.

## Panels

| Panel | Content | Code | Input data | Status |
|---|---|---|---|---|
| A | Median z-score and IQR per cluster, rich vs minimal, 2–72 h | `Supplementary_Figure_09_temporal_cluster_ORA.Rmd` | `data/vst_batch_corrected.csv.gz`, `data/timecourse_gene_clusters.csv` | Reproducible |
| B | GO BP over-representation per cluster, top 5 terms per cluster | same | `data/ORA_GO_timecourse_clusters.csv` | Reproducible |

## How to run

From this folder: `Rscript -e 'rmarkdown::render("Supplementary_Figure_09_temporal_cluster_ORA.Rmd")'`. Outputs go to `output/`: the figure (`Supplementary_Figure_09.{pdf,png}`), the cluster patterns (`Supplementary_Figure_09_cluster_patterns.csv`) and the ORA results shown in panel B (`Supplementary_Figure_09_ORA_terms_shown.csv`).
Required packages: rmarkdown, data.table, ggplot2, ggtext, patchwork, stringr, scales.

## Notes

- The data files are outputs of `CandidaTFKO5_WT_72h/analysis/WT_Rich_vs_Minimal_timecourse_DESeq2_ORA.Rmd` (`new_72h_mode = "add"`, `n_clusters = 8`, GO BP), the same files Figure 4 uses. The figure combines that analysis' "Expression patterns over time" and "ORA of temporal clusters" plots; the analysis itself was not changed.
- The clustering is rebuilt from the VST matrix to draw panel A, and the Rmd checks that it is identical to the saved cluster assignment. Cluster numbers, colours and gene counts match Figure 4B.
- Panel B selects terms as `enrichplot::dotplot(compareCluster result, showCategory = 5)` does in the analysis: all results sorted by p-value, top 5 per cluster, plus every significant result for those terms in other clusters. It is drawn with ggplot from the saved ORA table so that its columns line up with panel A. Each term is listed under the first cluster that selected it, so cluster 8 shows four terms in its own block: its fifth, cytoplasmic translational elongation, is already listed under cluster 7.
- The colour floor (Rmd parameter `p_cap`) keeps the scale usable: clusters 1 and 3 reach padj ≈ 10^-66, which would otherwise wash out every other cluster.
- `geneset_analysis_figure2.Rmd` is the original-submission code for this analysis (formerly Supplementary Figure 8), kept for reference. It builds a custom `org.Calbicans.eg.db` OrgDb with AnnotationForge and is not used by the current figure.
- The original-submission Supplementary Figure 9 (rich vs minimal log2FC heatmap and GSEA) is now Supplementary Figure 10.
