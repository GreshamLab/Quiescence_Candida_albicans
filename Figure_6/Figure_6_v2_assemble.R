# Figure 6 (v2). Transcriptional regulation of quiescence.
#   A) Screen of TF KOs for decreased survival in quiescence (ranked day-3 viability).
#   B-D) Strain x time interaction volcanoes, (KO 72h - KO 6h) - (BG 72h - BG 6h), for NRG, STP, NDT.
#        DE = padj < 0.05 and |shrunken LFC| >= 1 (results from CandidaTFKO5/analysis, DESeq2 + ashr).
#        DE genes annotated in CGD GO (root term + all descendants) are coloured and labelled:
#        autophagy-related (GO:0006914 autophagy, GO:0000423 mitophagy, GO:0000045 autophagosome
#        assembly), biofilm formation (GO:0042710), drug resistance (GO:0009410 response to xenobiotic
#        stimulus [CGD's former "response to drug"], GO:2001038, GO:0015903, GO:0045117).
# Panel A values were read off the vector plot OzanImir_20260310_v1_viability_plot.pdf (the per-strain
# table was not saved); they match the PDF bar heights to within 0.1 percentage points.
# Run from this folder: Rscript Figure_6_v2_assemble.R   (R 4.6.1; GO.db, dplyr, ggplot2, ggrepel, patchwork)
suppressPackageStartupMessages({
  library(GO.db); library(AnnotationDbi)
  library(dplyr); library(ggplot2); library(ggrepel); library(patchwork)
})
screen_csv <- "data/flow_screen/OzanImir_20260310_v1_viability_from_plot.csv"
ix_csv <- "data/rnaseq_interaction/Q3_interaction_KO_vs_BG_all_genes.csv"
gaf_file <- "data/cgd_C_albicans_SC5314.gaf.gz"
out_dir <- "output"
dir.create(out_dir, showWarnings = FALSE)

ink <- "#2b2b2a"; ink2 <- "#6b6a65"
theme_fig <- theme_classic(base_size = 8) +
  theme(axis.text = element_text(colour = ink2), axis.title = element_text(colour = ink),
        axis.line = element_line(colour = "grey55", linewidth = 0.3),
        axis.ticks = element_line(colour = "grey55", linewidth = 0.3),
        plot.title = element_text(size = 8.5, face = "bold", colour = ink),
        plot.subtitle = element_text(size = 7, colour = ink2),
        plot.tag = element_text(size = 14, face = "bold"))

## ---- A: ranked viability screen ----
scr <- read.csv(screen_csv) %>% arrange(viability_pct) %>%
  mutate(rank = row_number(), wt = strain == "SC5314")
wt_v <- scr$viability_pct[scr$wt]
pA <- ggplot(scr, aes(rank, viability_pct, fill = wt)) +
  geom_col(width = 0.75) +
  geom_hline(yintercept = wt_v, linetype = "dashed", linewidth = 0.35, colour = "#c0392b") +
  annotate("text", x = scr$rank[scr$wt], y = 103, label = sprintf("SC5314 (WT)\n%.1f%%", wt_v),
           size = 2.4, colour = ink, vjust = 0, lineheight = 0.9) +
  scale_fill_manual(values = c(`FALSE` = "#5b87b8", `TRUE` = "#c0392b"), guide = "none") +
  scale_y_continuous(limits = c(0, 115), breaks = seq(0, 100, 20), expand = c(0, 0)) +
  scale_x_continuous(expand = c(0.005, 0.005), breaks = c(1, 50, 100, 150, nrow(scr))) +
  labs(x = sprintf("TF KO strains ranked by viability (n = %d KOs + SC5314)", nrow(scr) - 1),
       y = "Viability (%)", title = "TF KO collection, day 3 of quiescence") +
  theme_fig

## ---- gene categories from CGD GO (each root term + all descendants) ----
gaf <- read.delim(gzfile(gaf_file), comment.char = "!", header = FALSE, quote = "")
gaf <- gaf[gaf$V9 == "P" & !grepl("NOT", gaf$V4), ]
gaf$gene_id <- vapply(strsplit(gaf$V11, "\\|"), function(x) {
  y <- x[grepl("^C[1-7R]_\\d{5}[WC]$", x)]; if (length(y)) y[1] else NA_character_ }, "")
off <- as.list(GOBPOFFSPRING)
go_genes <- function(roots) unique(na.omit(gaf$gene_id[gaf$V5 %in% unique(c(roots, unlist(off[roots])))]))
sets <- list(
  Mitophagy = go_genes("GO:0000423"),                               # mitophagy
  `Autophagosome assembly` = go_genes("GO:0000045"),
  Autophagy = go_genes("GO:0006914"),
  `Biofilm formation` = go_genes("GO:0042710"),
  # CGD maps "(cellular) response to drug" to response to xenobiotic stimulus; mostly mutant phenotypes
  `Drug resistance` = go_genes(c("GO:0009410", "GO:2001038", "GO:0015903", "GO:0045117")))
