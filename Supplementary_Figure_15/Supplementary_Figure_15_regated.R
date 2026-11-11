# Supplementary Figure 15, regenerated so that all three panels of a row show the same events.
#
# In the original figure the PI and SYTO9 histograms were drawn from every recorded event ("root")
# on a log10 axis, which drops events with values <= 0, while the 2D plot showed only Single_cells
# on an arcsinh axis, including events with negative PI. Here single cells with PI <= 0 are gated
# out first (PI_positive gate), and the histograms, the 2D plot and the gate percentages all use
# the remaining events on the same arcsinh axis.
#
# Gates: Cells and Single_cells from cytek_gating_OzanImir_20250918_v1.csv, Live_cells and
# Dead_cells from cytek_gating_OzanImir_20250918_v2.csv (v2 holds no parent gates).
# Hierarchy: Cells > Single_cells > PI_positive (PI > 0) > Live_cells / Dead_cells.
# The saved Live_cells polygon extends to negative PI; it is cut off in the positive PI region and
# closed with a few angled segments (not one vertical edge at PI = 0), so that the gate lies entirely
# at PI > 0. The saved Dead_cells polygon stops short of the brightest PI events; its high-PI side
# (three vertices) is replaced so that the gate reaches the detector maximum. The final vertices are
# written to output/.
#
# Run from this folder: Rscript Supplementary_Figure_15_regated.R [FCS folder]
suppressPackageStartupMessages({library(tidyverse); library(cowplot)})

args <- commandArgs(trailingOnly = TRUE)
fcs_dir <- if (length(args)) args[1] else file.path(
  "/scratch/obi203/data/Cytek Flow Cytometry",
  "X FINISHED -- Candida_albicans_Fungicidal_Drug_Screening/Supplementary Figure Reanalysis",
  "HeatKilling_FCS_Analysis/FCS_files")
dir.create("output", showWarnings = FALSE)

# Minimal FCS 3.x reader (float32 list-mode data, as written by the Cytek Aurora)
read_fcs <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  hdr <- readChar(con, 58, useBytes = TRUE)
  ts <- as.integer(substr(hdr, 11, 18)); te <- as.integer(substr(hdr, 19, 26))
  seek(con, ts); txt <- readChar(con, te - ts + 1, useBytes = TRUE)
  d <- substr(txt, 1, 1); parts <- strsplit(substring(txt, 2), d, fixed = TRUE)[[1]]
  kw <- setNames(parts[seq(2, length(parts), 2)], toupper(parts[seq(1, length(parts), 2)]))
  stopifnot(kw[["$DATATYPE"]] == "F")
  npar <- as.integer(kw[["$PAR"]]); ntot <- as.integer(kw[["$TOT"]])
  endian <- if (kw[["$BYTEORD"]] == "1,2,3,4") "little" else "big"
  seek(con, as.numeric(trimws(kw[["$BEGINDATA"]])))
  m <- matrix(readBin(con, "numeric", n = npar * ntot, size = 4, endian = endian), ncol = npar, byrow = TRUE)
  colnames(m) <- vapply(seq_len(npar), function(i) kw[[paste0("$P", i, "N")]], "")
  m
}

# flowJo arcsinh as applied by CytoExploreR (T = 262144, M = 4.5, A = 0)
fasinh <- function(x, t = 262144, m = 4.5) asinh(x * sinh(m * log(10)) / t) / (m * log(10))

parse_template <- function(csv) {
  gt <- read.csv(csv, stringsAsFactors = FALSE)
  setNames(lapply(seq_len(nrow(gt)), function(i) {
    nums <- as.numeric(strsplit(sub(".*boundaries = structure\\(c\\(([^)]*)\\).*", "\\1",
                                    gt$gating_args[i]), ",")[[1]])
    dims <- strsplit(gt$dims[i], ",")[[1]]
    list(parent = gt$parent[i], dims = dims, poly = matrix(nums, ncol = 2, dimnames = list(NULL, dims)))
  }), gt$alias)
}

apply_gates <- function(tm, gates) {
  keep <- list(root = rep(TRUE, nrow(tm)))
  for (g in names(gates)) {
    G <- gates[[g]]
    keep[[g]] <- keep[[G$parent]] &
      sp::point.in.polygon(tm[, G$dims[1]], tm[, G$dims[2]], G$poly[, 1], G$poly[, 2]) > 0
  }
  keep
}

