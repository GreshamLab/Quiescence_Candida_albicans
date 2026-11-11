# Figure TFBS (draft). Step 2b: site-based motif enrichment from the FIMO scan of all promoters.
# Run from this folder after 02_run_motif_enrichment.sh.
#
# A promoter "has a site" for a motif if FIMO reports >= 1 match at p < 1e-4 (either strand,
# background = promoter base composition). For every target set and motif, the fraction of target
# promoters with a site is compared with the fraction among unchanged promoters by logistic
# regression, has_site ~ target + log(promoter length), so that longer promoters do not inflate
# the counts. p-values are BH-adjusted across motifs within each set. Unlike SEA, whose site
# threshold is re-optimised on a random hold-out split, this test is deterministic.
# Writes work/site_enrichment.csv.

suppressPackageStartupMessages({ library(tidyverse); library(data.table); library(Biostrings) })

prom_len <- width(readDNAStringSet("work/promoters_all.fa")) %>%
  setNames(names(readDNAStringSet("work/promoters_all.fa")))
fimo <- fread("work/fimo_promoters_p1e-4.tsv.gz")
sites <- fimo[, .(n_sites = .N), by = .(motif_id, gene_id = sequence_name)]
classes <- fread("work/gene_classes.csv.gz")
sets <- read_csv("work/set_summary.csv", show_col_types = FALSE)
motifs <- read_csv("work/motif_annotation.csv", show_col_types = FALSE)$motif_id

has_site <- dcast(sites, gene_id ~ motif_id, value.var = "n_sites", fill = 0)
missing <- setdiff(motifs, names(has_site))            # motifs with no site in any promoter
for (m in missing) has_site[[m]] <- 0
has_site <- has_site[match(names(prom_len), gene_id)]
has_site[is.na(gene_id), gene_id := names(prom_len)[is.na(has_site$gene_id)]]
for (m in motifs) set(has_site, which(is.na(has_site[[m]])), m, 0)

res <- pmap_dfr(sets, function(set_group, contrast, direction, set, n_target, n_control) {
  this_contrast <- contrast; this_dir <- direction   # data.table would read the bare names as columns
  cl <- as.data.table(classes)[classes$contrast == this_contrast & classes$class %in% c(this_dir, "unchanged")]
  cl <- unique(cl, by = "gene_id")
  idx <- match(cl$gene_id, has_site$gene_id)
  tgt <- cl$class == this_dir; ll <- log(prom_len[cl$gene_id])
  stopifnot(sum(tgt) == n_target)
  map_dfr(motifs, function(m) {
    s <- has_site[[m]][idx]; y <- s > 0
    k_t <- sum(y[tgt]); k_c <- sum(y[!tgt])
    p <- if (k_t + k_c >= 3) {
      fit <- glm(y ~ tgt + ll, family = binomial())
      summary(fit)$coefficients["tgtTRUE", "Pr(>|z|)"]
    } else NA_real_
    or <- if (!is.na(p)) exp(coef(glm(y ~ tgt + ll, family = binomial()))[["tgtTRUE"]]) else NA_real_
    tibble(set = set, motif_id = m, n_target = sum(tgt), n_control = sum(!tgt),
           tp = k_t, fp = k_c, tp_pct = 100 * k_t / sum(tgt), fp_pct = 100 * k_c / sum(!tgt),
           sites_per_kb_target = 1000 * sum(s[tgt]) / sum(exp(ll[tgt])),
           sites_per_kb_control = 1000 * sum(s[!tgt]) / sum(exp(ll[!tgt])),
           odds_ratio_len_adj = or, p = p)
  }) %>% mutate(q = p.adjust(p, "BH"), enr = tp_pct / fp_pct, direction_of_effect = ifelse(enr > 1, "enriched", "depleted"))
})
write_csv(res, "work/site_enrichment.csv")
res %>% group_by(set) %>% summarise(n_enriched_q05 = sum(q < 0.05 & enr > 1, na.rm = TRUE)) %>% print(n = Inf)
