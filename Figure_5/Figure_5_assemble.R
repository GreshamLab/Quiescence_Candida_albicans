# Figure 5: assemble the figure.
#
# Layout (changed from Figure5_Ver8):
#   - panel A (SC5314 micafungin dose response, PI/SYTO9 inset, CFU plates) is Ver8 panel A, unchanged,
#     cropped from Figure5_Ver8.png;
#   - Ver8 panel B (clinical isolates p57055 / p37005) is removed;
#   - Ver8 panel C (20 isolates + SC5314, boxplots) takes B's place on the right and is labelled "B".
#     It is re-plotted here from data/ (same code as Figure_5_isolate_drug_response_proliferative_vs_quiescent.Rmd)
#     so it can be drawn at the full height of panel A. The Ver8 styling that was added in the figure layout
#     (% scale, drug brackets, significance bars, Proliferative/Quiescent) is reproduced in ggplot.
#
# Run from this folder: Rscript Figure_5_assemble.R

invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(magick)
})
set.seed(1)

base_png <- "../../Figure_Design/Figure_Design/Figure5/Figure5_Ver8.png"
out_dir <- "output"
dir.create(out_dir, showWarnings = FALSE)
dpi <- 300
font <- "Liberation Sans"  # metric-compatible with Arial used in the figure

a_w <- 935    # panel A column (px), cropped from Ver8
fig_h <- 1700
gap <- 40     # px between the two panels
b_w <- 2400   # panel B width (px)

# ---- Panel B data (as in the Rmd) ----
read_data <- function(file) {
  read.table(file.path("data", file), header = TRUE, sep = ",", dec = ".", fill = TRUE,
             fileEncoding = "UTF-8-BOM")
}
df <- bind_rows(lapply(c("Isolates_AmpB_Exp.csv", "Isolates_AmpB_Qui.csv",
                         "Isolates_Caspofungin_Exp.csv", "Isolates_Caspofungin_Qui.csv",
                         "Isolates_Micafungin_Exp.csv", "Isolates_Micafungin_Qui.csv"), read_data))

conditions <- c("Untreated", "Caspofungin", "Micafungin", "AmphotericinB")
plot_data <- df %>%
  mutate(Viability = 100 * Live_percent / (Live_percent + Dead_percent),
         Condition = if_else(Dose == 0, "Untreated", Treatment)) %>%
  filter(Dose == 0 | Treatment %in% conditions) %>%
  mutate(Growth = factor(Growth, levels = c("Exponential", "Quiescent")),
         x = 2 * match(Condition, conditions) - 2 + as.integer(Growth))  # 1..8, pairs side by side

# Paired t-tests (paired by strain) for the treated conditions
stars <- function(p) if (p < 0.001) "***" else if (p < 0.01) "**" else if (p < 0.05) "*" else "n.s."
tests <- plot_data %>%
  filter(Condition != "Untreated") %>%
  select(Sample, Condition, Growth, Viability) %>%
  pivot_wider(names_from = Growth, values_from = Viability) %>%
  group_by(Condition) %>%
  summarise(p = t.test(Exponential, Quiescent, paired = TRUE)$p.value, .groups = "drop") %>%
  mutate(label = sapply(p, stars),
         x0 = 2 * match(Condition, conditions) - 1, x1 = x0 + 1,
         y = c(AmphotericinB = 9.5, Caspofungin = 0.8, Micafungin = 0.8)[Condition])  # as in Ver8
print(tests)

# Drug brackets and labels below the panel
brackets <- data.frame(x0 = seq(1, 7, 2) - 0.4, x1 = seq(2, 8, 2) + 0.4, y = -5)
tick <- 1.8  # bracket tick length (% units)

