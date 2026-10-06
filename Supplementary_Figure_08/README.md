# Supplementary Figure 8. Expression of selected genes over the time course in rich and minimal medium

**Status:** Reproducible (resubmission draft) – see `Supplementary_Figure_08_genes_of_interest.Rmd`

![Supplementary Figure 8](Supplementary_Figure_08.png)

## Legend

**Supplementary Figure 8. Expression of selected genes over the time course in rich and minimal medium.** DESeq2-normalized counts (+1, log10 scale) of genes involved in morphogenesis (A) and in carbon metabolism (B) in wild-type SC5314 grown in rich (YPD) or carbon-limited minimal medium. Points are biological replicates; lines join the mean of the log-scaled values at each time point. Time is on a log2 scale. The shaded area marks the quiescent phase (24–72 h). Triangles are the additional rich 72 h libraries from a second sequencing run (HJT3JDRX7), which have low mRNA depth. The temporal cluster of each gene (Supplementary Figure 9, Figure 4B) is given under its name.

## Panels

| Panel | Content | Code | Input data | Status |
|---|---|---|---|---|
| A | *EFG1*, *NRG1*, *TUP1*, *HWP1*, *ALS3*: normalized counts over time, rich vs minimal | `Supplementary_Figure_08_genes_of_interest.Rmd` | `data/normalized_counts.csv.gz`, `data/timecourse_gene_clusters.csv` | Reproducible |
| B | *ICL1*, *PCK1*, *FBP1*, *HGT1*, *TDH3*: same | same | same | Reproducible |

## How to run

From this folder: `Rscript -e 'rmarkdown::render("Supplementary_Figure_08_genes_of_interest.Rmd")'`. Outputs go to `output/`: the figure (`Supplementary_Figure_08.{pdf,png}`) and the plotted values (`Supplementary_Figure_08_counts.csv`).
Required packages: rmarkdown, data.table, ggplot2, ggtext, patchwork, scales.

## Notes

- The data files are outputs of `CandidaTFKO5_WT_72h/analysis/WT_Rich_vs_Minimal_timecourse_DESeq2_ORA.Rmd` (`new_72h_mode = "add"`, `n_clusters = 8`). The figure is that analysis' "Genes of interest" plot, restyled; the analysis itself was not changed. The ten genes are its `genes_of_interest` parameter, here arranged in two rows by function (Rmd parameter `gene_rows`).
- What changed from the analysis plot: genes are grouped by function, the strips give each gene's cluster, and replicates are dodged by medium rather than randomly jittered. The y values, the mean line (mean of log10(count + 1), as `stat_summary` on a log10 axis) and the quiescent shading are unchanged.
- *NRG1* and *EFG1* are time-responsive only in minimal medium (LRT padj < 0.05); the other eight in both media. *HWP1*, *ALS3*, *ICL1*, *HGT1* and *TDH3* have a significant medium × time interaction.
- The rich 72 h means include the three HJT3JDRX7 libraries, as in the analysis. These libraries are ~99% rRNA (roughly 50–80 thousand mRNA counts each), so their normalized counts are noisy.
- Medium colours use the Figure 4 hues, with minimal darkened from the Figure 4 annotation colour so the lines are legible.
- This replaces the original-submission Supplementary Figure 8 (GO over-representation dotplots of the eight expression clusters). The cluster ORA is now Supplementary Figure 9, and the original code (`geneset_analysis_figure2.Rmd`) moved there for reference.
