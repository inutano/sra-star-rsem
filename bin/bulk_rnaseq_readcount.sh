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
VERSION="201708261740"

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
    JOB_CONF=$(resolve_path "${JOB_CONF}")
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
  FTP_TMPDIR="${TMPDIR}/ftp"
  FTP_CACHE_DIR="${FTP_TMPDIR}/cache"
  FTP_DL_DIR="${FTP_TMPDIR}/download"
  mkdir -p "${FTP_CACHE_DIR}" && logging "Set FTP cache directory ${FTP_CACHE_DIR}"
  mkdir -p "${FTP_DL_DIR}" && logging "Set FTP download directory ${FTP_DL_DIR}"

  # Set tmpdir for calculation
  CALC_TMPDIR="${TMPDIR}/calc"
  mkdir -p "${CALC_TMPDIR}" && logging "Set tmpdir for calculation ${CALC_TMPDIR}"
}

validate_inputs() {
  # Data source
  [[ "${DATABASE}" ]] || DATABASE="ddbj"
  logging "Set data download source: ${DATABASE}"

  [[ "${DL_METHOD}" ]] || DL_METHOD="lftp"
  logging "Set download method: ${DL_METHOD}"

  [[ "${NUMBER_OF_PARALLEL_FTP}" ]] || NUMBER_OF_PARALLEL_FTP=8
  logging "Set number of ftp connections: ${NUMBER_OF_PARALLEL_FTP}"

  [[ "${NUMBER_OF_THREADS}" ]] || NUMBER_OF_THREADS=2
  logging "Set number of threads: ${NUMBER_OF_THREADS}"

  [[ "${USE_UGE}" ]] && QUEUE_ENV="qsub" && logging "Use UGE for job scheduling."
  [[ "${USE_SLURM}" ]] && QUEUE_ENV="slurm" && logging "Use slurm for job scheduling."

  WF_SCRIPT="$(resolve_path "${WF_SCRIPT}")"
  [[ -e "${WF_SCRIPT}" ]] \
    && logging "Set calculation workflow script path: ${WF_SCRIPT}" \
    || (logging "ERROR: calculation workflow script not found." && exit 1)

  [[ -e "${EXPERIMENT_ID_LIST}" ]] \
    && EXPS="$(cat ${EXPERIMENT_ID_LIST})" \
    || EXPS="$(echo ${EXPERIMENT_ID_LIST} | tr ',' '\n')"
  logging "Number of experiments to process: $(echo "${EXPS}" | wc -l | tr -d ' ')"


  [[ -e "${RSEM_INDEX_DIR}" ]] \
    && (RSEM_INDEX_DIR="$(resolve_path "${RSEM_INDEX_DIR}")" && logging "Set RSEM index directory: ${RSEM_INDEX_DIR}") \
    || (logging "ERROR: RSEM_INDEX_DIR ${RSEM_INDEX_DIR} not found." && exit 1)

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

ddbj_url() {
  local target_dir_path="${1}"
  local path="ftp://ftp.ddbj.nig.ac.jp/ddbj_database/dra/sralite/ByExp/litesra/${target_dir_path}"
  echo "${path}"
}

ncbi_url() {
  local target_dir_path="${1}"
  local path="ftp://ftp.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByExp/sra/${target_dir_path}"
  echo "${path}"
}

generate_ftp_url() {
  local exp_id=${1}
  local target_dir_path="${exp_id:0:3}/${exp_id:0:6}/${exp_id}"
  case ${DATABASE} in
    ddbj)
      echo $(ddbj_url "${target_dir_path}")
      ;;
    ncbi)
      echo $(ncbi_url "${target_dir_path}")
      ;;
  esac
}

get_filesize() {
  local url="${1}"
  case ${DATABASE} in
    ddbj)
      list_cmd="ls -R"
      ;;
    ncbi)
      list_cmd="ls */*sra"
      ;;
  esac
  lftp -c "open ${url} && ${list_cmd}" | awk '$0 ~ /sra$/ { sum+=$5 }END{ print sum }'
}

disk_availability() {
  # output available volume size in bytes
  echo $(( $(df -Pk "${TMPDIR}" | awk 'NR == 2 { print $4 }') * 1024 ))
}