cols <- c(Exponential = "#F8766D", Quiescent = "#00BFC4")
p <- ggplot(plot_data, aes(x = x, y = Viability)) +
  geom_boxplot(aes(group = x, fill = Growth), outlier.shape = NA, width = 0.6, alpha = 0.8,
               colour = "grey20", linewidth = 0.6) +
  geom_point(data = filter(plot_data, Sample != "SC5314"),
             position = position_jitter(width = 0.08, height = 0),
             size = 1.3, colour = "black", alpha = 0.7) +
  geom_point(data = filter(plot_data, Sample == "SC5314"),
             position = position_jitter(width = 0.08, height = 0),
             size = 2.6, colour = "orange") +
  # significance brackets
  geom_segment(data = tests, aes(x = x0, xend = x1, y = y, yend = y), linewidth = 0.5) +
  geom_segment(data = tests, aes(x = x0, xend = x0, y = y, yend = y + tick), linewidth = 0.5) +
  geom_segment(data = tests, aes(x = x1, xend = x1, y = y, yend = y + tick), linewidth = 0.5) +
  geom_text(data = tests, aes(x = (x0 + x1) / 2, y = y + 0.6, label = label),
            vjust = 0, family = font, fontface = "bold", size = 4.6) +
  # drug brackets under the panel
  geom_segment(data = brackets, aes(x = x0, xend = x1, y = y, yend = y), linewidth = 0.6) +
  geom_segment(data = brackets, aes(x = x0, xend = x0, y = y, yend = y + 2.5), linewidth = 0.6) +
  geom_segment(data = brackets, aes(x = x1, xend = x1, y = y, yend = y + 2.5), linewidth = 0.6) +
  scale_fill_manual(values = cols, labels = c("Proliferative", "Quiescent"), name = "Growth Phase") +
  scale_x_continuous(breaks = seq(1.5, 7.5, 2),
                     labels = c("Untreated", "Caspofungin", "Micafungin", "Amphotericin-B"),
                     expand = expansion(add = 0.55)) +
  scale_y_continuous(breaks = seq(0, 100, 25), expand = expansion(add = 0)) +
  coord_cartesian(ylim = c(-3, 103), clip = "off") +
  labs(x = NULL, y = "Viability (%)") +
  theme_gray(base_family = font) +
  theme(
    panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.x = element_text(colour = "black", face = "bold", size = 14, angle = 60,
                               hjust = 1, vjust = 1, margin = margin(t = 22)),
    axis.text.y = element_text(colour = "black", face = "bold", size = 11),
    axis.title.y = element_text(colour = "black", face = "bold", size = 13),
    legend.title = element_text(face = "bold", size = 13),
    legend.text = element_text(size = 12.5),
    legend.key.size = unit(0.6, "cm"),
    plot.margin = margin(4, 4, 2, 22)
  )

panel_b_file <- file.path(out_dir, "Figure_5B_isolates_drug_response.png")
ggsave(panel_b_file, p, width = b_w / dpi, height = fig_h / dpi, dpi = dpi,
       device = ragg::agg_png, bg = "white")
ggsave(file.path(out_dir, "Figure_5B_isolates_drug_response.pdf"), p,
       width = b_w / dpi, height = fig_h / dpi, device = cairo_pdf)

# ---- Panel A: replace the data layer of Ver8 panel A ----
# Ver8 drew group means as large dots. Here the means are only joined by the line, and the replicate
# values are drawn as faint points. Axes, frame, inset and CFU plates stay the Ver8 pixels; only the
# plot interior is cleared (gridlines rebuilt from the Ver8 gridline profile) and redrawn.
# Values come from data/Panel_A_SC5314_micafungin_digitized.csv (see README). Where the replicates were
# hidden under the Ver8 mean dot (spread < ~0.6 %), the only value available is the mean, drawn as one point.
base <- image_read(base_png)
panel_a <- image_crop(base, geometry_area(a_w, fig_h, 0, 0)) %>%  # plot, inset, CFU plates and side labels
  image_composite(image_blank(40, 70, "white"), offset = "+895+0") # drop the edge of Ver8's "B" tag

# Ver8 plot interior and scale (1-based pixel centres, measured from the gridlines)
int_x <- c(156, 880); int_y <- c(7, 1166)
px_x <- function(dose) 192 + 161.875 * (log10(dose) + 3)   # 0.001 -> col 192, 10 -> col 839.5
px_y <- function(v) 25 + (100 - v) * 11.44                 # 100 % -> row 25, 50 % -> row 597
inset <- c(x0 = 178, y0 = 648, x1 = 533, y1 = 941)          # PI/SYTO9 inset, with a 3 px margin

