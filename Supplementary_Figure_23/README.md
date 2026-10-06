# Supplementary Figure 23. Viability screen of the TF KO collection in quiescence

**Status:** Reproducible. The per-strain table is regenerated from the raw FCS files (not distributed) and matches the original plot.

![Supplementary Figure 23](output/Supplementary_Figure_23.png)

## Legend
Supplementary Figure 23. Viability screen of the transcription factor knockout collection in quiescence. Each strain of
the TF KO collection (166 KOs) and the wild-type control (WT, SC5314) was grown to quiescence for 3 days in rich media,
stained with SYTO9 and propidium iodide (PI) and measured by flow cytometry (one well per strain).
Viability = Live / (Live + Dead) × 100. Strains are ranked by viability and labelled by plate ID. WT is shown in red, and
the dashed line marks WT viability (98.7%). The shaded region marks the 19 strains with the lowest viability.

## Panels

| Panel | Content | Code | Input data | Status |
|---|---|---|---|---|
| (single) | Ranked Day 3 viability of 166 TF KOs + SC5314 | `Supplementary_Figure_23_TFKO_viability_screen.Rmd` | `data/OzanImir_20260310_v1_viability_results.csv` (gating: `data/cytek_gating_OzanImir_20260310_v1.csv`, `data/sample_sheet_vignette_simple.csv`, FCS) | Reproducible |

## How to run
From this folder: `Rscript -e 'rmarkdown::render("Supplementary_Figure_23_TFKO_viability_screen.Rmd", output_dir = "output")'`.
The plot runs from the saved table in `data/`. If the FCS folder `params$fcs_root` exists (default
`/scratch/obi203/data/Cytek Flow Cytometry`), the gating chunk also re-gates the 167 FCS files and checks the counts
against the saved table. Packages: tidyverse, sp (gating only). Rendered with R 4.6.1.
Outputs: `output/Supplementary_Figure_23.{png,pdf}` (12 × 4.5 in) and the rendered HTML.

## Notes
- **Source.** This was panel A of the Figure 6 draft (`Figure6_Ver1.ai`). The source analysis is
  `Data_Analysis/Cytek Flow Cytometry/Knockout_Quiescence_Viability_2/KO_Strain_Viability.Rmd` (version `OzanImir_20260310_v1`).
- **Recovered per-strain table.** The original per-strain table was not saved. `data/OzanImir_20260310_v1_viability_results.csv`
  was regenerated from the 167 FCS files with the FCS reader and gating code of Supplementary Figure 22. The flowJo arcsinh
  defaults are used because the `cofactor` argument in the source notebook had no effect.
  - It matches the values read from the original plot (`data/OzanImir_20260310_v1_viability_from_plot.csv`) to < 0.01 percentage points.
  - The ranking is identical, and SC5314 = 98.73%, as in the original plot.
- **Strain labels.** Strain001–Strain166 are plate positions. No strain-to-gene plate map is available, so the bars are
  labelled by plate ID. It is therefore not possible to confirm which plate IDs correspond to the 19 KOs validated in
  Supplementary Figure 24.
- **Shading.** The shaded region reproduces the green box in the draft, which covers the 19 lowest-viability strains. That
  the shaded strains are the ones carried into the validation is inferred from the count (19) only. The legend therefore
  describes the region only as the lowest-viability strains.
- **Strain125.** The lowest-ranked strain (66.9%) has only 1,760 single cells, compared with a median of 34,889 across the screen.
- The screen is a single well per strain, so no statistics are given.
