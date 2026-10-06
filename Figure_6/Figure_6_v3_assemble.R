# Figure 6 (v3). Transcriptional regulation of quiescence.
#   A-B) Validation of 19 TF KOs selected from the screen: quiescent viability relative to WT (SC5314)
#        at Day 3 (A) and Day 7 (B). Each replicate's viability is divided by the mean WT viability of
#        the same day (no proliferative measurement exists for these 19 KOs, so WT is the reference).
#        Bars = mean ratio, error bars = SE, points = replicates (n = 3). Stars: Welch t-test of KO vs
#        WT raw viability within each day, BH-adjusted (as in Figure_6_TFKO_viability_validation.Rmd).
#        Both panels share one strain order (ascending Day 3 ratio). KOs profiled by RNA-seq are bold.
#   C-E) Strain x time interaction volcanoes, (KO 72h - KO 6h) - (BG 72h - BG 6h), for NRG, STP, NDT
#        (same contrasts as CandidaTFKO5/analysis/results_quiescence/volcanoes/volcano_*_x_time_vs_BG_.png).
#        DE = padj < 0.05 and |shrunken LFC| >= 1 (DESeq2 + ashr). DE genes annotated in CGD GO (root term
#        + all descendants) are coloured: autophagy-related (GO:0006914 autophagy, GO:0000423 mitophagy,
#        GO:0000045 autophagosome assembly), biofilm formation (GO:0042710), drug resistance (GO:0009410
#        response to xenobiotic stimulus [CGD's former "response to drug"], GO:2001038, GO:0015903,
#        GO:0045117). The top 10 upregulated genes per KO are labelled in bold dark red, ranked by
#        -log10(padj) x log2FC among DE up genes, selection markers excluded (the same ranking as the
#        source volcanoes, which name the top 20).
# Run from this folder: Rscript Figure_6_v3_assemble.R   (R 4.6.1; GO.db, dplyr, ggplot2, ggrepel, patchwork)
suppressPackageStartupMessages({
  library(GO.db); library(AnnotationDbi)
  library(dplyr); library(ggplot2); library(ggrepel); library(patchwork)
})
val_csv <- "data/flow_validation/viability_by_replicate_OzanImir_20260401_v1.csv"
ix_csv <- "data/rnaseq_interaction/Q3_interaction_KO_vs_BG_all_genes.csv"
gaf_file <- "data/cgd_C_albicans_SC5314.gaf.gz"
out_dir <- "output"
dir.create(out_dir, showWarnings = FALSE)

ink <- "#2b2b2a"; ink2 <- "#6b6a65"; top_col <- "#a11d1d"
theme_fig <- theme_classic(base_size = 8) +
  theme(axis.text = element_text(colour = ink2), axis.title = element_text(colour = ink),
        axis.line = element_line(colour = "grey55", linewidth = 0.3),
        axis.ticks = element_line(colour = "grey55", linewidth = 0.3),
        plot.title = element_text(size = 8.5, face = "bold", colour = ink),
        plot.subtitle = element_text(size = 7, colour = ink2),
        plot.tag = element_text(size = 14, face = "bold"))

## ---- A-B: quiescent viability of 19 validated KOs relative to WT ----
val <- read.csv(val_csv) %>%
  mutate(knockout = ifelse(knockout == "unspecified", "orf19.3253", knockout),
         viability = Live_cells / (Live_cells + Dead_cells)) %>%
  group_by(day) %>%
  mutate(ratio = viability / mean(viability[knockout == "WT"])) %>%
  ungroup()
stopifnot(nrow(val) == 120L)

val_stats <- val %>% filter(knockout != "WT") %>%
  group_by(day, knockout) %>%
  summarise(p_value = t.test(viability, val$viability[val$knockout == "WT" & val$day == day[1]])$p.value,
            .groups = "drop") %>%
  group_by(day) %>% mutate(p_adj = p.adjust(p_value, "BH")) %>% ungroup()
