# STAR/RSEM transcriptome quantification CWL

Common Workflow Language (CWL) is a workflow description standard developed by the CWL community. Visit the [project website](https://commonwl.org) and read the documents for more details. CWL allows to describe a workflow in the format that many different workflow engines can execute the exactly same procedure. Here we provide the CWL description for STAR/RSEM workflow.

## Prerequisites

- Workflow runner
  - Any of workflow runners that support CWL. For starter, we recommend the most basic local runner [cwltool](https://github.com/common-workflow-language/cwltool/).
  - The workflow is verified with the cwltool version `1.0.20190228155703`.
- Container engine
  - You may need to install one of the container engines, Docker, uDocker, or Singularity.
  - cwltool will use Docker as default container engine: you need to use `--singularity` option to use Singularity.
- STAR reference index
  - You can use your own build, or you may want to download RSEM/STAR index for human GRCh38 from [here](https://s3.amazonaws.com/nig-reference/GRCh38/rsem_star_index/rsem_star_GRCh38.tar.gz)(25GB, MD5: `12991b5ab993ae14b4bb3f95fee37e59`).

## Quick start

### Input local FASTQ file

To browse the required runtime parameters for the command line tool:

```
$ cwltool rsem-calculate-expression.cwl --help
```

Execute RSEM/STAR with your local FASTQ file:

```
$ cd analysis/processing/readcount/cwl
$ cwltool --debug rsem-calculate-expression.cwl \
    --nthreads 16 \
    --rsem_index_dir /path/to/rsem_star_GRCh38 \
    --rsem_index_prefix HS \
    --rsem_output_prefix rsem_test \
    --input_fastq SRR1274306.fastq
```

cwltool supports YAML format job configuration file which can be used to set the parameters in a reproducible way:

```
$ cwltool --make-template rsem-calculate-expression.cwl > job_conf.yaml
$ # Edit job_conf.yaml to set the parameters
$ cwltool --debug rsem-calculate-expression.cwl job_conf.yaml
```

For singularity users:

```
$ cwltool --singularity --debug rsem-calculate-expression.cwl job_conf.yaml
```

### Input public sequence data available on SRA

The tool definition files `download-sra.cwl`, `pfastq-dump.cwl`, and `rsem-calculate-expression.cwl` need to be in the same directory of the workflow definition file `rsem_from_sra_wf.cwl`

```
$ cd analysis/processing/readcount/cwl
$ ls
download-sra.cwl  pfastq-dump.cwl  rsem-calculate-expression.cwl  rsem_wf.cwl
```

To browse the required runtime parameters for the workflow:

```
$ cwltool rsem_from_sra_wf.cwl --help
```

Execute the workflow:

```
$ cwltool --debug rsem_wf.cwl \
    --nthreads 64 \
    --repo ebi \
    --rsem_index_dir /path/to/rsem_star_GRCh38 \
    --rsem_index_prefix HS \
    --rsem_output_prefix rsem_test \
    --run_ids SRR1274306
```

We recommend to make a job configuration file by `--make-template` which makes your life easier:

```
$ cwltool --make-template rsem_wf.cwl > job_conf.yaml
$ # Edit job_conf.yaml to set the parameters
$ cwltool --debug rsem_wf.cwl job_conf.yaml
```

For singularity users:

```
$ cwltool --singularity --debug rsem_wf.cwl job_conf.yaml
```
