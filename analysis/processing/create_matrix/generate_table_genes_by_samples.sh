#!/bin/bash
find $1 -name '*Reads*' |\
 xargs paste |\
 awk '{ printf $1; for(i=1;i<=NF;i++){ if(i%4==2){ printf "\t" $i } }; printf "\n" }' |\
 split -l $(find . -name '*Reads*' | head -1 | xargs wc -l | cut -d ' ' -f 1) - out.

cat <(echo -e "filename" $(find . -name '*Reads*' | xargs -I{} basename {} | sed -e 's:.ReadsPerGene.out.tab::g') | tr ' ' '\t') <(paste out.* | awk 'NR>4') |\
 awk 'NR == 1 { print $0 } NR > 2 { for(i=2;i<=NF;i++){ a[i] += $i }; print $0 }END{ printf "TotalMappedReads"; for( i in a ){ printf "\t" a[i] }; printf "\n"  }'

rm -f ./out.*
