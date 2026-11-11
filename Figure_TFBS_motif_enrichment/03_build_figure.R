# Figure TFBS (draft). Step 3: assemble the figure from the SEA and Tomtom results.
# Run from this folder: Rscript 03_build_figure.R
# Writes output/Figure_TFBS_draft_v1.{png,pdf} and the tables behind each panel.

suppressPackageStartupMessages({
  library(tidyverse); library(patchwork); library(ggtext)
})
# The cluster's containerised R starts in the C locale; Unicode glyphs (x, minus, Delta) need UTF-8.
invisible(Sys.setlocale("LC_ALL", "C.UTF-8"))
out_dir <- "output"; dir.create(out_dir, showWarnings = FALSE)
q_cut <- 0.05

ink <- "#2b2b2a"; ink2 <- "#6b6a65"; up_col <- "#a11d1d"; ctrl_col <- "#9a9893"
theme_fig <- theme_classic(base_size = 8) +
  theme(axis.text = element_text(size = 10, colour = ink2), axis.title = element_text(size = 12, colour = ink),
        axis.line = element_line(colour = "grey55", linewidth = 0.3),
        axis.ticks = element_line(colour = "grey55", linewidth = 0.3),
        strip.background = element_blank(), strip.text = element_text(size = 11, colour = ink),
        legend.text = element_text(size = 10, colour = ink), legend.title = element_text(size = 10.5, colour = ink),
        plot.title = element_text(size = 12, colour = ink, face = "bold"),
        plot.tag = element_text(size = 16, face = "bold"))

# ---- Inputs --------------------------------------------------------------------------------
ann  <- read_csv("work/motif_annotation.csv", show_col_types = FALSE)
sets <- read_csv("work/set_summary.csv", show_col_types = FALSE)
# Site-based enrichment (02b_site_enrichment.R): FIMO p < 1e-4, length-adjusted logistic test, BH.
# Only enrichment (target > unchanged) counts as significant in the figure.
consensus <- read_tsv("work/sea/Rich_72h_vs_2h__up.tsv", comment = "#", show_col_types = FALSE) %>%
  select(motif_id = ID, consensus = CONSENSUS)
sea <- read_csv("work/site_enrichment.csv", show_col_types = FALSE) %>%
  select(-n_target, -n_control) %>%
  left_join(sets, by = "set") %>% left_join(ann, by = "motif_id") %>% left_join(consensus, by = "motif_id") %>%
  mutate(q = ifelse(is.na(q), 1, q), sig = q < q_cut & enr > 1)
stopifnot(all(table(sea$set) == nrow(ann)))

# ---- Motif families (Tomtom, q < 0.05, average linkage) -------------------------------------
tt <- read_tsv("work/tomtom_all_vs_all.tsv", comment = "#", show_col_types = FALSE) %>%
  filter(`q-value` < 0.05, Query_ID != Target_ID)
ids <- ann$motif_id
sim <- matrix(0, length(ids), length(ids), dimnames = list(ids, ids))
sim[cbind(tt$Query_ID, tt$Target_ID)] <- 1
sim <- pmax(sim, t(sim)); diag(sim) <- 1
fam <- cutree(hclust(as.dist(1 - sim), method = "average"), h = 0.5)
ann <- ann %>% mutate(family = unname(fam[motif_id]))
sea <- sea %>% left_join(ann %>% select(motif_id, family), by = "motif_id")
write_csv(ann, file.path(out_dir, "Figure_TFBS_motif_annotation_and_families.csv"))

