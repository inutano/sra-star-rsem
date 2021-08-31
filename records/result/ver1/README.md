# Public RNA-seq analysis data Ver. 1

## Files

### Metadata

The metadata of data processing is recorded in [`tarball_mdata.yml`](./tarball_mdata.yml).

- md5sum
- The version of reference genome used
- Data amount
  - The number of experiments processed
  - Amount of Sequencing
  - File size
- The version of processing software used

### Processed experiments

The identifiers of the processed public data are recorded in the following files:

- [`experiments_processed.tsv`](./experiments_processed.tsv)
  - SRA experiment IDs (e.g. `DRX011551`) processed and local directory paths (just for logging purpose)
- [`experiments_processed_with_biosample.tsv`](./experiments_processed_with_biosample.tsv)
  - The relation of SRA experiment IDs and BioSample IDs (e.g. `SAMD00012590`)
- [`experiments_removed.txt`](./experiments_removed.txt)
  - The identifiers of public experiments now removed from the repository
  - Still the data are usable, but not able to referable anymore. Better removed from the set when performing analysis

The sample information is archived in the [BioSample](https://ncbi.nlm.nih.gov/biosample) database. Each BioSample entry is assigned a BioSample ID, and the data submitters describe the sample information in the form of key-value pairs. For example, the entry [SAMD00012590](https://www.ncbi.nlm.nih.gov/biosample/?term=SAMD00012590) has two attributes `sample name` and `sample comment`, with the values `DRS011387` and `Kasumi-1 cells transduced with wild-type RAD21 using retorovirus-based expression vector`, respectively. The entire biosample records are published in a form of XML on NCBI's FTP site ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz (daily updated).

There are many BioSample entries which do not follow the standard guidelines, thus do not have information required for the analysis. The one mentioned above, `SAMD00012590` only has the metadata such as cell type and the experimental conditions are described in `sample comment` with the free text format, making it difficult to extract the information automatically.
