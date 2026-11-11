# Figure TFBS (draft). Step 1: promoter sequences, target/control gene sets and the motif file.
# Run from this folder: Rscript 01_prepare_promoters_and_sets.R
# Writes work/promoters_all.fa, work/sets/<set>.{target,control}.fa, work/set_summary.csv,
# work/motifs_combined.meme and work/motif_annotation.csv.

suppressPackageStartupMessages({
  library(tidyverse); library(data.table); library(Biostrings); library(GenomicRanges)
})

ref_dir   <- "../../ref/C_albicans_A22_r228"
fasta     <- file.path(ref_dir, "C_albicans_SC5314_version_A22-s07-m01-r228_chromosomes.fasta")
gene_info <- file.path(ref_dir, "C_albicans_SC5314_A22_r228_gene_info.tsv")
de_wt     <- "../Figure_4/data/DESeq2_time_vs_2h.csv.gz"
de_ko     <- "../Figure_6/data/rnaseq_interaction/Q3_interaction_KO_vs_BG_all_genes.csv"

prom_max <- 1000   # bp upstream of the start codon
prom_min <- 100    # promoters shorter than this after truncation are dropped
padj_cut <- 0.05; lfc_cut <- 1

dir.create("work/sets", recursive = TRUE, showWarnings = FALSE)

# ---- Promoters (haplotype A) --------------------------------------------------------------
gi <- fread(gene_info) %>% as_tibble()
genes_A <- gi %>% filter(grepl("_A$", allele_id), grepl("chr[0-9R]A_", chr))
# All annotated features on haplotype A (any biotype) bound the upstream region.
feat <- GRanges(genes_A$chr, IRanges(genes_A$start, genes_A$end), strand = genes_A$strand)
cds  <- genes_A %>% filter(biotype == "mRNA")

genome <- readDNAStringSet(fasta)
names(genome) <- sub(" .*", "", names(genome))

up <- with(cds, GRanges(chr, IRanges(ifelse(strand == "+", pmax(1, start - prom_max), end + 1),
                                     ifelse(strand == "+", start - 1, end + prom_max)),
                        strand = strand, gene_id = gene_id))
up <- up[width(up) > 0]
# Truncate at the nearest neighbouring feature (either strand), so a promoter never runs into
# the coding sequence of the upstream gene.
ov <- findOverlaps(up, feat, ignore.strand = TRUE)
if (length(ov)) {
  hits <- tibble(q = queryHits(ov), fs = start(feat)[subjectHits(ov)], fe = end(feat)[subjectHits(ov)])
  plus  <- as.character(strand(up)) == "+"
  new_s <- hits %>% filter(plus[q]) %>% group_by(q) %>% summarise(v = max(fe) + 1)
  new_e <- hits %>% filter(!plus[q]) %>% group_by(q) %>% summarise(v = min(fs) - 1)
  start(up)[new_s$q] <- pmin(new_s$v, end(up)[new_s$q] + 1)
  end(up)[new_e$q]   <- pmax(new_e$v, start(up)[new_e$q] - 1)
}
end(up) <- pmin(end(up), width(genome)[match(as.character(seqnames(up)), names(genome))])
up <- up[width(up) >= prom_min]
prom <- subseq(genome[as.character(seqnames(up))], start(up), end(up))
minus <- as.character(strand(up)) == "-"
prom[minus] <- reverseComplement(prom[minus])   # promoters are written 5'->3' toward the ATG
names(prom) <- up$gene_id
prom <- prom[!duplicated(names(prom))]
writeXStringSet(prom, "work/promoters_all.fa")
cat(sprintf("Promoters: %d (median %d bp; %d at full %d bp)\n", length(prom), median(width(prom)),
            sum(width(prom) == prom_max), prom_max))

# ---- Map expression-table IDs to gene_id ----------------------------------------------------
name2id <- gi %>% filter(gene_name != "") %>% distinct(gene_name, gene_id)
to_gene_id <- function(x) {
  out <- ifelse(grepl("^CAALFM_C[1-7R][0-9]{5}[WC]A$", x),
                sub("^CAALFM_C([1-7R])([0-9]{5}[WC])A$", "C\\1_\\2", x), NA_character_)
  hit <- is.na(out)
  out[hit] <- name2id$gene_id[match(x[hit], name2id$gene_name)]
  out[is.na(out)] <- x[is.na(out)]
  out
}

# ---- Gene sets -------------------------------------------------------------------------------
# Targets are genes with higher (up) or lower (down) transcript abundance. The control for each
# target set is the promoters of genes tested in the same contrast that did not change
# (padj >= 0.05 or |log2FC| < 1), so promoter composition is matched to expressed genes.
wt <- fread(de_wt) %>% as_tibble() %>%
  mutate(gene_id = to_gene_id(gene), set_group = "WT time course",
         contrast = paste0(medium, "_", time, "h_vs_2h"))
ko <- fread(de_ko) %>% as_tibble() %>%
  mutate(set_group = "TF KO interaction",
         contrast = recode(contrast, "NRG x time (vs BG)" = "nrg1", "NDT x time (vs BG)" = "ndt80",
                           "STP x time (vs BG)" = "stp4")) %>%
  filter(!selection_marker)
cat(sprintf("WT IDs mapped to a promoter: %.1f%%\n", 100 * mean(unique(wt$gene_id) %in% names(prom))))

