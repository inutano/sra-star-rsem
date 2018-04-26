#!/bin/bash
# bash generate_table_genes_by_samples.sh <top dir on read count data>

workdir="${1}"
result="${workdir}/$(basename ${workdir}).genes_by_samples.tsv"

cd "${workdir}"

# Create separated list of files to avoid open files limit
find "${workdir}" -name '*ReadsPerGene.out.tab' | split -l $(($(ulimit -n)-10)) -d - lists

# Paste files for each list
for list in lists*; do
  paste $(cat ${list}) | \
  awk '{ printf $1; for(i=1;i<=NF;i++){ if(i%4==2){ printf "\t" $i } }; printf "\n" }' \
  > "merged${list##lists}"
done

# Check the numbre of merged files
if [[ $(ls merged* | wc -l) -gt $(ulimit -n) ]]; then
  echo "Too many files or something went wrong. exit"
  exit 1
fi

# Header line by combining file names
header=$(echo -e "filename" $(echo ${files} | xargs -I{} basename {} | sed -e 's:.ReadsPerGene.out.tab::g') | tr ' ' '\t')

# Concatenate header and contents, with calculating total mapped reads
cat <(echo ${header}) <(paste merged* | awk 'NR>4') |\
 awk 'NR == 1 { print $0 } NR > 2 { for(i=2;i<=NF;i++){ a[i] += $i }; print $0 }END{ printf "TotalMappedReads"; for( i in a ){ printf "\t" a[i] }; printf "\n"  }' \
 > "${result}"

echo "File saved at ${result}."
