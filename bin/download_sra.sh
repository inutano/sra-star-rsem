#!/bin/bash
#
#  download_sra.sh
#    usage:
#      ./download_sra.sh [-db|--database] <database name> [-x|--experiment-id] <Experiment ID>
#    example:
#      ./download_sra.sh -db ddbj -x SRX534534
set -e
VERSION="201708092200"

#
# argparse
#

while [[ $# -gt 0 ]]; do
  key=${1}
  case ${key} in
    -x|--experiment-id)
      EXPERIMENT_ID="${2}"
      shift
      ;;
    -db|--database)
      DATABASE="${2}"
      shift
      ;;
    --tmpdir)
      TMPDIR_ARG="${2}"
      shift
      ;;
    --outdir)
      OUTDIR_ARG="${2}"
      shift
      ;;
    -v|--version)
      echo "download_sra version: ${VERSION}" >&2
      exit 0
      ;;
    -q|--quiet)
      QUIET_OPTION="true"
      ;;
  esac
  shift
done

#
# Utility functions
#

# Date command switch for Mac/Linux
date_cmd() {
  local arg="${1}"
  if [[ "$(uname)" == 'Darwin' ]]; then
    gdate ${arg}
  elif [[ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]]; then
    date ${arg}
  else
    echo "Your platform ($(uname -a)) is not supported." 2>dev/null
    exit 1
  fi
}

# Write message to stdout and $LOGFILE
logging() {
  local m="${1}"
  local date_option="${2}"
  if [[ ${date_option} == 'date_on' ]]; then
    local m="${m} ($(date_cmd --rfc-2822))"
  fi
  if [[ -z "${QUIET_OPTION}" ]]; then
    echo "${m}" >&2 | tee -a "${LOGFILE}"
  else
    echo "${m}" >> "${LOGFILE}"
  fi
}

# resolve file paths from relative path
resolve_path(){
  local files=${1}
  local path=""
  for f in ${files}; do
    echo "$(cd $(dirname ${f}) && pwd -P)/$(basename ${f})"
  done
}

#
# Functions
#

validate_arguments() {
  # Check target experiment ID
  if [[ ! "${EXPERIMENT_ID}" ]]; then
    echo "ERROR: Experiment ID not specified." >&2
    exit 1
  fi

  # Default setting
  [[ "${DATABASE}" ]] || DATABASE="ncbi"
  [[ "${DL_PROTOCOL}" ]] || DL_PROTOCOL="lftp"

}

validate_dirs() {
  # Overwrite arguments
  [[ "${TMPDIR_ARG}" ]] && TMPDIR="${TMPDIR_ARG}"
  [[ "${OUTDIR_ARG}" ]] && OUTDIR="${OUTDIR_ARG}"

  # Default tmp/outdir
  [[ "${TMPDIR}" ]] || TMPDIR="${HOME}/data/download_sra"
  [[ "${OUTDIR}" ]] || OUTDIR="${HOME}/data/download_sra"

  # Create tmp/output directory if not exist
  [[ -e "${OUTDIR}" ]] || mkdir -p "${OUTDIR}"
  [[ -e "${TMPDIR}" ]] || mkdir -p "${TMPDIR}"

  # Resolve absolute path to tmp/outdir and create them
  TMPDIR="$(resolve_path "${TMPDIR}")/${EXPERIMENT_ID:0:6}/${EXPERIMENT_ID}/$(date_cmd +%Y%m%d-%H%M)/tmp"
  OUTDIR="$(resolve_path "${OUTDIR}")/${EXPERIMENT_ID:0:6}/${EXPERIMENT_ID}/$(date_cmd +%Y%m%d-%H%M)"

  # Create outdir first to start logging
  mkdir -p "${OUTDIR}"

  # Create log file in the output directory
  LOGFILE="${OUTDIR}/${EXPERIMENT_ID}.download_sra.log"
  touch "${LOGFILE}" \
    && logging "Created log file at ${LOGFILE}" \
    || (echo "ERROR: failed to create log file at ${LOGFILE}" && exit 1)

  # Set tmp/outdir
  logging "Set output directory ${OUTDIR}"
  mkdir -p "${TMPDIR}" && logging "Set temporary directory ${TMPDIR}"
}

validate_setting() {
  validate_arguments
  validate_dirs
}

ddbj_url() {
  local target_dir_path="${1}"
  local path="ftp://ftp.ddbj.nig.ac.jp/ddbj_database/dra/sralite/ByExp/litesra/${target_dir_path}"
  logging "Download from DDBJ - ${path}"
  echo "${path}"
}

ncbi_url() {
  local target_dir_path="${1}"
  local path="ftp://ftp.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByExp/sra/${target_dir_path}"
  logging "Download from NCBI - ${path}"
  echo "${path}"
}

generate_ftp_url() {
  local target_dir_path="${EXPERIMENT_ID:0:3}/${EXPERIMENT_ID:0:6}/${EXPERIMENT_ID}"
  case ${DATABASE} in
    ddbj)
      echo $(ddbj_url "${target_dir_path}")
      ;;
    ncbi)
      echo $(ncbi_url "${target_dir_path}")
      ;;
  esac
}

fetch_data_lftp() {
  local url="${1}"
  logging "Downloading data.." 'date_on'
  logging $(time (lftp -c "set net:max-retries 2; set net:timeout 5; mirror --parallel=4 ${url} ${TMPDIR}"))

  # Collect downloaded data to outdir
  chmod -R u+w "${TMPDIR}"
  find "${TMPDIR}" -name '*sra' | xargs -I{} mv {} "${OUTDIR}"
}

fetch_data() {
  local url="$(generate_ftp_url)"
  case ${DL_PROTOCOL} in
    lftp)
      fetch_data_lftp "${url}"
      ;;
  esac
}

clean_directories() {
  chmod -R u+w "${TMPDIR}"
  rm -fr "${TMPDIR}"
  logging "Data downloaded in ${OUTDIR}" 'date_on'
  logging "$(ls -l ${OUTDIR})"
}

main() {
  # Prepare directories
  validate_setting

  # Download
  fetch_data

  # Remove tmpdir
  clean_directories
}

#
# Run
#
main