val_sum <- val %>% group_by(day, knockout) %>%
  summarise(mean_ratio = mean(ratio), se = sd(ratio) / sqrt(n()), max_pt = max(ratio), .groups = "drop") %>%
  left_join(val_stats, by = c("day", "knockout")) %>%
  mutate(star = case_when(is.na(p_adj) ~ "", p_adj < 0.001 ~ "***", p_adj < 0.01 ~ "**",
                          p_adj < 0.05 ~ "*", TRUE ~ ""))
ko_order <- val_sum %>% filter(day == "Day3") %>% arrange(mean_ratio) %>% pull(knockout)
rnaseq_kos <- c("NRG1", "STP4", "NDT80")
val_ylim <- c(floor(min(val$ratio) * 20) / 20 - 0.05, max(val$ratio) + 0.06)

ratio_panel <- function(dy, title) {
  s <- val_sum %>% filter(day == dy) %>% mutate(knockout = factor(knockout, ko_order),
                                                 grp = ifelse(knockout == "WT", "WT", "KO"))
  r <- val %>% filter(day == dy) %>% mutate(knockout = factor(knockout, ko_order))
  lab_face <- ifelse(ko_order %in% rnaseq_kos, "bold.italic", ifelse(ko_order == "WT", "bold", "italic"))
  ggplot(s, aes(knockout, mean_ratio)) +
    geom_hline(yintercept = 1, linetype = "dashed", linewidth = 0.35, colour = "#c0392b") +
    geom_col(aes(fill = grp), width = 0.72) +
    geom_errorbar(aes(ymin = mean_ratio - se, ymax = mean_ratio + se), width = 0.3,
                  linewidth = 0.3, colour = ink) +
    geom_point(data = r, aes(y = ratio), size = 0.7, colour = ink, alpha = 0.75,
               position = position_jitter(width = 0.12, height = 0, seed = 1)) +
    geom_text(aes(y = pmax(max_pt, mean_ratio + se) + 0.012, label = star), size = 3.2,
              colour = ink, vjust = 0) +
    scale_fill_manual(values = c(KO = "#5b87b8", WT = "#c0392b"), guide = "none") +
    coord_cartesian(ylim = val_ylim) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = NULL, y = "Quiescent viability / WT viability", title = title) +
    theme_fig +
    theme(axis.text.x = element_text(angle = 50, hjust = 1, vjust = 1, colour = ink, face = lab_face))
}
pA <- ratio_panel("Day3", "Day 3 of quiescence: 19 selected TF KOs relative to WT")
pB <- ratio_panel("Day7", "Day 7 of quiescence: 19 selected TF KOs relative to WT")

## ---- gene categories from CGD GO (each root term + all descendants) ----
gaf <- read.delim(gzfile(gaf_file), comment.char = "!", header = FALSE, quote = "")
gaf <- gaf[gaf$V9 == "P" & !grepl("NOT", gaf$V4), ]
gaf$gene_id <- vapply(strsplit(gaf$V11, "\\|"), function(x) {
  y <- x[grepl("^C[1-7R]_\\d{5}[WC]$", x)]; if (length(y)) y[1] else NA_character_ }, "")
off <- as.list(GOBPOFFSPRING)
go_genes <- function(roots) unique(na.omit(gaf$gene_id[gaf$V5 %in% unique(c(roots, unlist(off[roots])))]))
sets <- list(
  Mitophagy = go_genes("GO:0000423"),
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
         mlp = -log10(padj)) %>%
  group_by(contrast) %>%
  mutate(up_score = ifelse(direction == "up" & !selection_marker, mlp * log2FC, NA_real_),
         top_up_rank = ifelse(is.na(up_score), NA_integer_, rank(-up_score, ties.method = "first", na.last = "keep")),
         top10 = !is.na(top_up_rank) & top_up_rank <= 10) %>%
  ungroup()

