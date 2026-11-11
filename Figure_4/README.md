# Figure 4. Gene expression profiling in proliferative and quiescent cells (RNA-seq time course)

**Status:** Replotted (resubmission draft) – see `Figure_4_RNAseq_timecourse.Rmd`

![Figure 4](Figure_4.png)

## Legend

The resubmission legend for this figure is not final. In the original submission this was Figure 2: *Gene expression profiling in proliferative and quiescent Candida albicans cells. A) Experimental design, sequencing pipeline, and computational strategy employed to quantify transcript level changes across time. B) Hierarchical clustering defined 8 clusters that are annotated using the most significant over-represented GO terms (p < 0.05).*

## Panels

All panels are produced by one R Markdown file, `Figure_4_RNAseq_timecourse.Rmd`, which writes the
assembled figure to `output/Figure_4.{pdf,png}`.

| Panel | Content | Input data | Status |
|---|---|---|---|
| A | Experimental design and pipeline schematic | `data/Figure_4A_schematic.png` (cropped from the original-submission `Figure_4.png`) | Schematic |
| B | log₂FC heatmap (each time point vs 2 h, rich and minimal, 2–72 h) of the time-responsive genes, with the dendrogram and the 8 clusters labelled by their top GO BP terms | `data/vst_batch_corrected.csv.gz`, `data/timecourse_gene_clusters.csv`, `data/DESeq2_time_vs_2h.csv.gz`, `data/ORA_GO_timecourse_clusters.csv` | Reproducible |
| C | Top 10 up-regulated genes (Rich 72 h vs 2 h) over time in the three clusters most induced at 72 h, shown in cluster-number order (6, 7, 8) | same as B | Reproducible |
| D | Autophagy: GO BP over-representation of autophagy terms among genes up at each time point vs 2 h (rich and minimal) | `data/ORA_GO_contrasts_time_vs_2h.csv` | Reproducible |
| E | Autophagy: log₂FC trajectories (rich medium only; the medium is named in the y-axis label, "log₂ fold change vs 2 h (Rich)", as in panel C) of core autophagy genes with *AUT7* (Atg8) highlighted | `data/DESeq2_time_vs_2h.csv.gz` | Reproducible |

`dimension_reduction_media-effect.Rmd` is the original-submission code and is kept for reference.

## Notes

- The image shown is a copy of `output/Figure_4.png`. The earlier panel D (GO over-representation of the top three clusters) was removed; the autophagy panel, formerly E, is now D.
- The data files are outputs of `CandidaTFKO5_WT_72h/analysis/WT_Rich_vs_Minimal_timecourse_DESeq2_ORA.Rmd` (`new_72h_mode = "add"`, `n_clusters = 8`, GO BP). `DESeq2_time_vs_2h.csv.gz` is the `time_vs_2h` subset of its `DESeq2_pairwise_contrasts_long.csv`. The Rmd checks that the rebuilt clustering is identical to the saved cluster assignment.
- The panel A schematic is the original-submission artwork with a 72 h point added (the 48 h point was moved to make room). The area under the growth curve and the time-point circles are recoloured to show glucose: a gold-to-pale gradient over 2–11 h (glucose falling) and grey at 24–72 h (glucose depleted). It still reads `lm(Gene ~ Time+Media)`; the current analysis uses a medium × time group model with LRTs.
- Resubmission revisions: the standalone "Rich" title above the autophagy trajectory plot (now panel E) was removed (the Rich/Minimal facet strips of the left dot plot are kept); its y-axis now reads "log₂ fold change vs 2 h (Rich)". All log axis/legend titles are drawn with plotmath subscripts (log₂FC vs 2 h, log₂ fold change, −log₁₀ p_adj with a true minus sign).
- Cluster numbering (resubmission revision): clusters are numbered 1–8 from top to bottom of the panel B heatmap. The saved assignment (`data/timecourse_gene_clusters.csv`) and the ORA file keep the original numbering (by time of peak in rich medium); the Rmd checks the rebuilt clustering against it and then renumbers (saved → figure: 3→1, 2→2, 1→3, 4→4, 7→5, 6→6, 5→7, 8→8). Colours and GO labels follow each cluster. `output/Figure_4C_top_genes.csv` uses the figure numbers.
- Cluster 5 label (resubmission revision): formerly "Translational elongation & pheromone response", now "Pheromone response & meiosis". Its top GO terms, (cytoplasmic) translational elongation, are driven only by tRNA genes (24 of 24 and 24 of 26 genes; GO annotates tRNAs to these terms), so they do not indicate induction of translation. The remaining terms (pheromone response, meiosis, sexual reproduction) are modest (padj 0.002–0.03). Cluster 8 also contains tRNA genes (32) and shows the same elongation terms in Supplementary Figure 9B.
- Panels C–E (resubmission revision): the autophagy trajectory plot, formerly the right half of panel D, is its own panel E. Each panel C plot shows its own time-axis labels, and the grey quiescent shading starts just before the 24 h point (Rmd parameter `late_shade_offset = 0.2` time-point steps; previously midway between 11 h and 24 h), since glucose is depleted from 24 h on.
- Panel D terms (resubmission revision): panel D reports the three directly autophagy-related terms, autophagy (GO:0006914), macroautophagy (GO:0016236) and autophagosome assembly (GO:0000045). Mitophagy (GO:0000423) and autophagy of mitochondrion (GO:0000422) were removed at the author's request. In the ORA data mitophagy is significant among up-regulated genes at 24, 48 and 72 h in both media (padj 0.002–0.04), and its genes are a subset of those of autophagy of mitochondrion (e.g. 11 of 20 at rich 24 h).
- Raw reads: SRA PRJNA1271226.
