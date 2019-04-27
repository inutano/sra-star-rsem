#!/bin/bash
set -e

#
# Variable
#
PROJECT_DIR="${HOME}/.readcount"
REPOS_DIR="${PROJECT_DIR}/repos"
BIN_DIR="${PROJECT_DIR}/bin"

STAR_VERSION="2.5.2b"
RSEM_VERSION="1.2.31-inutano.1"

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
  fi
  "${cmd}" "--version"
}

install_star() {
  local cmd="${BIN_DIR}/STAR"
  if [[ ! -e "${cmd}" ]]; then
    cd ${REPOS_DIR}
    wget "https://github.com/alexdobin/STAR/archive/${STAR_VERSION}.tar.gz"
    tar zxf "${STAR_VERSION}.tar.gz"
    cd "STAR-${STAR_VERSION}/source"
    make STAR
    case "$(uname -s)" in
      Linux*)
        ln -s "./bin/Linux_x86_64_static/*" "${BIN_DIR}"
      Darwin)
        ln -s "./bin/MacOSX_x86_64/*" "${BIN_DIR}"
      *)
        echo "ERROR: Unknown operation system. Quit installing.."
        exit 1
    esac
  fi
  "${cmd}" "--version"
}

install_rsem() {
  local cmd="${BIN_DIR}/rsem-calculate-expression"
  if [[ ! -e "${cmd}" ]]; then
    cd ${REPOS_DIR}
    wget "https://github.com/inutano/RSEM/archive/v${RSEM_VERSION}.tar.gz"
    tar zxf "v${RSEM_VERSION}.tar.gz"
    cd "RSEM-${RSEM_VERSION}"
    make
    make install DESTDIR="${REPOS_DIR}" prefix="/"
  fi
  "${cmd}" "--version"
}

install_tools(){
  install_pfastq_dump
  install_star
  install_rsem
}

main(){
  setup
  check_prerequisites
  install_tools
}

#
# Run
#
main