gates <- c(parse_template("data/cytek_gating_OzanImir_20250918_v1.csv")[c("Cells", "Single_cells")],
           parse_template("data/cytek_gating_OzanImir_20250918_v2.csv"))

# Clip a polygon to x >= xmin (Sutherland-Hodgman, one edge)
clip_left <- function(poly, xmin = 0) {
  n <- nrow(poly); out <- list()
  for (i in seq_len(n)) {
    a <- poly[i, ]; b <- poly[if (i == n) 1 else i + 1, ]
    if (a[1] >= xmin) out[[length(out) + 1]] <- a
    if ((a[1] >= xmin) != (b[1] >= xmin))
      out[[length(out) + 1]] <- c(xmin, a[2] + (b[2] - a[2]) * (xmin - a[1]) / (b[1] - a[1]))
  }
  m <- do.call(rbind, out); dimnames(m) <- list(NULL, colnames(poly)); m
}
# Close the low-PI end of a polygon with a polygonal cap: cut at x = depth, then add four vertices
# on a half-ellipse whose tip sits at x = tip (> 0). Units are arcsinh-transformed PI.
cap_left <- function(poly, depth = 0.05, tip = 0.002) {
  cut <- clip_left(poly, depth)
  on_cut <- which(abs(cut[, 1] - depth) < 1e-12)
  stopifnot(length(on_cut) == 2, diff(on_cut) == 1)            # the two cut points are consecutive
  y1 <- cut[on_cut[1], 2]; y2 <- cut[on_cut[2], 2]
  th <- seq(pi / 2, -pi / 2, length.out = 6)[2:5]
  cap <- cbind(tip + (depth - tip) * (1 - cos(th)), (y1 + y2) / 2 + (y1 - y2) / 2 * sin(th))
  m <- rbind(cut[seq_len(on_cut[1]), , drop = FALSE], cap, cut[on_cut[2]:nrow(cut), , drop = FALSE])
  dimnames(m) <- list(NULL, colnames(poly)); m
}
gates$Live_cells$poly <- cap_left(gates$Live_cells$poly)     # fasinh(0) = 0

# Dead_cells: keep the low-PI side and the edge facing Live_cells (saved vertices 1, 2, 6, 7, 8) and
# replace the high-PI side (saved vertices 3-5) with a wider polygonal end. Units are arcsinh-
# transformed; 1.0 is the detector maximum (262144).
dead <- gates$Dead_cells$poly
stopifnot(nrow(dead) == 8)
dead_high_PI <- rbind(c(0.95, 0.655), c(1.02, 0.74), c(1.03, 0.88), c(0.99, 0.985), c(0.90, 0.975), c(0.56, 0.87))
gates$Dead_cells$poly <- rbind(dead[1:2, ], dead_high_PI, dead[6:8, ])
colnames(gates$Dead_cells$poly) <- colnames(dead)
stopifnot(all(gates$Live_cells$poly[, 1] > 0), all(gates$Dead_cells$poly[, 1] > 0))
dir.create("output", showWarnings = FALSE)
write.csv(bind_rows(lapply(c("Live_cells", "Dead_cells"), function(g)
  tibble(gate = g, parent = "PI_positive", PI_arcsinh = gates[[g]]$poly[, 1], SYTO9_arcsinh = gates[[g]]$poly[, 2]))),
  "output/Supplementary_Figure_15_regated_gate_vertices.csv", row.names = FALSE)

details <- read.csv("data/Vignette-Experiment-Details.csv")

events <- vector("list", nrow(details)); counts <- vector("list", nrow(details))
for (i in seq_len(nrow(details))) {
  raw <- read_fcs(file.path(fcs_dir, details$name[i])); tm <- raw
  for (ch in c("FSC-A", "FSC-H", "SSC-A", "SSC-H", "YG4-A", "B12-A")) tm[, ch] <- fasinh(raw[, ch])
  k <- apply_gates(tm, gates)
  pos <- k$Single_cells & raw[, "YG4-A"] > 0          # gate out negative PI
  k$Live_cells <- k$Live_cells & pos; k$Dead_cells <- k$Dead_cells & pos
  sc <- pos
  events[[i]] <- tibble(panel = LETTERS[i], PI_t = tm[sc, "YG4-A"], SYTO9_t = tm[sc, "B12-A"])
  counts[[i]] <- tibble(panel = LETTERS[i], fcs_file = details$name[i], growth = details$growth[i],
                        expected_viability = details$viability[i], all_events = nrow(raw),
                        Cells = sum(k$Cells), Single_cells = sum(k$Single_cells), PI_positive = sum(pos),
                        Live_cells = sum(k$Live_cells), Dead_cells = sum(k$Dead_cells),
                        PI_negative_removed = sum(k$Single_cells) - sum(pos))
}
events <- bind_rows(events)
counts <- bind_rows(counts) %>%
  mutate(PI_negative_removed_pct = 100 * PI_negative_removed / Single_cells,
         Live_pct = 100 * Live_cells / PI_positive, Dead_pct = 100 * Dead_cells / PI_positive,
         viability_pct = 100 * Live_cells / (Live_cells + Dead_cells))