## ---- C-E: strain x time interaction volcanoes ----
cat_levels <- c("Autophagy-related", "Biofilm formation", "Drug resistance", "Biofilm + drug resistance",
                "Top 10 upregulated")
cat_cols <- setNames(c("#2a78d6", "#eb6834", "#1baf7a", "#eda100", top_col), cat_levels)
cat_shapes <- setNames(c(23, 21, 24, 22, 21), cat_levels)
xlim_all <- max(abs(ix$log2FC)) * 1.05
volcano <- function(ko) {
  d <- ix %>% filter(contrast == paste0(ko, " x time (vs BG)")) %>%
    mutate(bg = ifelse(sig, "DE", "ns"),
           category = ifelse(is.na(category) & top10, "Top 10 upregulated", category),
           category = factor(category, cat_levels))
  hl <- d %>% filter(!is.na(category)) %>% arrange(top10, desc(category))  # top 10 and autophagy on top
  n_up <- sum(d$direction == "up"); n_dn <- sum(d$direction == "down")
  ggplot(d, aes(log2FC, mlp)) +
    geom_point(data = filter(d, bg == "ns"), colour = "grey85", size = 0.5, stroke = 0) +
    geom_point(data = filter(d, bg == "DE", is.na(category)), colour = "grey60", size = 0.6, stroke = 0) +
    geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.25, colour = "grey45") +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.25, colour = "grey45") +
    geom_point(data = hl, aes(fill = category, shape = category), size = 2.4, stroke = 0.35, colour = "white") +
    # top 10 that also carry a category keep their category colour and get a dark-red ring
    geom_point(data = filter(hl, top10, category != cat_levels[5]), shape = 21, size = 3.4, stroke = 0.6,
               colour = top_col, fill = NA) +
    geom_text_repel(data = hl, aes(label = gene, colour = top10, fontface = ifelse(top10, "bold", "plain")),
                    size = 2.0, max.overlaps = Inf,
                    min.segment.length = 0, segment.size = 0.2, segment.colour = "grey55",
                    box.padding = 0.2, point.padding = 0.15, force = 3, max.time = 3, max.iter = 1e5, seed = 1) +
    scale_colour_manual(values = c(`FALSE` = ink, `TRUE` = top_col), guide = "none") +
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
pC <- volcano("NRG")
pD <- volcano("STP") + guides(fill = "none"); pE <- volcano("NDT") + guides(fill = "none")

legend_note <- paste0("Bold dark-red labels: top 10 upregulated genes per KO (DE up, ranked by -log10 padj x log2FC). ",
                      "None of the top 10 falls in a highlighted GO category.")
fig <- (pA | pB) / (pC | pD | pE) +
  plot_layout(heights = c(0.5, 1), guides = "collect") +
  plot_annotation(tag_levels = "A", caption = legend_note,
                  theme = theme(plot.caption = element_text(size = 7.5, colour = ink2, hjust = 0.5))) &
  theme(legend.position = "bottom", legend.title = element_text(size = 7.5, colour = ink))
ggsave(file.path(out_dir, "Figure_6_v3.png"), fig, width = 13, height = 10, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "Figure_6_v3.pdf"), fig, width = 13, height = 10, bg = "white")

write.csv(val_sum %>% select(day, knockout, mean_ratio, se, p_value, p_adj, star),
          file.path(out_dir, "Figure_6_v3_AB_viability_ratio_vs_WT.csv"), row.names = FALSE)
write.csv(ix %>% filter(!is.na(category) | top10) %>% arrange(contrast, top_up_rank) %>%
            select(contrast, gene_id, gene, category, top10, top_up_rank, Mitophagy, `Autophagosome assembly`,
                   Autophagy, `Biofilm formation`, `Drug resistance`, log2FC, padj, direction, note),
          file.path(out_dir, "Figure_6_v3_highlighted_genes.csv"), row.names = FALSE)
