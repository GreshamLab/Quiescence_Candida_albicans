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
| [Figure 4](Figure_4/) | RNA-seq time course | Being replotted |
| [Figure 5](Figure_5/) | Antifungal survival of proliferative and quiescent cells | Partially reproducible |
| [Figure 6](Figure_6/) | Transcriptional regulation of quiescence (TF knockouts) | Partially reproducible |

## Supplementary figures

| Figure | Content | Status |
|---|---|---|
| [S1](Supplementary_Figure_01/) | Phase contrast images and cell cluster composition | Reproducible (panel B) |
| [S2](Supplementary_Figure_02/) | DNA content histograms | Image only |
| [S3](Supplementary_Figure_03/) | Percoll density fractionation | Reproducible (panel B) |
| [S4](Supplementary_Figure_04/)–[S7](Supplementary_Figure_07/) | Mitochondrial staining and imaging | Image only (microscopy) |
| [S8](Supplementary_Figure_08/) | GO over-representation of expression clusters | Being replotted |
| [S9](Supplementary_Figure_09/) | Rich vs minimal media expression and GSEA | Being overhauled |
| [S10](Supplementary_Figure_10/)–[S11](Supplementary_Figure_11/) | 40nm-GEMs crowding profiles and cell volume | Placeholder |
| [S12](Supplementary_Figure_12/) | Culture media pH | Placeholder |
| [S13](Supplementary_Figure_13/) | Time to bud emergence | Placeholder |
| [S14](Supplementary_Figure_14/) | PI/SYTO9 viability validation | Image only; gating documented |
| [S15–S20](Supplementary_Figures_15-20/) | PI/SYTO9 gating of antifungal-treated cells | Image only; gating documented |

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
