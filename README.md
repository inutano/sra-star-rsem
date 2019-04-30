# RNAseq readcount workflow

This repository contains the scripts and the [Common Workflow Language](https://commonwl.org) definition files of the RNA-Seq quantification workflow. The workflow is designed to perform the gene expression analysis for human/mouse RNA-Seq data using [STAR](https://github.com/alexdobin/STAR) and [RSEM](https://github.com/deweylab/RSEM).

We modified the RSEM script `rsem-calculate-expression` to change input parameters to STAR command along with the [ENCODE project standard](https://www.encodeproject.org/pipelines/ENCPL002LSE/). The modified script is published at [inutano/RSEM](https://github.com/inutano/RSEM).

***To make installation and deployment easier, we highly recommend to use CWL version of the workflow. The introduction and examples are available [here](analysis/processing/readcount/cwl).***

Note that the workflow requires >32GB memory for human/mouse RNA-Seq data.

## Workflow steps

![workflow structure drawn by [view.commonwl.org](https://view.commonwl.org/workflows/github.com/inutano/sra-star-rsem/blob/master/analysis/processing/readcount/cwl/rsem_from_sra_wf.cwl)](analysis/processing/readcount/cwl/images/star-rsem.png)

The image is drawn by [view.commonwl.org](https://view.commonwl.org)
