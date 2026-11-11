# Figure TFBS (draft v1). Candidate regulators of the quiescence transcriptional program

**Status:** Draft, new analysis (2026-10-16). Not yet placed in the paper. Figure number to be decided.

![Figure TFBS draft](output/Figure_TFBS_draft_v1.png)

## Question
Which TF binding motifs are over-represented in the promoters of genes whose transcripts rise as cells
enter quiescence? These TFs are candidates for driving the induction, either by binding (activators)
or by releasing repression (repressors).

## Draft legend
> **Figure X. TF binding motifs over-represented in promoters of quiescence-induced genes.**
>
> **A)** Motif families most enriched in the promoters of genes induced at 72 h vs 2 h in rich medium
> (padj < 0.05, log₂FC ≥ 1; n = 1,471). These are compared with genes that did not change (n = 3,141).
> Points show the percentage of promoters with ≥ 1 site (FIMO p < 10⁻⁴) in induced (red) and unchanged
> (grey) genes. The columns give the number of induced promoters with a site, the ratio of the two
> percentages and the BH-adjusted q of a length-adjusted logistic test. Motifs are grouped into families
> by similarity (Tomtom). Each row shows the family's best motif, and "+n" counts the other significant
> motifs in the family. Labels give the *C. albicans* TF (CGOB ortholog) and, in grey, the
> *S. cerevisiae* TF that the motif was determined for. ᔆᶜ marks *S. cerevisiae* motifs with no 1:1
> *C. albicans* ortholog.
> **B)** Enrichment of the same families (and of the top families for repressed genes) among genes
> induced or repressed at each time point vs 2 h, in rich and minimal medium. Dots mark enrichment at q < 0.05.
> **C)** Motifs of the TFs required for quiescence survival (Figure 6) in the promoters of genes whose
> quiescence response depends on each TF. "Higher" and "lower" refer to the strain × time interaction in
> Figure 6B–D (padj < 0.05, |log₂FC| ≥ 1). Cells are coloured only where the motif is enriched at q < 0.05.

## Main results (numbers from `output/`)
- **Induced genes (Rich, 72 h):** 80 of 186 motifs are enriched, in 41 similarity families. The strongest
  are:
  - the C-rich **Mig1/Mig2/Mig3** family (CCCCRC). 40–48% of induced promoters have a site, against
    22–28% of unchanged promoters (q ≈ 10⁻¹⁵–10⁻¹⁴).
  - several **Zn₂Cys₆ CGG-triplet** families: Cta4 (Sc Oaf1), C3_01210C (Sc Nhp10), Zcf23 (Sc Gsm1),
    Cwt1 (Sc Rds2), Aro80 and Cha4ᔆᶜ.
  - **Msn2/Msn4** STRE (CCCCT), the most widespread: 739/1,471 induced promoters (50%).
  - **Mcm1**.
- These families are enriched from 5 h onward in rich medium and from 8 h in minimal medium (panel B).
  They are depleted from repressed genes, which instead carry poly(dA:dT) (SUM1ᔆᶜ / Sfp1 family),
  Mbp1–Swi6 (MCB, cell cycle) and Tbf1 motifs. This repressed-gene signature is the expected ribosome
  biogenesis / cell-cycle shutdown and serves as an internal positive control.
- **Figure 6 TFs:**
  - The Ndt80 motif is enriched among Rich 72 h induced genes (473/1,471 promoters, q = 0.005).
  - None of the Nrg1, Ndt80 or Stp4 motifs is enriched among the genes whose quiescence response depends on
    that TF. The KO-dependent gene sets may therefore be largely indirect targets, or the
    *S. cerevisiae*-derived motifs may not capture *C. albicans* binding (see Caveats).
- **Agreement with SEA:** 14 of the 15 families in panel A are also significant with MEME-SEA, which uses a different
  scoring method (`work/sea/`).

