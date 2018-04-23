#!/bin/bash
#  requirement:
#    expected to be executed on the same dir that the create_datalist.sh run
#  usage:
#   ./move_n_compress.sh <target dir>
#set -e
set -u

# Target dir from cmd argument
dest_dir="${1}"
result_dir="${dest_dir}/readcount_results"
log_dir="${result_dir}/log"
mkdir -p "${result_dir}"
mkdir -p "${log_dir}"

# Locate tmp file
tdir="./tmp/readcount_datalist"

if [[ ! -e "${tdir}" ]]; then
  echo "==> ERROR: ./tmp/readcount_datalist not found."
  exit 1
fi

# Create dest dir and move files
cat "${tdir}/dirsToMove.txt" | while read dir
do
  filesToMove="$(find "${dir}" -name '*ReadsPerGene.out.tab') $(find "${dir}" -name '*.out') $(find "${dir}" -name '*results')"
  expid=$(dirname "${dir}" | xargs -I{} basename {})

  numFiles=$(echo ${filesToMove} | tr '\n' ' ' | awk '{ print NF }')
  if [[ ${numFiles} == 5 ]]; then
    if [[ ! -z $(find ${dir} -name '*Log.out' | xargs -I{} grep "Homo_sapiens" {} 2>/dev/null) ]]; then
      sp="human"
    else
      sp="mouse"
    fi
    dest="${result_dir}/${sp}/$(echo "${expid}" | sed -e 's:...$::')/${expid}"; mkdir -p "${dest}"
    echo -e "${expid}\t${dir}\t${dest}" >> "${log_dir}/movedDirs.tab"
    cp -t "${dest}" ${filesToMove}
  else
    echo -e "${expid}\t${dir}" >> "${log_dir}/errorDirs.tab"
  fi
done

# Compress
cd "${dest_dir}"
tar zcf "readcount_results.tgz" "readcount_results"