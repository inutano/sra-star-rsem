# Configuration file for rnaseq_recount.sh

# Uncomment and add source file if necessary
#source ${HOME}/.bash_profile

# Uncomment and edit PATH to include path to required binaries if necessary
#PATH=${HOME}/local/bin:${PATH}

# Set number of threads to be used by pipeline, default=2
NUMBER_OF_THREADS=8

# FIXME: directory and prefix for RSEM index files
RSEM_INDEX_DIR="${HOME}/data/reference/igenome/Homo_sapiens/UCSC/hg38/Sequence/RSEMIndex/STAR"
RSEM_INDEX_PREFIX="HS"

# Uncomment and edit experiment id and paths to input files, multiple files should be comma-separated
EXPERIMENT_ID="SRX534534"
#INPUT_FILES="/path/to/SRR1274306.sra,/path/to/SRR1274306.sra"

# Set temporary directory, default $HOME/data/readcount
TMPDIR="${HOME}/data/readcount"

# Set output directory, default $HOME/data/readcount
OUTDIR="${HOME}/data/readcount"
