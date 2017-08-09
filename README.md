# RNAseq readcount workflow

get data from SRA, pfastq-dump/STAR/RSEM

# Quick start

Fetch data from NCBI and run workflow

```
$ cd rnaseq-readcount-workflow
$ mkdir test
$ ./bin/download_sra.sh --database ncbi --experiment SRX534534 --outdir $(pwd)
$ ./bin/rnaseq_readcount.sh -j ./conf/conf_example.sh -f SRX534/SRX534534/<date of download>/SRR1274306.sra,SRX534/SRX534534/<date of download>/SRR1274307.sra -x SRX534534
```