# Clear the interior: rebuild gridlines as min(row profile, column profile) from data-free strips
arr <- as.integer(image_data(panel_a, "rgb"))
xs <- int_x[1]:int_x[2]; ys <- int_y[1]:int_y[2]
for (ch in 1:3) {
  row_prof <- apply(arr[ys, 862:878, ch], 1, median)        # right edge strip: no data, no labels
  col_prof <- apply(arr[950:1160, xs, ch], 2, median)       # strip below the inset
  arr[ys, xs, ch] <- outer(row_prof, col_prof, pmin)
}
inset_px <- as.integer(image_data(panel_a, "rgb"))[inset["y0"]:inset["y1"], inset["x0"]:inset["x1"], ]
arr[inset["y0"]:inset["y1"], inset["x0"]:inset["x1"], ] <- inset_px
panel_a <- image_read(arr / 255)

a_data <- read.csv(file.path("data", "Panel_A_SC5314_micafungin_digitized.csv"))
a_means <- a_data %>% transmute(Growth, Dose = Dose_ug_mL, Viability = Mean_viability_pct)
a_points <- a_data %>%
  mutate(Viability = if_else(Replicates_pct == "" | is.na(Replicates_pct),
                             as.character(Mean_viability_pct), Replicates_pct)) %>%
  separate_rows(Viability, sep = ";") %>%
  transmute(Growth, Dose = Dose_ug_mL, Viability = as.numeric(Viability))
# CFU plate letters at their Ver8 positions (pixel centres)
a_labels <- data.frame(
  label = letters[1:8],
  Growth = rep(c("Proliferative", "Quiescent"), each = 4),
  px = c(395, 554, 701, 841.5, 366.5, 531.5, 707.5, 844),
  py = c(37.5, 277.5, 1104.5, 1099.5, 192.5, 141.5, 156, 168.5)
)
inv_x <- function(p) 10^((p - 192) / 161.875 - 3)
inv_y <- function(p) 100 - (p - 25) / 11.44

a_line_cols <- c(Proliferative = "#DB5F5F", Quiescent = "#37C0BF")
a_text_cols <- c(Proliferative = "#F3756B", Quiescent = "#37C0BF")
a_w_in <- diff(int_x) + 1; a_h_in <- diff(int_y) + 1
pa <- ggplot(a_means, aes(Dose, Viability, colour = Growth)) +
  geom_point(data = a_points, size = 2.4, alpha = 0.35, stroke = 0) +
  geom_line(linewidth = 0.5) +
  # plate letters use a lighter red than the line, as in Ver8
  geom_text(data = a_labels, aes(inv_x(px), inv_y(py), label = label),
            colour = a_text_cols[a_labels$Growth], family = font, fontface = "bold",
            size = 2.75, inherit.aes = FALSE) +
  scale_colour_manual(values = a_line_cols) +
  scale_x_log10(limits = inv_x(int_x + c(-0.5, 0.5)), expand = expansion(0)) +
  scale_y_continuous(limits = inv_y(int_y + c(0.5, -0.5))[2:1], expand = expansion(0)) +
  theme_void() + theme(legend.position = "none", plot.margin = margin(0, 0, 0, 0))
layer_file <- file.path(out_dir, "Figure_5A_data_layer.png")
ggsave(layer_file, pa, width = a_w_in / dpi, height = a_h_in / dpi, dpi = dpi,
       device = ragg::agg_png, bg = "transparent")
panel_a <- image_composite(panel_a, image_read(layer_file),
                           offset = paste0("+", int_x[1] - 1, "+", int_y[1] - 1))
unlink(layer_file)

# ---- Assemble ----
tag_b <- image_crop(base, geometry_area(37, 44, 920, 10))          # Ver8's "B" tag letter, same font as "A"

fig <- image_blank(a_w + gap + b_w, fig_h, "white") %>%
  image_composite(panel_a, offset = "+0+0") %>%
  image_composite(image_read(panel_b_file), offset = paste0("+", a_w + gap, "+0")) %>%
  image_composite(tag_b, offset = paste0("+", a_w + gap - 10, "+11"))

image_write(fig, file.path(out_dir, "Figure_5.png"), format = "png", density = dpi)
image_write(fig, file.path(out_dir, "Figure_5.pdf"), format = "pdf", density = dpi)
cat("Wrote", file.path(out_dir, "Figure_5.png"), "\n")
