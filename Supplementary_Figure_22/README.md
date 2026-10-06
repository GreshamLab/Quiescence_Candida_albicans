# Supplementary Figure 22. PI/SYTO9 gating of the exponential and quiescent samples in Figure 6A

**Status:** Reproducible from raw FCS (FCS not distributed). The gating reproduces the saved Live/Dead counts behind Figure 6A exactly.

![Supplementary Figure 22](output/Supplementary_Figure_22.png)

## Legend
Supplementary Figure 22. Cell viability quantification of the transcription factor deletion mutants in Figure 6A by
PI/SYTO9 staining. A–D) PI and SYTO9 distribution functions as well as the gated PI/SYTO9 2D quantification of untreated
exponential cells of WT (SC5314) (A), *nrg1*Δ (B), *ndt80*Δ (C) and *stp4*Δ (D) grown in rich media. E–H) PI and SYTO9
distribution functions as well as the gated PI/SYTO9 2D quantification of quiescent cells (Day 3) of WT (SC5314) (E),
*nrg1*Δ (F), *ndt80*Δ (G) and *stp4*Δ (H) grown in rich media. Distribution functions show single cells, one line per
biological replicate (n = 3). 2D plots show the single cells of the three replicates pooled. Gate labels give the mean
percentage of single cells in the Live_cells and Dead_cells gates. Viability (Live / (Live + Dead), mean of three
replicates, as used in Figure 6A) is given in the top-left corner of each 2D plot.

## Panels

| Panel | Content | Code | Input data | Status |
|---|---|---|---|---|
| A–D | Exponential (untreated, rich media): WT, NRG1, NDT80, STP4 | `Supplementary_Figure_22_Figure6A_PI_SYTO9_gating.Rmd` | `data/Figure_6A_samples.csv`, `data/cytek_gating_OzanImir_20260809_v1.csv`, FCS | Reproducible (FCS required) |
| E–H | Quiescent (Day 3, rich media): WT, NRG1, NDT80, STP4 | same | `data/Figure_6A_samples.csv`, `data/cytek_gating_OzanImir_20260401_v1.csv`, FCS | Reproducible (FCS required) |

## How to run
From this folder: `Rscript -e 'rmarkdown::render("Supplementary_Figure_22_Figure6A_PI_SYTO9_gating.Rmd", output_dir = "output")'`.
Set `params$fcs_root` to the `Cytek Flow Cytometry` data folder. The default is `/scratch/obi203/data/Cytek Flow Cytometry`.
Packages: tidyverse, cowplot, sp. flowCore, flowWorkspace and CytoExploreR are **not** needed. Rendered with R 4.6.1.
Outputs: `output/Supplementary_Figure_22.png` (10.5 × 21 in, 300 dpi), `output/Supplementary_Figure_22_gate_counts.csv`
and the rendered HTML.

## Notes
- **Samples.** These are the same 24 samples as Figure 6A (`Figure_6/Figure_6_v6_assemble.R`):
  - *Exponential:* untreated rich-media samples of `Knockout_Quiescence_Viability_4_ValidationExtended/Proliferative`
    (`OzanImir_20260809_v1`). The 6HC group is used, except for NRG1, which uses the DR-group untreated samples.
  - *Quiescent:* Day 3 samples of `Knockout_Quiescence_Viability_3_Validation` (`OzanImir_20260401_v1`).
- **Gating without CytoExploreR.**
  - The FCS files are read with a small built-in reader, and the polygon gates are parsed from the saved gatingTemplates.
  - `cyto_transformer_arcsinh(..., cofactor = 150/500)` in the source notebooks actually applied the flowJo arcsinh
    with default parameters (T = 262144, M = 4.5, A = 0) to every channel. The `cofactor` argument had no effect.
  - With that transform, all 24 recomputed Live_cells and Dead_cells counts equal the saved counts. The Rmd checks this
    with `stopifnot`.
- **Different SYTO9 detectors.** SYTO9 is read on B7-A for the exponential samples and on B3-A for the quiescent samples.
  The two experiments also have their own gates. SYTO9 intensities should therefore not be compared between A–D and E–H.
- **Ungated SYTO9-low events in exponential NDT80 and STP4 (C, D).**
  - Many single cells fall below the Live_cells gate, with SYTO9 ≤ ~0 and PI ~10²–10³.
  - The effect varies by replicate. Live_cells is 96% of single cells for NDT80 rep 1, but 63% for rep 2 and 75% for rep 3.
    For STP4 it is 44% for rep 1, 62% for rep 2 and 96% for rep 3.
  - Viability = Live / (Live + Dead) leaves these events out, so the exponential denominators in Figure 6A are unaffected.
    A reviewer looking at this figure may still ask about them; they look like incompletely stained cells.
- The TF screen and the validation of selected KOs (Figure 6 draft panels A and B) follow as Supplementary Figures 23 and 24.
