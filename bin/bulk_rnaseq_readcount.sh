#!/bin/bash
#
#  bulk_rnaseq_readcount: Download SRA data file and process RNAseq readcount workflow
#
#    usage:
#      ./bulk_rnaseq_readcount.sh [-j|--job-conf] <job configuration file>
#
#    example:
#      ./bulk_rnaseq_readcount.sh -j ./bulk_job_conf.sh
#
VERSION="20170818"

#
# argparse
#

while [[ $# -gt 0 ]]; do
  key=${1}
  case ${key} in
    -j|--job-conf)
      JOB_CONF="${2}"
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
      echo "bulk_rnaseq_readcount version: ${VERSION}" >&2
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
    echo "${m}" >&2
    echo "${m}" >> ${LOGFILE}
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

## Load configuration

load_config() {
  echo "Loading configuration file.." >&2

  # Load job configuration
  if [[ -e "${JOB_CONF}" ]]; then
    source "${JOB_CONF}"
  else
    echo "ERROR: Job configuration file ${JOB_CONF} not found." >&2
    exit 1
  fi
}

## Validation

validate_dirs() {
  # Overwrite arguments
  [[ "${TMPDIR_ARG}" ]] && TMPDIR="${TMPDIR_ARG}"
  [[ "${OUTDIR_ARG}" ]] && OUTDIR="${OUTDIR_ARG}"

  # Default tmp/outdir
  [[ "${TMPDIR}" ]] || TMPDIR="${HOME}/data/readcount"
  [[ "${OUTDIR}" ]] || OUTDIR="${HOME}/data/readcount"

  # Create tmp/output directory if not exist
  [[ -e "${OUTDIR}" ]] || mkdir -p "${OUTDIR}"
  [[ -e "${TMPDIR}" ]] || mkdir -p "${TMPDIR}"

  # Resolve absolute path to tmp/outdir and create them
  TMPDIR="$(resolve_path "${TMPDIR}")/bulk-$(date_cmd +%Y%m%d-%H%M)/tmp"
  OUTDIR="$(resolve_path "${OUTDIR}")/bulk-$(date_cmd +%Y%m%d-%H%M)"

  # Create outdir first to start logging
  mkdir -p "${OUTDIR}"

  # Create log file in the output directory
  LOGFILE="${OUTDIR}/bulk_wf_readcount.log"
  touch "${LOGFILE}" \
    && logging "Bulk RNA-seq readcount workflow: version ${VERSION}" \
    && logging "Created log file at ${LOGFILE}" \
    || (echo "ERROR: failed to create log file at ${LOGFILE}" && exit 1)

  # Set tmp/outdir
  logging "Set output directory ${OUTDIR}"
  mkdir -p "${TMPDIR}" && logging "Set temporary directory ${TMPDIR}"

  # Set FTP download dirs
  FTP_CACHE_DIR="${TMPDIR}/ftp/cache"
  FTP_DL_DIR="${TMPDIR}/ftp/download"
  mkdir -p "${FTP_CACHE_DIR}" && logging "Set FTP cache directory ${FTP_CACHE_DIR}"
  mkdir -p "${FTP_DL_DIR}" && logging "Set FTP download directory ${FTP_DL_DIR}"
}

validate_inputs() {
  [[ "${NUMBER_OF_PARALLEL_FTP}" ]] || NUMBER_OF_PARALLEL_FTP=8
  logging "Set number of ftp connections: ${NUMBER_OF_PARALLEL_FTP}"

  [[ "${NUMBER_OF_THREADS}" ]] || NUMBER_OF_THREADS=2
  logging "Set number of threads: ${NUMBER_OF_THREADS}"

  [[ -e "${EXPERIMENT_ID_LIST}" ]] \
    && EXPS="$(cat ${EXPERIMENT_ID_LIST})" \
    || EXPS="$(echo ${EXPERIMENT_ID_LIST} | tr ',' '\n')"
  logging "Number of experiments to process: $(echo "${EXPS}" | wc -l | tr -d ' ')"

  [[ -e "${RSEM_INDEX_DIR}" ]] \
    && logging "Set RSEM index directory: ${RSEM_INDEX_DIR}" \
    || (logging "ERROR: RSEM_INDEX_DIR not found." && exit 1)

  [[ "${RSEM_INDEX_PREFIX}" ]] \
    && logging "Set RSEM index prefix: ${RSEM_INDEX_PREFIX}" \
    || (logging "ERROR: RSEM_INDEX_PREFIX not defined." && exit 1)
}

validate_settings() {
  # validate dirs first to start logging
  validate_dirs
  validate_inputs
}

## Download data from SRA

download_data() {
  local id="${1}"
  sleep 1
  echo "${id} downloaded."
}

init_download() {
  logging "Start downloading data.." 'date_on'

  echo "${EXPS}" | while read exp_id; do
    download_data "${exp_id}"
  done

  logging "Download finished." 'date_on'
}

## Calculate downloaded data

init_calculation(){
  echo ""
}

## Watch download and calculate processes

init_watch(){
  echo ""
}

## main

main() {
  # Load configuration file
  load_config

  # Validate settings
  validate_settings

  # Init download process
  init_download
  sleep 3

  # Init calculation process
  init_calculation

  # Init watch process
  init_watch
}

#
# Run
#
main
