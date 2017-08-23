# Configuration file for bulk_rnaseq_recount.sh

# Uncomment and add source file if necessary
#source ${HOME}/.bash_profile

# Uncomment and edit PATH to include path to the required binaries if necessary
#PATH=${HOME}/local/bin:${PATH}

# Set temporary directory, default $HOME/data/readcount
TMPDIR="${HOME}/data/readcount"

# Set output directory, default $HOME/data/readcount
OUTDIR="${HOME}/data/readcount"

# Set database where the workflow fetch data from. "ncbi" or "ddbj"
DATABASE="ddbj"

# Set number of parallel FTP connections for data download
NUMBER_OF_PARALLEL_FTP=8

# Set number of threads to be used by calculation
NUMBER_OF_THREADS=2

# Uncomment lines below to enable UGE execution
#USE_UGE="true"
#LEAVE_TMPDIR="true"

# Set path to the calculation workflow script, should be absolute path
WF_SCRIPT="${HOME}/repos/rnaseq-readcount-workflow/bin/rnaseq_readcount.sh"

# Specify list of experiment IDs by csv string or file path.
# If a file path was specified, the programm expect the file contains one ID per line.
#EXPERIMENT_ID_LIST=/path/to/experiment_id_list.txt
EXPERIMENT_ID_LIST="SRX534534,SRX1069901,SRX1069907"

# FIXME: directory and prefix for RSEM index files
RSEM_INDEX_DIR="${HOME}/data/reference/igenome/Homo_sapiens/UCSC/hg38/Sequence/RSEMIndex/STAR"
RSEM_INDEX_PREFIX="HS"
