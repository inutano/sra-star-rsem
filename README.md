# RNAseq readcount workflow

get data from SRA, pfastq-dump/STAR/RSEM

# Prerequisites

- [lftp](https://lftp.yar.ru) and fast internet connection
- [pfastq-dump](https://github.com/inutano/pfastq-dump)
- [inutano/RSEM (build from inutano branch)](https://github.com/inutano/RSEM/tree/inutano)

# Quick start

Fetch data from NCBI and run workflow

```
$ cd rnaseq-readcount-workflow
$ mkdir test
$ ./bin/download_sra.sh --database ncbi --experiment SRX534534 --outdir $(pwd)
$ ./bin/rnaseq_readcount.sh -j ./conf/conf_example.sh -f SRX534/SRX534534/<date of download>/SRR1274306.sra,SRX534/SRX534534/<date of download>/SRR1274307.sra -x SRX534534
```

# Bulk execution

```
$ cd rnaseq-readcount-workflow
$ ./bin/bulk_rnaseq_readcount.sh -j ./conf/bulk_conf_example.sh
```
