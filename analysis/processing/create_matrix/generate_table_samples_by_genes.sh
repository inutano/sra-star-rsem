#!/bin/bash

cat <(
  find . -name '*Reads*' | \
  head -1 |\
  xargs cat |\
  awk 'BEGIN{ printf "gene_symbol" } NR>4 { printf "\t" $1 }END{ printf "\t" TotalMappedReads "\n" }'
) \
    <(
  find . -name '*Reads*' | \
  while read f; do
    expid=$(basename $f | sed -e 's:.ReadsPerGene.out.tab$::g');
    cat $f |\
      awk -v expid=$expid 'BEGIN{ printf expid } NR > 4 { sum += $2; printf "\t" $2 }END{ printf "\t" sum "\n" }';
  done
)
