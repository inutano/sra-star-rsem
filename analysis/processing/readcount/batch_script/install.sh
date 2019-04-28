#!/bin/bash
set -e

#
# Variable
#
WORKFLOW_VERSION="1.0.0"
PROJECT_DIR="${HOME}/.readcount"
REPOS_DIR="${PROJECT_DIR}/repos"
BIN_DIR="${PROJECT_DIR}/bin"

STAR_VERSION="2.5.2b"
RSEM_VERSION="1.2.31-inutano.1"

cmd_pfastq_dump="${BIN_DIR}/pfastq-dump"
cmd_star="${BIN_DIR}/STAR"
cmd_rsem="${BIN_DIR}/rsem-calculate-expression"

#
# Install target dir
#
while [[ $# -gt 0 ]]; do
  key=${1}
  case ${key} in
    -v|--version)
      echo "${WORKFLOW_VERSION}"
      exit 0
      ;;
    --prefix)
      PROJECT_DIR="${2}"
      shift
      ;;
  esac
  shift
done

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

install_pfastq_dump(){
  if [[ ! -e "${cmd_pfastq_dump}" ]]; then
    cd ${REPOS_DIR}
    git clone "https://github.com/inutano/pfastq-dump"
    ln -s "${REPOS_DIR}/pfastq-dump/bin/pfastq-dump" "${cmd_pfastq_dump}"
    chmod +x "${cmd_pfastq_dump}"
  fi
}

install_star(){
  if [[ ! -e "${cmd_star}" ]]; then
    cd ${REPOS_DIR}
    wget "https://github.com/alexdobin/STAR/archive/${STAR_VERSION}.tar.gz"
    tar zxf "${STAR_VERSION}.tar.gz"
    cd "STAR-${STAR_VERSION}/source"
    make STAR
    cd ..
    case "$(uname -s)" in
      Linux*)
        ln -s "./bin/Linux_x86_64_static/"* "${BIN_DIR}"
        ;;
      Darwin)
        ln -s "./bin/MacOSX_x86_64/"* "${BIN_DIR}"
        ;;
      *)
        echo "ERROR: Unknown operation system. Quit installing.."
        exit 1
        ;;
    esac
  fi
}

install_rsem(){
  if [[ ! -e "${cmd_rsem}" ]]; then
    cd ${REPOS_DIR}
    wget "https://github.com/inutano/RSEM/archive/v${RSEM_VERSION}.tar.gz"
    tar zxf "v${RSEM_VERSION}.tar.gz"
    cd "RSEM-${RSEM_VERSION}"
    make
    make install DESTDIR="${PROJECT_DIR}" prefix="/"
  fi
}

install_tools(){
  install_pfastq_dump
  install_star
  install_rsem
}

check_version(){
  "${cmd_pfastq_dump}" "--version"
  "${cmd_star}" "--version"
  "${cmd_rsem}" "--version"
}

main(){
  setup
  check_prerequisites
  install_tools
  check_version
}

#
# Run
#
main