# A family is represented, in every panel, by its best motif in the reference set
# (Rich 72 h induced, or Rich 72 h repressed for families shown only on the repressed side).
# A motif with a C. albicans ortholog is preferred when its q is within 10-fold of the family's best.
pick_rep <- function(d) {
  d %>% filter(enr > 1) %>% group_by(family) %>%
    arrange(q, .by_group = TRUE) %>%
    mutate(n_sig = sum(sig), members = paste(motif_alt[sig], collapse = ", "),
           has_ca = !is.na(ca_ortholog) & sig & q <= 10 * min(q)) %>%
    filter(if (any(has_ca)) has_ca else row_number() == 1) %>% slice(1) %>% ungroup() %>% arrange(q)
}
ref_up <- "Rich_72h_vs_2h__up"; ref_dn <- "Rich_72h_vs_2h__down"
rep_up <- sea %>% filter(set == ref_up) %>% pick_rep() %>% filter(sig)
rep_dn <- sea %>% filter(set == ref_dn) %>% pick_rep() %>% filter(sig, !family %in% rep_up$family)
cat(sprintf("Rich 72 h induced: %d motifs enriched (q < 0.05) in %d families\n",
            sum(sea$set == ref_up & sea$sig), nrow(rep_up)))
cat(sprintf("Rich 72 h repressed: %d motifs enriched in %d further families\n",
            sum(sea$set == ref_dn & sea$sig), nrow(rep_dn)))

fmt_label <- function(label, n_sig) {
  lab <- str_replace(label, " \\(Sc; no Ca ortholog\\)", "<sup>Sc</sup>")
  lab <- str_replace(lab, "\\(Sc ([^)]+)\\)", "<span style='color:#6b6a65'>(Sc \\1)</span>")
  paste0("*", lab, "*", ifelse(n_sig > 1, paste0(" <span style='color:#6b6a65'>+", n_sig - 1, "</span>"), ""))
}
q_lab <- function(q) ifelse(q < 1e-3, sprintf("%.0e", q), sprintf("%.3f", q)) %>%
  str_replace("e-0?", "&times;10<sup>&minus;") %>% { ifelse(grepl("sup", .), paste0(., "</sup>"), .) }

# ---- Panel A: induced promoters vs unchanged promoters, top families -------------------------
n_top <- 15
a_dat <- rep_up %>% slice_head(n = n_top) %>%
  mutate(row = fmt_label(label, n_sig), row = fct_rev(fct_inorder(row)))
a_long <- a_dat %>% select(row, tp_pct, fp_pct) %>%
  pivot_longer(c(tp_pct, fp_pct), names_to = "grp", values_to = "pct") %>%
  mutate(grp = factor(recode(grp, tp_pct = "Induced at 72 h", fp_pct = "Unchanged"),
                      levels = c("Induced at 72 h", "Unchanged")))
xmax <- max(a_long$pct) * 1.02
pA <- ggplot(a_dat, aes(y = row)) +
  geom_segment(aes(x = fp_pct, xend = tp_pct, yend = row), colour = "grey75", linewidth = 0.9) +
  geom_point(data = a_long, aes(x = pct, colour = grp), size = 2.8) +
  geom_richtext(aes(x = xmax * 1.05, label = paste0(tp, "/", n_target)),
                hjust = 0, size = 3.2, colour = ink2, fill = NA, label.colour = NA) +
  geom_richtext(aes(x = xmax * 1.31, label = paste0(sprintf("%.1f", enr), "&times;")),
                hjust = 0, size = 3.2, colour = ink2, fill = NA, label.colour = NA) +
  geom_richtext(aes(x = xmax * 1.46, label = q_lab(q)),
                hjust = 0, size = 3.2, colour = ink2, fill = NA, label.colour = NA) +
  annotate("text", x = xmax * c(1.05, 1.31, 1.46) + 0.6, y = n_top + 0.9,
           label = c("promoters", "ratio", "q"), hjust = 0, size = 3.2, colour = ink, fontface = "bold") +
  scale_colour_manual(values = c(`Induced at 72 h` = up_col, Unchanged = ctrl_col), name = NULL) +
  scale_x_continuous(limits = c(0, xmax * 1.66), breaks = seq(0, 100, 20), expand = expansion(mult = c(0, 0))) +
  coord_cartesian(clip = "off") +
  labs(x = "% of promoters with \u2265 1 site (FIMO p < 10\u207b\u2074)", y = NULL,
       title = "Motif families in quiescence-induced promoters (Rich, 72 h vs 2 h)") +
  theme_fig + theme(axis.text.y = element_markdown(size = 10.5, colour = ink),
                    legend.position = "bottom", plot.title.position = "plot")

