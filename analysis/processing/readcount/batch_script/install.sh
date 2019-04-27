#!/bin/bash
set -e

#
# Variable
#
PROJECT_DIR="${HOME}/.readcount"
REPOS_DIR="${PROJECT_DIR}/repos"
BIN_DIR="${PROJECT_DIR}/bin"

#
# Functions
#
setup(){
  mkdir -p "${REPOS_DIR}"
  mkdir -p "${BIN_DIR}"
  export PATH="${BIN_DIR}:${PATH}"
}

check_cmd(){
  local cmd=$1
  if [[ -z $(which ${cmd} 2>/dev/null ||:) ]]; then
    echo "Failed: ${cmd} not found"
    exit 1
  fi
}

check_prerequisites(){
  check_cmd "git"
  check_cmd "lftp"
  check_cmd "fastq-dump"
  check_cmd "sra-stat"
  check_cmd "make"
}

install_pfastq_dump() {
  local cmd="${BIN_DIR}/pfastq-dump"
  if [[ ! -e "${cmd}" ]]; then
    cd ${REPOS_DIR}
    git clone "https://github.com/inutano/pfastq-dump"
    ln -s "${REPOS_DIR}/pfastq-dump/bin/pfastq-dump" "${cmd}"
    chmod +x "${cmd}"
    "${cmd}" "--version"
  fi
}

install_star() {
  local cmd="${BIN_DIR}/STAR"
  if [[ ! -e "${cmd}" ]]; then
    cd ${REPOS_DIR}
    git clone "https://github.com/alexdobin/STAR"
    cd STAR/source
    make STAR
  fi
}

install_rsem() {
  local cmd="${BIN_DIR}/rsem-calculate-expression"
  if [[ ! -e "${cmd}" ]]; then
    cd ${REPOS_DIR}
    git clone -b "inutano" "https://github.com/inutano/RSEM"
    cd RSEM
    make
    make install DESTDIR="${BIN_DIR}"
  fi
}

install_tools(){
  install_pfastq_dump
  install_star
  install_rsem
}

main(){
  if [[ -e "${PROJECT_DIR}" ]]; then
    echo "installed."
  else
    setup
    check_prerequisites
    install_tools
  fi
}

#
# Run
#
main
