#!/bin/bash
#
#  rnaseq_readcount.sh
#    usage:
#      ./rnaseq_readcount.sh [-j|--job-conf] <job configuration file> [-f|--sra-file] <input sra file>[,<input sra file>,..] [-x|--experiment-id] <Experiment ID>
#
#    example:
#      ./rnaseq_readcount.sh -j job_conf.sh -f SRR1274307.sra,SRR1274306.sra -x SRX534534
#
set -e
VERSION="201709011650"

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
    -f|--sra-file)
      INPUT_FILES="${2}"
      shift
      ;;
    -x|--experiment-id)
      EXPERIMENT_ID="${2}"
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
    --delete-input)
      DELETE_INPUT="true"
      ;;
    -v|--version)
      echo "rnaseq_readcount version: ${VERSION}" >&2
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

load_args() {
  echo "Loading configuration file.." >&2

  # Load job configuration
  if [[ "${JOB_CONF}" ]]; then
    source "${JOB_CONF}"
  else
    echo "ERROR: Job configuration file not found." >&2
    exit 1
  fi
}

validate_arguments() {
  # Check required arguments
  if [[ ! "${INPUT_FILES}" ]]; then
    echo "ERROR: No input files found." >&2
    exit 1
  fi

  if [[ ! "${EXPERIMENT_ID}" ]]; then
    echo "ERROR: Experiment ID not specified." >&2
    exit 1
  fi

  # Resolve absolute path to input files
  FILES="$(resolve_path "$(echo ${INPUT_FILES} | sed -e 's:,: :g')")"
}

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
  TMPDIR="$(resolve_path "${TMPDIR}")/${EXPERIMENT_ID:0:6}/${EXPERIMENT_ID}/$(date_cmd +%Y%m%d-%H%M)/tmp"
  OUTDIR="$(resolve_path "${OUTDIR}")/${EXPERIMENT_ID:0:6}/${EXPERIMENT_ID}/$(date_cmd +%Y%m%d-%H%M)"

  # Create outdir first to start logging
  mkdir -p "${OUTDIR}"

  # Create log file in the output directory
  LOGFILE="${OUTDIR}/${EXPERIMENT_ID}.wf_readcount.log"
  touch "${LOGFILE}" \
    && logging "Created log file at ${LOGFILE}" \
    || (echo "ERROR: failed to create log file at ${LOGFILE}" && exit 1)

  # Set tmp/outdir
  logging "Set output directory ${OUTDIR}"
  mkdir -p "${TMPDIR}" && logging "Set temporary directory ${TMPDIR}"
}

validate_inputs() {
  [[ -e "${RSEM_INDEX_DIR}" ]] \
    && logging "Set RSEM index directory: ${RSEM_INDEX_DIR}" \
    || (logging "ERROR: RSEM_INDEX_DIR not found." && exit 1)

  [[ "${RSEM_INDEX_PREFIX}" ]] \
    && logging "Set RSEM index prefix: ${RSEM_INDEX_PREFIX}" \
    || (logging "ERROR: RSEM_INDEX_PREFIX not defined." && exit 1)

  [[ "${NUMBER_OF_THREADS}" ]] || NUMBER_OF_THREADS=2
  logging "Set number of threads: ${NUMBER_OF_THREADS}"
}

validate_setting() {
  validate_arguments
  validate_dirs
  validate_inputs
}

check_binary(){
  logging ""
  local cmd=${1}
  local stepname=${2}
  local cmd_path=$(which ${cmd} 2>/dev/null)

  if [[ -e "${cmd_path}" ]]; then
    logging "[step ${stepname}] Executable ${cmd} found at ${cmd_path}, version: $(${cmd} --version 2>&1 | head -1)"
  else
    logging "ERROR: command not found: ${cmd}"
    exit 1
  fi
}

run_step(){
  local stepname="${1}"
  local base_command="${2}"
  local args="${3}"

  # Check
  check_binary "${base_command}" "${stepname}"

  # Build command
  logging "[step ${stepname}] command: ${base_command} ${args}"
  logging ""

  # Run
  logging "[step ${stepname}] start." 'date_on'
  cd "${TMPDIR}" && ${base_command} ${args} &

  # Wait until the job finished
  local failure=0
  for job in $(jobs -p); do
    wait ${job} || let "failure+=1"
  done

  if [[ "${failure}" != "0" ]]; then
    logging "[step ${stepname}] failure"
    find "${TMPDIR}" -name '*log' | xargs -I{} mv {} "${OUTDIR}"
    clean_directories
    exit 1
  else
    logging "[step ${stepname}] completed success"
  fi

  # Finish
  logging "[step ${stepname}] finished." 'date_on'
}

run_pfastq_dump() {
  local input_files="${1}"
  local stepname="pfastq-dump"
  local base_command="pfastq-dump"
  local args="--split-spot --stdout --readids -t ${NUMBER_OF_THREADS} ${input_files}"
  local output="${TMPDIR}/${EXPERIMENT_ID}.fastq"

  # Run pfastq-dump and redirect output to file
  run_step "${stepname}" "${base_command}" "${args}" > "${output}"

  # Return path to output fastq file
  echo "${output}"
}

run_rsem_index() {
  echo ""
}

run_rsem() {
  local input_fastq="${1}"
  local stepname="rsem-calculate"
  local base_command="rsem-calculate-expression"
  local args="--star --keep-intermediate-files --no-bam-output -p ${NUMBER_OF_THREADS} ${input_fastq} ${RSEM_INDEX_DIR}/${RSEM_INDEX_PREFIX} ${EXPERIMENT_ID}"

  # Run rsem-calculate-expression
  run_step "${stepname}" "${base_command}" "${args}"

  # Collect result files
  mv "${TMPDIR}/${EXPERIMENT_ID}.genes.results" "${OUTDIR}"
  mv "${TMPDIR}/${EXPERIMENT_ID}.isoforms.results" "${OUTDIR}"
  mv "${TMPDIR}/${EXPERIMENT_ID}.temp/${EXPERIMENT_ID}ReadsPerGene.out.tab" "${OUTDIR}/${EXPERIMENT_ID}.ReadsPerGene.out.tab"
  mv "${TMPDIR}/${EXPERIMENT_ID}.temp/${EXPERIMENT_ID}Log.final.out" "${OUTDIR}/${EXPERIMENT_ID}.STAR.Log.final.out"
  mv "${TMPDIR}/${EXPERIMENT_ID}.temp/${EXPERIMENT_ID}Log.out" "${OUTDIR}/${EXPERIMENT_ID}.STAR.Log.out"
}

clean_directories() {
  chmod -R a+w "${TMPDIR}"
  rm -fr "${TMPDIR}"
  logging "Result files are stored in ${OUTDIR}"
  logging "$(ls -l ${OUTDIR})"

  if [[ "${DELETE_INPUT}" == 'true' ]]; then
    chmod -R a+w ${FILES}
    rm -fr ${FILES}
  fi
}

wf_rnaseq_readcount() {
  logging "Starting workflow for ${EXPERIMENT_ID} at $(hostname).." 'date_on'

  # Run pfastq-dump and get a path to fastq file
  step1_out=`run_pfastq_dump "$(echo "${FILES}" | tr '\n' ' ')"`

  # Run RSEM
  run_rsem "${step1_out}"

  # Remove tmpdir
  clean_directories

  logging "Finished workflow for ${EXPERIMENT_ID}." 'date_on'
}

main() {
  # Load configuration file
  load_args

  # Validate settings
  validate_setting

  # Run workflow
  wf_rnaseq_readcount
}

#
# run
#
main