de <- bind_rows(wt %>% select(set_group, contrast, gene_id, log2FC, padj),
                ko %>% select(set_group, contrast, gene_id, log2FC, padj)) %>%
  filter(gene_id %in% names(prom)) %>%
  mutate(class = case_when(!is.na(padj) & padj < padj_cut & log2FC >=  lfc_cut ~ "up",
                           !is.na(padj) & padj < padj_cut & log2FC <= -lfc_cut ~ "down",
                           TRUE ~ "unchanged"))

summ <- de %>% group_by(set_group, contrast) %>%
  group_modify(function(d, k) {
    ctrl <- unique(d$gene_id[d$class == "unchanged"])
    map_dfr(c("up", "down"), function(dir) {
      tgt <- unique(d$gene_id[d$class == dir])
      set <- paste0(k$contrast, "__", dir)
      writeXStringSet(prom[tgt],  file.path("work/sets", paste0(set, ".target.fa")))
      writeXStringSet(prom[ctrl], file.path("work/sets", paste0(set, ".control.fa")))
      tibble(direction = dir, set = set, n_target = length(tgt), n_control = length(ctrl))
    })
  }) %>% ungroup()
write_csv(summ, "work/set_summary.csv")
write_csv(de, "work/gene_classes.csv.gz")
print(summ, n = Inf)

# ---- Motif file ------------------------------------------------------------------------------
# JASPAR 2022 CORE fungi (non-redundant) plus the C. albicans motifs in CIS-BP that were measured
# for the C. albicans protein itself (no "(species)_(DBD)" inference tag).
read_meme <- function(f) {
  l <- readLines(f); s <- grep("^MOTIF", l)
  list(header = l[seq_len(s[1] - 1)],
       blocks = map2(s, c(s[-1] - 1, length(l)), ~ l[.x:.y]))
}
j  <- read_meme("data/motifs/JASPAR2022_CORE_fungi_non-redundant_v2.meme")
c2 <- read_meme("data/motifs/CIS-BP_2.00_Candida_albicans.meme")
c1 <- read_meme("data/motifs/CIS-BP_1.02_Candida_albicans.meme")
direct <- function(m) keep(m$blocks, ~ !grepl("\\(", .x[1]))
c1_direct <- keep(direct(c1), ~ grepl("GRF10", .x[1]))   # the 1.02 PBM motifs not repeated in 2.00
blocks <- c(j$blocks, direct(c2), c1_direct)
writeLines(c(j$header, unlist(blocks)), "work/motifs_combined.meme")

# Motif -> TF, with the C. albicans ortholog (CGOB) of each S. cerevisiae TF.
orth <- fread("data/CGOB_C_albicans_S_cerevisiae_orthologs.tsv", header = FALSE,
              col.names = c("ca_allele", "ca_name", "ca_cgdid", "sc_orf", "sc_name", "sc_sgdid")) %>%
  as_tibble() %>% mutate(ca_gene_id = sub("_A$", "", ca_allele),
                         ca_label = ifelse(ca_name == "", ca_gene_id, ca_name))
ann <- map_dfr(blocks, function(b) {
  f <- strsplit(sub("^MOTIF ", "", b[1]), " ")[[1]]
  tibble(motif_id = f[1], motif_alt = f[2])
}) %>%
  mutate(source = ifelse(grepl("^MA", motif_id), "JASPAR2022 (S. cerevisiae TF)",
                         "CIS-BP (C. albicans TF, measured)"),
         sc_tf = ifelse(grepl("^MA", motif_id), toupper(motif_alt), NA_character_),
         orf19 = ifelse(grepl("^CaO19", motif_alt), sub("CaO19", "orf19", motif_alt), NA_character_))
sc_to_ca <- orth %>% group_by(sc_name) %>%
  summarise(ca_ortholog = paste(unique(ca_label), collapse = "/"),
            ca_gene_ids = paste(unique(ca_gene_id), collapse = ";"))
orf19_to_ca <- gi %>% filter(grepl("_A$", allele_id)) %>%
  transmute(orf19, ca_label_orf = ifelse(gene_name == "", gene_id, gene_name), gene_id_orf = gene_id)
ann <- ann %>% left_join(sc_to_ca, by = c(sc_tf = "sc_name")) %>%
  left_join(orf19_to_ca, by = "orf19") %>%
  mutate(ca_ortholog = coalesce(ca_ortholog, ca_label_orf,
                                ifelse(motif_alt == "GRF10", "GRF10", NA_character_)),
         ca_gene_ids = coalesce(ca_gene_ids, gene_id_orf),
         label = case_when(source != "JASPAR2022 (S. cerevisiae TF)" ~ ca_ortholog,
                           is.na(ca_ortholog) ~ paste0(motif_alt, " (Sc; no Ca ortholog)"),
                           toupper(ca_ortholog) == sc_tf ~ ca_ortholog,
                           TRUE ~ paste0(ca_ortholog, " (Sc ", motif_alt, ")"))) %>%
  select(motif_id, motif_alt, source, sc_tf, ca_ortholog, ca_gene_ids, label)
write_csv(ann, "work/motif_annotation.csv")
cat(sprintf("Motifs: %d (%d with a C. albicans TF)\n", nrow(ann), sum(!is.na(ann$ca_ortholog))))