# ---- Panel B: the same families over the time course, induced and repressed -----------------
n_dn <- 6
rows_b <- bind_rows(rep_up %>% slice_head(n = n_top) %>% mutate(block = "Induced-gene motifs"),
                    rep_dn %>% slice_head(n = n_dn) %>% mutate(block = "Repressed-gene motifs")) %>%
  mutate(row = fmt_label(label, n_sig))
b_dat <- sea %>% filter(set_group == "WT time course", motif_id %in% rows_b$motif_id) %>%
  left_join(rows_b %>% select(motif_id, row, block), by = "motif_id") %>%
  mutate(medium = sub("_.*", "", contrast), time = as.integer(str_extract(contrast, "(?<=_)[0-9]+(?=h)")),
         dir = factor(ifelse(direction == "up", "Induced vs 2 h", "Repressed vs 2 h"),
                      levels = c("Induced vs 2 h", "Repressed vs 2 h")),
         medium = factor(medium, levels = c("Rich", "Minimal")),
         row = factor(row, levels = rev(rows_b$row)),
         l2e = log2(pmax(enr, 1e-3)))
pB <- ggplot(b_dat, aes(factor(time), row)) +
  geom_tile(aes(fill = l2e), colour = "white", linewidth = 0.6) +
  geom_point(data = ~ filter(.x, sig), size = 0.9, colour = ink) +
  scale_fill_gradient2(low = "#3b6fb6", mid = "#f2f1ee", high = up_col, midpoint = 0,
                       limits = c(-1.25, 1.25), oob = scales::squish,
                       name = "log<sub>2</sub> enrichment<br>(target / unchanged)") +
  facet_grid(block ~ dir + medium, scales = "free_y", space = "free_y") +
  labs(x = "Hours in culture", y = NULL,
       title = "The same motif families across the time course",
       caption = "\u2022 enriched, q < 0.05") +
  theme_fig + theme(axis.text.y = element_markdown(size = 10, colour = ink),
                    axis.line = element_blank(), axis.ticks = element_blank(),
                    legend.title = element_markdown(size = 10.5, colour = ink),
                    strip.text.y = element_text(angle = 0, hjust = 0),
                    plot.caption = element_text(size = 9.5, colour = ink2), plot.title.position = "plot")

# ---- Panel C: motifs of the Figure 6 TFs in the TF-dependent gene sets ----------------------
c_motifs <- ann %>% filter(motif_alt %in% c("NRG1", "NDT80", "STP3", "STP4")) %>%
  mutate(row = case_when(motif_alt == "NRG1" ~ "Nrg1 (Sc NRG1)", motif_alt == "NDT80" ~ "Ndt80 (Sc NDT80)",
                         motif_alt == "STP3" ~ "Stp4 (Sc STP3)", motif_alt == "STP4" ~ "Stp4 (Sc STP4)"))
c_sets <- tribble(
  ~set,                    ~col,
  "Rich_72h_vs_2h__up",    "WT Rich<br>72 h &uarr;",
  "Minimal_72h_vs_2h__up", "WT Minimal<br>72 h &uarr;",
  "nrg1__up",   "*nrg1*&Delta;<br>higher", "nrg1__down",  "*nrg1*&Delta;<br>lower",
  "ndt80__up",  "*ndt80*&Delta;<br>higher", "ndt80__down", "*ndt80*&Delta;<br>lower",
  "stp4__up",   "*stp4*&Delta;<br>higher", "stp4__down",  "*stp4*&Delta;<br>lower")
