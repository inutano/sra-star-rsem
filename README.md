# RNAseq readcount workflow

## Prerequisites

- [lftp](https://lftp.yar.ru) and fast internet connection
- [pfastq-dump](https://github.com/inutano/pfastq-dump)
- [alexdobin/STAR](https://github.com/alexdobin/STAR)
- [inutano/RSEM (build from inutano branch)](https://github.com/inutano/RSEM/tree/inutano)

## Quick start

### Fetch and Run

Fetch data from NCBI:

```
$ download_sra.sh --database ncbi --experiment-id SRX534534 --outdir $(pwd)
```

Run STAR/RSEM:

```
$ rnaseq_readcount.sh -j conf_example.sh -f SRR1274306.sra,SRR1274307.sra -x SRX534534
```

### Bulk execution

```
$ bulk_rnaseq_readcount.sh -j bulk_conf_example.sh
```