fetch_data_lftp() {
  local exp_id=${1}

  # Set download cache directory for this experiment
  local cache_dir="${FTP_CACHE_DIR}/${exp_id:0:6}/${exp_id}"
  mkdir -p "${cache_dir}"

  # Set download dest directory for this experiment
  local target_dir="${FTP_DL_DIR}/${exp_id:0:6}/${exp_id}"
  mkdir -p "${target_dir}"

  # Set download log file in cache directory
  local download_log="${target_dir}/${exp_id}.log"

  # Generate ftp download url from experiment id
  local url="$(generate_ftp_url ${exp_id})"
  echo "Downloading data from ${url} ($(date_cmd --rfc-2822))" > "${download_log}"

  # Get file size
  filesize=$(get_filesize "${url}")
  echo "Total file size: ${filesize}" >> "${download_log}"
  fsize_double=$(( ${filesize} * 2 ))

  # Wait until disk is free (at least free space of double file size is required)
  volume=$(disk_availability)
  while [[ ${fsize_double} -gt ${volume} ]]; do
    sleep 60
    volume=$(disk_availability)
    echo "No enough disk space! require double file size (${fsize_double} bytes), only ${volume} bytes available ($(date_cmd --rfc-2822))" >> "${download_log}"
  done

  # Wait a moment before connecting
  sleep 1

  {
    time (
      lftp -c "set net:max-retries 3; set net:timeout 5; mirror --parallel=${NUMBER_OF_PARALLEL_FTP} ${url} ${cache_dir}"
    );
  } 1>&2 2>> "${download_log}"

  # Collect downloaded data to outdir
  chmod -R u+w "${cache_dir}"
  find "${cache_dir}" -name '*sra' | xargs -I{} mv {} "${target_dir}"

  ls -lR "${target_dir}" >> "${download_log}"
  echo "Donwload successfully finished. ($(date_cmd --rfc-2822))" >> "${download_log}"

  # Wait a moment before connecting
  sleep 1
}

fetch_data() {
  local exp_id=${1}
  case ${DL_METHOD} in
    lftp)
      fetch_data_lftp "${exp_id}"
      ;;
  esac
}

init_download() {
  logging "Start downloading data.." 'date_on'

  echo "${EXPS}" | while read exp_id; do
    fetch_data "${exp_id}"
  done

  # Create token and cleaning tmpdir
  touch "${FTP_TMPDIR}/download_finished"
  logging "Download finished." 'date_on'
}

## Calculate downloaded data

init_calculation(){
  logging "Start calculation.." 'date_on'

  while :
  do
    # Find downloaded data, then collect paths to experiment directories
    exp_dirs=$(find "${FTP_DL_DIR}" -name '*sra' | xargs -I{} dirname {} | sort -u)

    # if no data found
    if [[ ! "${exp_dirs}" ]]; then

      # And download_finished token found, break the loop and exit
      if [[ -e "${FTP_TMPDIR}/download_finished" ]]; then
        break
      fi

    # if any downloaded sra file found
    else

      echo "${exp_dirs}" | while read expdir; do
        expid=$(basename "${expdir}")

        # Move downloaded data to tmpdir for calculation
        mv "${expdir}" "${CALC_TMPDIR}"
        tmpd="${CALC_TMPDIR}/${expid}"

        # List items to be processed
        items=$(find "${tmpd}" -name '*sra' | tr '\n' ',' | sed -e 's:,$::')

        # Run calculation workflow
        cmd="${WF_SCRIPT} -j ${JOB_CONF} -f ${items} -x ${expid} --tmpdir ${tmpd} --outdir ${OUTDIR} --delete-input"

        # log file for job scheduling system
        job_logfile="${tmpd}/${expid}.job.log"

        # Select entrypoint
        case ${QUEUE_ENV} in
          qsub)
            exec_cmd="qsub -j y -o ${job_logfile} -N ${expid} -l mem_req=4G,s_vmem=4G -pe def_slot ${NUMBER_OF_THREADS}"

            # wait if too many jobs are in the queue
            job_in_queue=$(qstat | grep $(whoami) | wc -l)
            while [[ ${job_in_queue} -gt 200 ]]; do
              sleep 60
              job_in_queue=$(qstat | grep $(whoami) | wc -l)
            done

            ;;
          slurm)
            exec_cmd="sbatch -n ${NUMBER_OF_THREADS} -o ${job_logfile} -J ${expid}"
            ;;
          *)
            exec_cmd="sh"
            ;;
        esac

        # Record command
        logging "${exec_cmd} ${cmd}" 'date_on'

        # Run
        ${exec_cmd} ${cmd}
      done
    fi

    # Sleep to wait for next items to be downloaded
    sleep 5
  done
}

## Cleaning

clean_dirs() {
  [[ "${LEAVE_TMPDIR}" ]] || rm -fr "${TMPDIR}"
}

## Main

main() {
  # Load configuration file
  load_config

  # Validate settings
  set -e; validate_settings; set +e

  # Init download process and detach
  init_download &
  sleep 3

  # Init calculation process
  init_calculation

  # Cleaning
  clean_dirs
}

#
# Run
#
main