c_dat <- sea %>% inner_join(c_motifs %>% select(motif_id, row), by = "motif_id") %>%
  inner_join(c_sets, by = "set") %>%
  mutate(col = factor(col, levels = c_sets$col),
         row = factor(row, levels = rev(c("Nrg1 (Sc NRG1)", "Ndt80 (Sc NDT80)", "Stp4 (Sc STP3)", "Stp4 (Sc STP4)"))),
         l2e = ifelse(sig, log2(enr), NA_real_),
         lab = paste0(round(tp), "/", n_target, "\n", ifelse(sig, paste0("q = ", signif(q, 1)), "n.s.")))
pC <- ggplot(c_dat, aes(col, row)) +
  geom_tile(aes(fill = l2e), colour = "white", linewidth = 0.6) +
  geom_text(aes(label = lab), size = 2.9, colour = ink, lineheight = 0.9) +
  scale_fill_gradient2(low = "#3b6fb6", mid = "#f2f1ee", high = up_col, midpoint = 0,
                       limits = c(-1.25, 1.25), oob = scales::squish, na.value = "#f4f3f0", guide = "none") +
  labs(x = NULL, y = NULL, caption = "Promoters with \u2265 1 site / promoters in set; coloured only where enriched at q < 0.05",
       title = "Motifs of the quiescence-survival TFs (Figure 6) in TF-dependent genes") +
  theme_fig + theme(axis.text.x = element_markdown(size = 10, colour = ink, lineheight = 1.1),
                    axis.text.y = element_text(size = 10.5, colour = ink, face = "italic"),
                    axis.line = element_blank(), axis.ticks = element_blank(), plot.title.position = "plot",
                    plot.caption = element_text(size = 9.5, colour = ink2))

# ---- Assemble -------------------------------------------------------------------------------
fig <- (pA | pB) / pC + plot_layout(heights = c(1.55, 0.62), widths = c(1, 1.15)) +
  plot_annotation(tag_levels = "A")
ggsave(file.path(out_dir, "Figure_TFBS_draft_v1.png"), fig, width = 17, height = 10.5, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "Figure_TFBS_draft_v1.pdf"), fig, width = 17, height = 10.5, bg = "white", device = cairo_pdf)

# ---- Tables ---------------------------------------------------------------------------------
write_csv(sea %>% select(set_group, contrast, direction, n_target, n_control, motif_id, motif_alt, label,
                         ca_ortholog, family, consensus, tp, tp_pct, fp, fp_pct, enr,
                         sites_per_kb_target, sites_per_kb_control, odds_ratio_len_adj, p, q) %>%
            arrange(set_group, contrast, direction, q),
          file.path(out_dir, "Figure_TFBS_site_enrichment_all_sets.csv"))
write_csv(a_dat %>% select(family, motif_id, motif_alt, label, ca_ortholog, consensus, tp, tp_pct, fp_pct,
                           enr, q, n_sig, members),
          file.path(out_dir, "Figure_TFBS_A_rich72h_induced_families.csv"))
write_csv(c_dat %>% select(row, set, n_target, tp, tp_pct, fp_pct, enr, q),
          file.path(out_dir, "Figure_TFBS_C_figure6_TF_motifs.csv"))
print(a_dat %>% select(label, consensus, tp_pct, fp_pct, enr, q, n_sig), n = Inf, width = 200)
print(rep_dn %>% select(label, consensus, tp_pct, fp_pct, enr, q, n_sig) %>% head(n_dn), width = 200)

# ---- Cross-check with SEA (threshold optimised on a random hold-out; seed 1) ----------------
sea_chk <- read_tsv("work/sea/Rich_72h_vs_2h__up.tsv", comment = "#", show_col_types = FALSE) %>%
  transmute(motif_id = ID, sea_q = exp(LOG_QVALUE))
chk <- a_dat %>% select(label, motif_id, family) %>% left_join(sea_chk, by = "motif_id")
cat(sprintf("Panel A families also significant by SEA (rep. motif, q < 0.05): %d of %d\n",
            sum(chk$sea_q < q_cut, na.rm = TRUE), nrow(chk)))