write.csv(counts, "output/Supplementary_Figure_15_regated_gate_counts.csv", row.names = FALSE)
print(as.data.frame(counts %>% select(panel, Single_cells, PI_positive, PI_negative_removed_pct,
                                      Live_pct, Dead_pct, viability_pct)))

# ---- Figure ----
theme_set(theme_cowplot(font_size = 13))
dens_cols <- c("#00007F", "blue", "#007FFF", "cyan", "#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000")
br_raw <- c(-1e2, 0, 1e2, 1e3, 1e4, 1e5)
br_lab <- c(expression(-10^2), "0", expression(10^2), expression(10^3), expression(10^4), expression(10^5))
lims <- list(PI_t = fasinh(c(-8, 4e5)), SYTO9_t = fasinh(c(-150, 4e5)))

hist_panel <- function(df, var, xlabel) {
  ggplot(df, aes(.data[[var]])) +
    geom_histogram(bins = 300, boundary = 0, fill = "black", colour = "black", linewidth = 0.1) +
    scale_x_continuous(breaks = fasinh(br_raw), labels = br_lab) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
    coord_cartesian(xlim = lims[[var]], expand = TRUE) +
    labs(x = xlabel, y = "Count") +
    theme(plot.margin = margin(7, 7, 7, 26))
}

scatter_panel <- function(df, p) {
  bx <- cut(df$PI_t, 256); by <- cut(df$SYTO9_t, 256)
  df$dens <- ave(rep(1, nrow(df)), bx, by, FUN = length)
  df <- df[order(df$dens), ]
  polys <- bind_rows(lapply(c("Live_cells", "Dead_cells"), function(g)
    tibble(gate = g, x = gates[[g]]$poly[, 1], y = gates[[g]]$poly[, 2])))
  cnt <- counts[counts$panel == p, ]
  labs_df <- polys %>% group_by(gate) %>% summarise(x = mean(range(pmax(x, lims$PI_t[1]))), y = mean(range(y))) %>%
    mutate(label = sprintf("%s\n%.2f %%", gate, c(Dead_cells = cnt$Dead_pct, Live_cells = cnt$Live_pct)[gate]))
  ggplot(df, aes(PI_t, SYTO9_t)) +
    geom_point(aes(colour = dens), size = 0.06, shape = 16) +
    scale_colour_gradientn(colours = dens_cols, trans = "log10", guide = "none") +
    geom_polygon(data = polys, aes(x, y, group = gate), inherit.aes = FALSE,
                 fill = NA, colour = "red", linewidth = 0.7) +
    geom_label(data = labs_df, aes(x, y, label = label), inherit.aes = FALSE, size = 3.4,
               fontface = "bold", lineheight = 0.9, fill = alpha("white", 0.6), linewidth = 0,
               label.padding = unit(0.08, "lines")) +
    scale_x_continuous(breaks = fasinh(br_raw), labels = br_lab) +
    scale_y_continuous(breaks = fasinh(br_raw), labels = br_lab) +
    coord_cartesian(xlim = lims$PI_t, ylim = lims$SYTO9_t) +
    labs(x = "PI", y = "SYTO9") +
    theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.6), axis.line = element_blank())
}

rows <- lapply(LETTERS[seq_len(nrow(details))], function(p) {
  df <- filter(events, panel == p)
  plot_grid(hist_panel(df, "PI_t", "PI"), hist_panel(df, "SYTO9_t", "SYTO9"), scatter_panel(df, p),
            nrow = 1, align = "h", axis = "tb", labels = c(p, "", ""), label_size = 20)
})
fig <- plot_grid(plotlist = rows, ncol = 1)
ggsave("output/Supplementary_Figure_15_regated.png", fig, width = 13, height = 19, units = "in", dpi = 300, bg = "white")
ggsave("output/Supplementary_Figure_15_regated.pdf", fig, width = 13, height = 19, units = "in", bg = "white")
