#!/bin/bash
#  usage
#   ./create_datalist.sh /path/to/data/dirs
#set -e
set -u

# Set variables
result_data_dir=$1

# Create tmp dir
tdir="./tmp/readcount_datalist"
if [[ ! -e "${tdir}" ]]; then
  echo "==> use existing tmp directory."
else
  mkdir -p ${tdir}
fi

# Find all the readcount files
#find ${result_data_dir} -name '*ReadsPerGene.out.tab' > ${tdir}/all_RPGpath.txt 2>/dev/null

# Experiment ID - ReadsPerGene
cat ${tdir}/all_RPGpath.txt | \
  awk -F'/' '{ print $NF "@\t" $0 }' | \
  sed -e 's:.ReadsPerGene.out.tab@::g' \
  > ${tdir}/all_expid_RPGpath.tab

# Count number of experimernt IDs occurrence
cat ${tdir}/all_expid_RPGpath.tab | cut -f 1 | sort | uniq -c > ${tdir}/all_count_expid.txt

#
# Non-duplicated items
#

# Non-duplicated experiment IDs - record to list of passengers
cat ${tdir}/all_count_expid.txt | awk '$1 == 1 { print $2 }' | while read expid
  do cat ${tdir}/all_expid_RPGpath.tab | \
    awk -v expid=${expid} -F'\t' '$1 == expid { print $2; exit }'
  done | \
  xargs -I{} dirname {} \
  > ${tdir}/dirsToMove.txt

#
# Duplicated items
#

# Duplicated experiment ID
cat ${tdir}/all_count_expid.txt | awk '$1 != 1 { print $2 }' > ${tdir}/all_duplicatedExpid.txt

# Readcount files of duplicated IDs
cat ${tdir}/all_duplicatedExpid.txt | while read expid
  do cat ${tdir}/all_expid_RPGpath.tab | \
    awk -v expid=${expid} -F "\t" '$1 == expid { print $0; exit }'
  done > ${tdir}/all_duplicatedExpid_RPGpath.tab

# md5sum for duplicated RPG files
cat ${tdir}/all_duplicatedExpid_RPGpath.tab | \
  cut -f 2 | \
  xargs -I{} md5sum {} \
  > ${tdir}/all_md5_RPGpath.txt

# Count number of md5sum occurrence
cat ${tdir}/all_md5_RPGpath.txt | cut -f 1 -d ' ' | sort | uniq -c > ${tdir}/all_count_md5.txt

# single/odd number md5sum means unmatched pairs of files with a single ID, removed from the final list
cat ${tdir}/all_count_md5.txt | awk '$1 % 2 == 1 { print $2 }' | while read md5
  do cat ${tdir}/all_md5_RPGpath.txt | awk -v md5=${md5} '$1 == md5 { print $2; exit }'
  done > ${tdir}/all_md5unmatched_RPGpath.txt

# double/even number md5sum means files processed mutilple times, removed with leaving one
cat ${tdir}/all_count_md5.txt | awk '$1 % 2 == 0 { print $2 }' | while read md5
  do cat ${tdir}/all_md5_RPGpath.txt | awk -v md5=${md5} '$1 == md5 { print $2; exit }' | \
    xargs ls -t | head -1
  done > ${tdir}/all_md5matched_representative_RPGpath.txt

cat ${tdir}/all_md5matched_representative_RPGpath.txt | \
  xargs -I{} dirname {} \
  >> ${tdir}/dirsToMove.txt