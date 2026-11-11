#!/bin/bash
# Figure TFBS (draft). Step 2: motif enrichment (MEME Suite SEA) in the promoters of each target
# set against its matched control set, and all-vs-all Tomtom to group similar motifs into families.
# Run from this folder after 01_prepare_promoters_and_sets.R.
set -euo pipefail
module load meme/5.5.9 2>/dev/null || export PATH=/share/apps/meme/5.5.9/bin:$PATH

mkdir -p work/sea
ls work/sets/*.target.fa | sed 's#.*/##; s/\.target\.fa$//' |
  xargs -P 4 -I{} sh -c 'sea --p work/sets/{}.target.fa --n work/sets/{}.control.fa \
      --m work/motifs_combined.meme --thresh 1e6 --seed 1 --text > work/sea/{}.tsv 2> work/sea/{}.log'

tomtom -no-ssc -dist pearson -min-overlap 5 -thresh 0.05 -text \
  work/motifs_combined.meme work/motifs_combined.meme > work/tomtom_all_vs_all.tsv 2> work/tomtom.log

# Site scan used for the figure statistics (02b_site_enrichment.R): FIMO at a fixed p < 1e-4 on every
# promoter, with a 0-order background from the promoters themselves (fasta-get-markov is not installed).
awk '!/^>/{l=toupper($0); a+=gsub(/A/,"",l); c+=gsub(/C/,"",l); g+=gsub(/G/,"",l); t+=gsub(/T/,"",l)}
     END{tot=a+c+g+t; at=(a+t)/2/tot; cg=(c+g)/2/tot; printf "A %.4f\nC %.4f\nG %.4f\nT %.4f\n", at,cg,cg,at}' \
  work/promoters_all.fa > work/promoters_bg0.txt
fimo --text --thresh 1e-4 --bgfile work/promoters_bg0.txt work/motifs_combined.meme work/promoters_all.fa \
  2> work/fimo.log | gzip > work/fimo_promoters_p1e-4.tsv.gz
