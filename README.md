# Quiescence in *Candida albicans*

Code and processed data for Imir et al. 2026. Each figure has its own folder containing the
current figure image, the legend, and either the R Markdown analysis plus the data it reads, or a
note that the figure is microscopy-only.

Raw RNA-seq reads are at SRA [PRJNA1271226](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1271226).
Raw flow cytometry (FCS) files are not distributed; the flow folders contain the gating templates,
sample sheets and the gated summary tables that the analyses use.

## Figures

| Figure | Content | Status |
|---|---|---|
| [Figure 1](Figure_1/) | Growth, yield vs glucose, cell volume, bud index and DNA content, heat stress, exit from quiescence | Partially reproducible |
| [Figure 2](Figure_2/) | Mitochondrial and vacuole dynamics | Image only (microscopy) |
| [Figure 3](Figure_3/) | Intracellular fluidity (40nm-GEMs) | Image only (data not in repository) |
| [Figure 4](Figure_4/) | RNA-seq time course | Reproducible (panels B–D) |
| [Figure 5](Figure_5/) | Antifungal survival of proliferative and quiescent cells | Partially reproducible |
| [Figure 6](Figure_6/) | Transcriptional regulation of quiescence (TF knockouts) | Partially reproducible |

## Supplementary figures

| Figure | Content | Status |
|---|---|---|
| [S1](Supplementary_Figure_01/) | Phase contrast images and cell cluster composition | Reproducible (panel B) |
| [S2](Supplementary_Figure_02/) | DNA content histograms | Image only |
| [S3](Supplementary_Figure_03/) | Percoll density fractionation | Reproducible (panel B) |
| [S4](Supplementary_Figure_04/)–[S7](Supplementary_Figure_07/) | Mitochondrial staining and imaging | Image only (microscopy) |
| [S8](Supplementary_Figure_08/) | Expression of selected genes, rich vs minimal time course | Reproducible |
| [S9](Supplementary_Figure_09/) | GO over-representation of temporal expression clusters | Reproducible |
| [S10](Supplementary_Figure_10/) | Rich vs minimal media expression and GSEA | Being overhauled |
| [S11](Supplementary_Figure_11/)–[S12](Supplementary_Figure_12/) | 40nm-GEMs crowding profiles and cell volume | Placeholder |
| [S13](Supplementary_Figure_13/) | Culture media pH | Placeholder |
| [S14](Supplementary_Figure_14/) | Time to bud emergence | Placeholder |
| [S15](Supplementary_Figure_15/) | PI/SYTO9 viability validation | Image only; gating documented |
| [S16–S21](Supplementary_Figures_16-21/) | PI/SYTO9 gating of antifungal-treated cells | Image only; gating documented |
| [S22](Supplementary_Figure_22/) | PI/SYTO9 gating of the exponential and quiescent samples in Figure 6A | Reproducible from raw FCS (not distributed) |
| [S23](Supplementary_Figure_23/) | Viability screen of the TF KO collection in quiescence | Reproducible |
| [S24](Supplementary_Figure_24/) | Day 3 / Day 7 quiescent viability of 19 selected TF KOs | Reproducible |

Supplementary figures 9–20 of the original submission are now 10–21: the original Supplementary Figure 8
(cluster GO dotplots) was replaced by the new Supplementary Figures 8 and 9.

## Running the analyses

Each Rmd runs from its own folder and writes its outputs to `output/`:

```r
rmarkdown::render("Figure_1/Figure_1_yield_vs_glucose.Rmd")
```

The analyses were run with R 4.6.1. Main packages: tidyverse, readxl, patchwork, emmeans,
DESeq2, clusterProfiler (≥ 4.20) and data.table. The flow cytometry gating sections need
CytoExploreR and the raw FCS files, and are not evaluated by default.

## License

See [LICENSE](LICENSE).