## Interpretation caveats (to resolve before submission)
1. **Enrichment is not binding.** This is a sequence analysis. No ChIP data were used. Mig1 and Nrg1 are
   repressors, so for them enrichment in induced genes most likely reflects **release of
   repression** after glucose depletion, not new binding. The legend and text should say "candidate
   regulators" or "motifs over-represented", not "bound".
2. **Most motifs come from *S. cerevisiae*** (JASPAR 2022 CORE fungi). They were mapped to *C. albicans*
   through CGOB 1:1 orthologs, and 78 of 186 have no 1:1 ortholog. Some *C. albicans* TFs have rewired
   specificity. Rows such as "CTA4 (Sc OAF1)" therefore name a candidate, not a validated
   regulator. Only 7 motifs were measured for *C. albicans* proteins (CIS-BP).
3. **Nrg1:** the *S. cerevisiae* NRG1 motif may not represent *C. albicans* Nrg1 binding. Consider adding the
   published *C. albicans* NRE before concluding that Nrg1 targets are absent.
4. **Motif redundancy:** members of a family cannot be told apart by sequence. For example, the CCCCRC
   family fits Mig1, Mig2, Mig3, Zms1 and Adr1-like factors equally well.
5. **Promoter definition:** up to 1 kb upstream of the start codon, truncated at the neighbouring
   feature. Only the A haplotype is used. 5,937 promoters are ≥ 100 bp (median 610 bp). About 6% of
   expressed genes have no usable promoter and are excluded.
6. Panels A–B use the Figure 4 time-course DE results. Panel C uses the Figure 6 interaction results.
   Selection markers are excluded from the KO sets.

## Methods (draft)
> **Promoter motif enrichment.** Promoters were defined as up to 1,000 bp upstream of the start codon
> (*C. albicans* SC5314 A22-s07-m01-r228, haplotype A), truncated at the nearest annotated feature.
> Promoters < 100 bp were discarded. Motifs were taken from JASPAR 2022 CORE fungi (non-redundant;
> 179 motifs) and CIS-BP (7 motifs measured for *C. albicans* TFs). *S. cerevisiae* TFs were mapped to
> *C. albicans* orthologs with CGOB (CGD).
>
> Sites were identified with FIMO (MEME Suite 5.5.9; p < 10⁻⁴; zero-order background from the promoter
> set). For each gene set (DESeq2 padj < 0.05 and log₂FC ≥ 1 or ≤ −1), the presence of ≥ 1 site was
> compared between target promoters and promoters of unchanged genes in the same contrast. The test was
> a logistic regression with log promoter length as a covariate, and p-values were BH-adjusted across
> motifs.
>
> Motifs were grouped into families by average-linkage clustering of Tomtom similarities (q < 0.05;
> cut height 0.5). Results were cross-checked with SEA.

## How to run
From this folder:
```bash
Rscript 01_prepare_promoters_and_sets.R   # promoters, gene sets, motif file  (R 4.6.1)
bash    02_run_motif_enrichment.sh        # SEA, Tomtom, FIMO                  (MEME 5.5.9)
Rscript 02b_site_enrichment.R             # length-adjusted site enrichment
Rscript 03_build_figure.R                 # figure + tables in output/
```
`work/` holds intermediates (~96 MB) and can be regenerated.

## Files
| File | Content |
|---|---|
| `data/motifs/` | JASPAR 2022 fungi and CIS-BP *C. albicans* motif files (MEME motif database bundle 12.25) |
| `data/CGOB_C_albicans_S_cerevisiae_orthologs.tsv` | CGD CGOB ortholog table (downloaded 2026-10-16) |
| `output/Figure_TFBS_draft_v1.{png,pdf}` | Figure |
| `output/Figure_TFBS_site_enrichment_all_sets.csv` | Every motif × gene set: counts, %, sites/kb, length-adjusted OR, p, q |
| `output/Figure_TFBS_A_rich72h_induced_families.csv` | Panel A table, with all significant members of each family |
| `output/Figure_TFBS_C_figure6_TF_motifs.csv` | Panel C table |
| `output/Figure_TFBS_motif_annotation_and_families.csv` | Motif → TF, ortholog and family |
