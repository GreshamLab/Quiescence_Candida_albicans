# Supplementary Figure 22. PI/SYTO9 gating of the exponential and quiescent samples in Figure 6A

**Status:** Reproducible from raw FCS (FCS not distributed). The gating reproduces the saved Live/Dead counts behind Figure 6A exactly.

![Supplementary Figure 22](output/Supplementary_Figure_22.png)

## Legend
Supplementary Figure 22. Cell viability quantification of the transcription factor deletion mutants in Figure 6A by
PI/SYTO9 staining. A–D) PI and SYTO9 distribution functions and the gated PI/SYTO9 2D quantification of each biological
replicate of untreated exponential cells of WT (SC5314) (A), *nrg1*Δ (B), *ndt80*Δ (C) and *stp4*Δ (D) grown in rich media.
E–H) PI and SYTO9 distribution functions and the gated PI/SYTO9 2D quantification of each biological replicate of
quiescent cells (Day 3) of WT (SC5314) (E), *nrg1*Δ (F), *ndt80*Δ (G) and *stp4*Δ (H) grown in rich media. Distribution
functions show single cells, one line per biological replicate (n = 3). The three 2D plots of each row show the single
cells of Replicate 1, 2 and 3 separately; each plot is framed in the colour of that replicate in the distribution
functions. Gate labels give the percentage of that replicate's single cells in the Live_cells and Dead_cells gates, and
the viability of that replicate (Live / (Live + Dead), as used in Figure 6A, where the three replicates are averaged) is
given in the top-left corner of each 2D plot. The per-replicate 2D plots show the variation between biological replicates
and support the selection of the samples used for quantification in Figure 6A.

## Panels

| Panel | Content | Code | Input data | Status |
|---|---|---|---|---|
| A–D | Exponential (untreated, rich media): WT (SC5314), *nrg1*Δ, *ndt80*Δ, *stp4*Δ; PI and SYTO9 histograms + one 2D plot per replicate | `Supplementary_Figure_22_Figure6A_PI_SYTO9_gating.Rmd` | `data/Figure_6A_samples.csv`, `data/cytek_gating_OzanImir_20260809_v1.csv`, FCS | Reproducible (FCS required) |
| E–H | Quiescent (Day 3, rich media): WT (SC5314), *nrg1*Δ, *ndt80*Δ, *stp4*Δ; PI and SYTO9 histograms + one 2D plot per replicate | same | `data/Figure_6A_samples.csv`, `data/cytek_gating_OzanImir_20260401_v1.csv`, FCS | Reproducible (FCS required) |

## How to run
From this folder: `Rscript -e 'rmarkdown::render("Supplementary_Figure_22_Figure6A_PI_SYTO9_gating.Rmd", output_dir = "output")'`.
Set `params$fcs_root` to the `Cytek Flow Cytometry` data folder. The default is `/scratch/obi203/data/Cytek Flow Cytometry`.
Packages: tidyverse, cowplot, sp. flowCore, flowWorkspace and CytoExploreR are **not** needed. Rendered with R 4.6.1.
Outputs: `output/Supplementary_Figure_22.png` (18 × 30 in, 300 dpi), `output/Supplementary_Figure_22_gate_counts.csv`,
`output/Supplementary_Figure_22_replicate_gate_percentages.csv` (per-replicate Live_cells/Dead_cells/ungated % of single
cells and viability) and the rendered HTML.

## Notes
- **Samples.** These are the same 24 samples as Figure 6A (`Figure_6/Figure_6_v6_assemble.R`):
  - *Exponential:* untreated rich-media samples of `Knockout_Quiescence_Viability_4_ValidationExtended/Proliferative`
    (`OzanImir_20260809_v1`). The 6HC group is used, except for *nrg1*Δ, which uses the DR-group untreated samples.
  - *Quiescent:* Day 3 samples of `Knockout_Quiescence_Viability_3_Validation` (`OzanImir_20260401_v1`).
- **Gating without CytoExploreR.**
  - The FCS files are read with a small built-in reader, and the polygon gates are parsed from the saved gatingTemplates.
  - `cyto_transformer_arcsinh(..., cofactor = 150/500)` in the source notebooks actually applied the flowJo arcsinh
    with default parameters (T = 262144, M = 4.5, A = 0) to every channel. The `cofactor` argument had no effect.
  - With that transform, all 24 recomputed Live_cells and Dead_cells counts equal the saved counts. The Rmd checks this
    with `stopifnot`.
- **Different SYTO9 detectors.** SYTO9 is read on B7-A for the exponential samples and on B3-A for the quiescent samples.
  The two experiments also have their own gates. SYTO9 intensities should therefore not be compared between A–D and E–H.
- **Ungated SYTO9-low events in exponential *ndt80*Δ and *stp4*Δ (C, D).**
  - Many single cells fall below the Live_cells gate, with SYTO9 ≤ ~0 and PI ~10²–10³.
  - The effect varies by replicate. Live_cells is 96% of single cells for *ndt80*Δ rep 1, but 63% for rep 2 and 75% for rep 3.
    For *stp4*Δ it is 44% for rep 1, 62% for rep 2 and 96% for rep 3.
  - Viability = Live / (Live + Dead) leaves these events out, so the exponential denominators in Figure 6A are unaffected.
    They look like incompletely stained cells. The per-replicate 2D plots now show this replicate dependence directly.
- **Per-replicate 2D plots (revision).** In response to the reviewer request for 2D PI/SYTO9 plots of the knockout
  strains showing variation and justifying sample selection, the single pooled 2D plot per row was replaced by three
  plots, one per biological replicate (WT included as the reference). Density colouring is computed within each replicate.
  Gate percentages and viability in each plot are those of that replicate (previously the mean of three replicates).
  Per-replicate viabilities (%), Rep 1/2/3:
  - *Exponential:* WT 99.8/99.8/99.8; *nrg1*Δ 98.2/98.2/98.0; *ndt80*Δ 99.6/99.5/99.5; *stp4*Δ 99.6/99.5/99.8.
  - *Quiescent:* WT 96.6/96.8/95.6; *nrg1*Δ 70.5/66.6/66.2; *ndt80*Δ 91.0/83.8/88.1; *stp4*Δ 92.4/91.0/91.3.
  - Viability is consistent between replicates even where the ungated SYTO9-low fraction is not (exponential *ndt80*Δ,
    *stp4*Δ), so all three replicates are kept for Figure 6A.
- Strain names use delta notation (*nrg1*Δ, *ndt80*Δ, *stp4*Δ). The sample table and code keep the internal
  identifiers NRG1/NDT80/STP4.
- The TF screen and the validation of selected KOs (Figure 6 draft panels A and B) follow as Supplementary Figures 23 and 24.
