# STAR/RSEM readcount pipeline

## Workflow in [CWL](https://www.commonwl.org/)

### prerequisites

- Docker
- [Workflow runner supports CWL execution](https://www.commonwl.org/#Implementations) such as [cwltool](https://github.com/common-workflow-language/cwltool)

#### Install cwltool

Prerequisites:

- python-dev
- pip
- build-essentials (replace this to proper package for your linux distribution)
- libxml2-dev
- libxslt-dev
- zlib-dev

Use pip to install cwltool of recommended version:

```
$ pip install cwltool==1.0.20180820141117
```

### How to run CWL workflow

#### SRA Run ID => readcount data

Usage:

```
$ cwltool --debug rsem_wf.cwl --nthreads NTHREADS [--repo REPO] --rsem_index_dir RSEM_INDEX_DIR --rsem_index_prefix RSEM_INDEX_PREFIX --rsem_output_prefix RSEM_OUTPUT_PREFIX --run_ids RUN_IDS
```

Example:

```
$ ls $HOME/data/reference/RSEM_Index
Genome      HS.idx.fa      HS.ti              SA             chrName.txt        exonGeTrInfo.tab  genomeParameters.txt      sjdbList.out.tab
HS.chrlist  HS.n2g.idx.fa  HS.transcripts.fa  SAindex        chrNameLength.txt  exonInfo.tab      sjdbInfo.txt              transcriptInfo.tab
HS.grp      HS.seq         HSLog.out          chrLength.txt  chrStart.txt       geneInfo.tab      sjdbList.fromGTF.out.tab
$ cwltool --debug rsem_wf.cwl --nthreads 16 --rsem_index_dir $HOME/data/reference/RSEM_index --rsem_index_prefix HS --rsem_output_prefix rsem_result --run_ids SRR4250750
```

#### local fastq file => readcount data

Usage:

```
$ cwltool --debug rsem-calculate-expression.cwl [-h] --input_fastq INPUT_FASTQ --nthreads NTHREADS --rsem_index_dir RSEM_INDEX_DIR --rsem_index_prefix RSEM_INDEX_PREFIX --rsem_output_prefix RSEM_OUTPUT_PREFIX
```

Example:

```
$ ls $HOME/data/reads
data.fastq
$ ls $HOME/data/reference/RSEM_Index
Genome      HS.idx.fa      HS.ti              SA             chrName.txt        exonGeTrInfo.tab  genomeParameters.txt      sjdbList.out.tab
HS.chrlist  HS.n2g.idx.fa  HS.transcripts.fa  SAindex        chrNameLength.txt  exonInfo.tab      sjdbInfo.txt              transcriptInfo.tab
HS.grp      HS.seq         HSLog.out          chrLength.txt  chrStart.txt       geneInfo.tab      sjdbList.fromGTF.out.tab
$ cwltool --debug rsem-calculate-expression.cwl --input_fastq $HOME/data/reads/data.fastq --nthreads 16 --rsem_index_dir $HOME/data/reference/RSEM_index --rsem_index_prefix HS --rsem_output_prefix rsem_result
```

Note that this STAR/RSEM workflow expects multiple or paired reads to be concatenated as one single fastq file.
