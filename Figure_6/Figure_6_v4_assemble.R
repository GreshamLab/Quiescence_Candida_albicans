# Figure 6 (v4). Transcriptional regulation of quiescence.
#   A) Day 3 quiescent / exponential viability of WT (SC5314) and the three TF KOs profiled by RNA-seq
#      (NRG1, NDT80, STP4). Quiescent = Day 3 samples of the 19-KO validation (OzanImir_20260401_v1, the
#      same data as the supplementary panel). Exponential = untreated rich-media samples of the resubmission
#      experiment OzanImir_20260809_v1 (6HC group; NRG1: DR-group untreated, its 6HC untreated samples were
#      removed; same rule as Figure_6_TFKO_micafungin_proliferative.Rmd). The two are separate experiments.
#      Each quiescent replicate is divided by the mean exponential viability of the same strain.
#      Bars = mean ratio, error bars = SE, points = replicates (n = 3); dashed line = WT mean.
#      Stars: Welch t-test of KO vs WT ratios, BH-adjusted over the three KOs.
#   B-D) Strain x time interaction volcanoes, (KO 72h - KO 6h) - (BG 72h - BG 6h), for NRG, STP, NDT
#        (same contrasts as CandidaTFKO5/analysis/results_quiescence/volcanoes/volcano_*_x_time_vs_BG_.png).
#        DE = padj < 0.05 and |shrunken LFC| >= 1 (DESeq2 + ashr). DE genes annotated in CGD GO (root term
#        + all descendants) are coloured: autophagy-related (GO:0006914 autophagy, GO:0000423 mitophagy,
#        GO:0000045 autophagosome assembly), biofilm formation (GO:0042710), drug resistance (GO:0009410
#        response to xenobiotic stimulus [CGD's former "response to drug"], GO:2001038, GO:0015903,
#        GO:0045117). The top 10 upregulated genes per KO are labelled in bold dark red, ranked by
#        -log10(padj) x log2FC among DE up genes, selection markers excluded (the same ranking as the
#        source volcanoes, which name the top 20).
#   Supplement: Day 3 / Day 7 quiescent viability of the 19 validated TF KOs vs WT on the same day
#        (OzanImir_20260401_v1; Welch t-test vs WT, BH within day, as in Figure_6_TFKO_viability_validation.Rmd).
# Run from this folder: Rscript Figure_6_v4_assemble.R   (R 4.6.1; GO.db, dplyr, ggplot2, ggrepel, patchwork)
suppressPackageStartupMessages({
  library(GO.db); library(AnnotationDbi)
  library(dplyr); library(ggplot2); library(ggrepel); library(patchwork)
})
val_csv <- "data/flow_validation/viability_by_replicate_OzanImir_20260401_v1.csv"
exp_csv <- "data/flow_micafungin_proliferative/viability_normalized_to_untreated_OzanImir_20260809_v1.csv"
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
star_of <- function(p) case_when(is.na(p) ~ "", p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ "")

## ---- A: Day 3 quiescent / exponential viability (untreated) ----
a_strains <- c("WT", "NRG1", "NDT80", "STP4")
exp_v <- read.csv(exp_csv) %>% filter(dose == "Untreated", media == "Rich", knockout %in% a_strains) %>%
  mutate(viability = Live_cells / (Live_cells + Dead_cells))
stopifnot(all(exp_v$group[exp_v$knockout != "NRG1"] == "6HC"), all(table(exp_v$knockout) == 3))
qui_v <- read.csv(val_csv) %>% filter(day == "Day3", knockout %in% a_strains) %>%
  mutate(viability = Live_cells / (Live_cells + Dead_cells))
stopifnot(all(table(qui_v$knockout) == 3))
qe <- qui_v %>% select(knockout, well, qui = viability) %>%
  left_join(exp_v %>% group_by(knockout) %>% summarise(exp_mean = mean(viability)), by = "knockout") %>%
  mutate(ratio = qui / exp_mean, knockout = factor(knockout, a_strains))
qe_sum <- qe %>% group_by(knockout) %>%
  summarise(qui_mean = mean(qui), exp_mean = exp_mean[1], mean_ratio = mean(ratio),
            se = sd(ratio) / sqrt(n()), max_pt = max(ratio),
            p_value = if (knockout[1] == "WT") NA_real_ else t.test(ratio, qe$ratio[qe$knockout == "WT"])$p.value,
            .groups = "drop") %>%
  mutate(p_adj = p.adjust(p_value, "BH"), star = star_of(p_adj), grp = ifelse(knockout == "WT", "WT", "KO"))
print(qe_sum)
wt_ratio <- qe_sum$mean_ratio[qe_sum$knockout == "WT"]
pA <- ggplot(qe_sum, aes(knockout, mean_ratio)) +
  geom_col(aes(fill = grp), width = 0.68) +
  geom_hline(yintercept = wt_ratio, linetype = "dashed", linewidth = 0.35, colour = "#c0392b") +
  geom_errorbar(aes(ymin = mean_ratio - se, ymax = mean_ratio + se), width = 0.25, linewidth = 0.3, colour = ink) +
  geom_point(data = qe, aes(y = ratio), size = 1, colour = ink, alpha = 0.8,
             position = position_jitter(width = 0.1, height = 0, seed = 1)) +
  # stars sit above the bar; if that lands on the WT line, move them just above it
  geom_text(aes(y = ifelse(abs(pmax(max_pt, mean_ratio + se) + 0.02 - wt_ratio) < 0.035, wt_ratio + 0.012,
                           pmax(max_pt, mean_ratio + se) + 0.02), label = star),
            size = 3.4, colour = ink, vjust = 0) +
  scale_fill_manual(values = c(KO = "#5b87b8", WT = "#c0392b"), guide = "none") +
  scale_y_continuous(limits = c(0, 1.1), breaks = seq(0, 1, 0.2), expand = c(0, 0)) +
  labs(x = NULL, y = "Viability ratio, quiescent (Day 3) / exponential", title = "Quiescent survival relative to WT",
       subtitle = "n = 3; dashed line = WT") +
  theme_fig +
  theme(axis.text.x = element_text(colour = ink, size = 8, face = c("bold", rep("bold.italic", 3))))

