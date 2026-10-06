# Supplementary Figure 24. Quiescent viability of 19 selected TF KOs at Day 3 and Day 7

**Status:** Reproducible. The summary, p-values and stars match the saved results of the original analysis to machine precision.

![Supplementary Figure 24](output/Supplementary_Figure_24.png)

## Legend
Supplementary Figure 24. Quiescent viability of 19 selected transcription factor knockouts. Nineteen TF KOs and the
wild-type control (WT, SC5314) were grown to quiescence in rich media in biological triplicate, and viability was
measured by SYTO9/PI flow cytometry at Day 3 and Day 7. Viability = Live / (Live + Dead). Bars show the mean of three
replicates, error bars the SE and points the individual replicates. Each KO was compared with WT on the same day by
Welch's t-test, with Benjamini–Hochberg correction within each day. \* adjusted p < 0.05.

## Panels

| Panel | Content | Code | Input data | Status |
|---|---|---|---|---|
| (single, Day 3 / Day 7 facets) | Viability of 19 KOs + WT; Welch t-test vs WT per day, BH | `Supplementary_Figure_24_TFKO_viability_validation.Rmd` | `data/viability_by_replicate_OzanImir_20260401_v1.csv` | Reproducible |

## How to run
From this folder: `Rscript -e 'rmarkdown::render("Supplementary_Figure_24_TFKO_viability_validation.Rmd", output_dir = "output")'`.
Packages: tidyverse. Rendered with R 4.6.1.
Outputs: `output/Supplementary_Figure_24.{png,pdf}` (11 × 4 in), `output/Supplementary_Figure_24_stats.csv` and the rendered HTML.

## Notes
- **Source.** This was panel B of the Figure 6 draft (`Figure6_Ver1.ai`). The source analysis is
  `Data_Analysis/Cytek Flow Cytometry/Knockout_Quiescence_Viability_3_Validation/KO_Strain_Viability.Rmd`
  (version `OzanImir_20260401_v1`). The gating code (CytoExploreR, needs FCS) is in `Figure_6/Figure_6_TFKO_viability_validation.Rmd`.
- **Significant KOs** (BH-adjusted p < 0.05): STP4 and NRG1 at Day 3; NDT80 and NRG1 at Day 7.
- The KO labelled "unspecified" in the sample sheet is orf19.3253, and it is labelled as such.
- **Shared samples.** The Day 3 WT, NRG1, NDT80 and STP4 samples are the quiescent samples of Figure 6A. Their gating is
  shown in Supplementary Figure 22 (E–H).
- The style matches the supplementary plot written by `Figure_6/Figure_6_v6_assemble.R`
  (`Figure_6/output/Supplementary_TFKO_validation_Day3_Day7.png`). That plot is the same figure, with a title and caption.
- SYTO9 was read on B3-A in this experiment, not B7-A as in the screen (Supplementary Figure 23).