print(sapply(sets, length))

ix <- read.csv(ix_csv)
for (s in names(sets)) ix[[s]] <- ix$gene_id %in% sets[[s]]
ix <- ix %>% filter(!is.na(padj)) %>%
  mutate(auto = Mitophagy | `Autophagosome assembly` | Autophagy,
         cats = paste0(ifelse(auto, "A", ""), ifelse(`Biofilm formation`, "B", ""), ifelse(`Drug resistance`, "D", "")),
         category = case_when(!sig | cats == "" ~ NA_character_,
                              auto ~ "Autophagy-related",
                              `Biofilm formation` & `Drug resistance` ~ "Biofilm + drug resistance",
                              `Biofilm formation` ~ "Biofilm formation",
                              TRUE ~ "Drug resistance"),
         mlp = -log10(padj))

## ---- B-D: strain x time interaction volcanoes ----
cat_levels <- c("Autophagy-related", "Biofilm formation", "Drug resistance", "Biofilm + drug resistance")
cat_cols <- setNames(c("#2a78d6", "#eb6834", "#1baf7a", "#eda100"), cat_levels)
cat_shapes <- setNames(c(23, 21, 24, 22), cat_levels)
xlim_all <- max(abs(ix$log2FC)) * 1.05
volcano <- function(ko) {
  d <- ix %>% filter(contrast == paste0(ko, " x time (vs BG)")) %>%
    mutate(bg = ifelse(sig, "DE", "ns"), category = factor(category, cat_levels))
  hl <- d %>% filter(!is.na(category)) %>% arrange(desc(category))  # autophagy drawn last (on top)
  n_up <- sum(d$direction == "up"); n_dn <- sum(d$direction == "down")
  ggplot(d, aes(log2FC, mlp)) +
    geom_point(data = filter(d, bg == "ns"), colour = "grey85", size = 0.5, stroke = 0) +
    geom_point(data = filter(d, bg == "DE", is.na(category)), colour = "grey60", size = 0.6, stroke = 0) +
    geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.25, colour = "grey45") +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.25, colour = "grey45") +
    geom_point(data = hl, aes(fill = category, shape = category), size = 2.4, stroke = 0.35, colour = "white") +
    geom_text_repel(data = hl, aes(label = gene), size = 2.0, colour = ink, max.overlaps = Inf,
                    min.segment.length = 0, segment.size = 0.2, segment.colour = "grey55",
                    box.padding = 0.2, point.padding = 0.15, force = 3, max.time = 3, max.iter = 1e5, seed = 1) +
    annotate("text", x = c(-xlim_all, xlim_all), y = Inf, vjust = 1.4, hjust = c(0, 1), size = 2.3,
             colour = ink2, label = c(sprintf("weaker in %s\n(%d genes)", ko, n_dn),
                                      sprintf("stronger in %s\n(%d genes)", ko, n_up)), lineheight = 0.9) +
    scale_fill_manual(values = cat_cols, drop = FALSE, name = "DE genes annotated to:") +
    scale_shape_manual(values = cat_shapes, drop = FALSE, name = "DE genes annotated to:") +
    guides(shape = "none", fill = guide_legend(override.aes = list(shape = unname(cat_shapes), size = 3.2))) +
    scale_x_continuous(limits = c(-xlim_all, xlim_all)) +
    scale_y_continuous(expand = expansion(mult = c(0.02, 0.18))) +
    labs(title = sprintf("%s x time (vs BG)", ko),
         x = "Interaction log2 fold change (shrunken)", y = "-log10 adjusted p") +
    theme_fig + theme(legend.position = "bottom", legend.text = element_text(size = 7.5, colour = ink))
}
pB <- volcano("NRG")  # NRG has hits in all four categories, so its legend is the complete one
pC <- volcano("STP") + guides(fill = "none"); pD <- volcano("NDT") + guides(fill = "none")

fig <- pA / (pB | pC | pD) +
  plot_layout(heights = c(0.42, 1), guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(legend.position = "bottom", legend.title = element_text(size = 7.5, colour = ink))
ggsave(file.path(out_dir, "Figure_6_v2.png"), fig, width = 12, height = 9, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "Figure_6_v2.pdf"), fig, width = 12, height = 9, bg = "white")
write.csv(ix %>% filter(!is.na(category)) %>%
            select(contrast, gene_id, gene, category, Mitophagy, `Autophagosome assembly`, Autophagy,
                   `Biofilm formation`, `Drug resistance`, log2FC, padj, direction, note),
          file.path(out_dir, "Figure_6_v2_highlighted_genes.csv"), row.names = FALSE)