## ---- Supplement: 19 validated TF KOs, Day 3 / Day 7 quiescent viability vs WT (same day) ----
val <- read.csv(val_csv) %>%
  mutate(knockout = ifelse(knockout == "unspecified", "orf19.3253", knockout),
         viability = Live_cells / (Live_cells + Dead_cells),
         day = sub("Day", "Day ", day))
stopifnot(nrow(val) == 120L)
val_order <- unique(val$knockout[order(as.integer(sub("Well", "", val$well)))])  # plate layout, WT first
val_sum <- val %>% group_by(day, knockout) %>%
  summarise(mean_v = mean(viability), se = sd(viability) / sqrt(n()), max_pt = max(viability),
            p_value = if (knockout[1] == "WT") NA_real_ else
              t.test(viability, val$viability[val$knockout == "WT" & val$day == day[1]])$p.value,
            .groups = "drop") %>%
  group_by(day) %>% mutate(p_adj = p.adjust(p_value, "BH")) %>% ungroup() %>%
  mutate(star = star_of(p_adj), grp = ifelse(knockout == "WT", "WT", "KO"),
         knockout = factor(knockout, val_order))
pS <- ggplot(val_sum, aes(knockout, mean_v * 100)) +
  geom_col(aes(fill = grp), width = 0.72) +
  geom_errorbar(aes(ymin = (mean_v - se) * 100, ymax = pmin(mean_v + se, 1) * 100), width = 0.3,
                linewidth = 0.3, colour = ink) +
  geom_point(data = val %>% mutate(knockout = factor(knockout, val_order)), aes(y = viability * 100),
             size = 0.7, colour = ink, alpha = 0.75, position = position_jitter(width = 0.12, height = 0, seed = 1)) +
  geom_text(aes(y = pmax(max_pt, mean_v + se) * 100 + 1.5, label = star), size = 3.4, colour = ink, vjust = 0) +
  facet_wrap(~day, nrow = 1) +
  scale_fill_manual(values = c(KO = "#5b87b8", WT = "#c0392b"), guide = "none") +
  scale_y_continuous(limits = c(0, 108), breaks = seq(0, 100, 20), expand = c(0, 0)) +
  labs(x = NULL, y = "Viability (%)", title = "Quiescent viability of 19 selected TF KOs",
       caption = "Bars = mean of 3 replicates, error bars = SE. * BH-adjusted p < 0.05, Welch t-test vs WT on the same day.") +
  theme_fig +
  theme(axis.text.x = element_text(angle = 50, hjust = 1, vjust = 1, colour = ink,
                                   face = ifelse(val_order == "WT", "bold", "italic")),
        strip.background = element_blank(), strip.text = element_text(size = 9, face = "bold", colour = ink),
        plot.caption = element_text(size = 7, colour = ink2))
ggsave(file.path(out_dir, "Supplementary_TFKO_validation_Day3_Day7.png"), pS, width = 11, height = 4, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "Supplementary_TFKO_validation_Day3_Day7.pdf"), pS, width = 11, height = 4, bg = "white")
write.csv(val_sum %>% select(day, knockout, mean_v, se, p_value, p_adj, star),
          file.path(out_dir, "Supplementary_TFKO_validation_Day3_Day7_stats.csv"), row.names = FALSE)

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
pB <- volcano("NRG")
pC <- volcano("STP") + guides(fill = "none"); pD <- volcano("NDT") + guides(fill = "none")

n_top_cat <- sum(ix$top10 & !is.na(ix$category))
legend_note <- paste0("Bold dark-red labels: top 10 upregulated genes per KO (DE up, ranked by -log10 padj x log2FC)",
                      ifelse(n_top_cat == 0, "; none falls in a highlighted GO category.",
                             "; a dark-red ring marks one that also falls in a highlighted GO category."))
fig <- (pA | pB | pC | pD) +
  plot_layout(widths = c(0.42, 1, 1, 1), guides = "collect") +
  plot_annotation(tag_levels = "A", caption = legend_note,
                  theme = theme(plot.caption = element_text(size = 7.5, colour = ink2, hjust = 0.5))) &
  theme(legend.position = "bottom", legend.title = element_text(size = 7.5, colour = ink))
ggsave(file.path(out_dir, "Figure_6_v4.png"), fig, width = 16, height = 6.8, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "Figure_6_v4.pdf"), fig, width = 16, height = 6.8, bg = "white")

write.csv(qe_sum %>% select(knockout, qui_mean, exp_mean, mean_ratio, se, p_value, p_adj, star),
          file.path(out_dir, "Figure_6_v4_A_quiescent_over_exponential.csv"), row.names = FALSE)
write.csv(ix %>% filter(!is.na(category) | top10) %>% arrange(contrast, top_up_rank) %>%
            select(contrast, gene_id, gene, category, top10, top_up_rank, Mitophagy, `Autophagosome assembly`,
                   Autophagy, `Biofilm formation`, `Drug resistance`, log2FC, padj, direction, note),
          file.path(out_dir, "Figure_6_v4_highlighted_genes.csv"), row.names = FALSE)
