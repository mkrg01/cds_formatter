# cds_formatter
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)

CDS file formatting for gfe_pipeline. The formatting includes extracting the longest isoform for each gene.

> [!WARNING]
> The code should be run on a Mac. The `sed` command on Linux does not work properly.

## Installation
### 1. Clone this repository
```
git clone https://github.com/mkrg01/cds_formatter
cd cds_formatter
```

### 2.  Create and activate environment
```
mamba env create -f environment.yml
mamba activate cds_formatter
```


## NCBI formatter

### 1. Download from NCBI

1. Search annotated genomes via the NCBI datasets genome page (e.g., https://www.ncbi.nlm.nih.gov/datasets/genome/?taxon=261007&annotated_only=true&refseq_annotation=true&genbank_annotation=true)
2. Select assemblies
3. Push "Download/Download Package"
4. Select "Genome sequences (FASTA)", "Annotation features (GFF)", and "Genomic coding sequences (FASTA)"
5. Push "Download"
6. Unzip `ncbi_dataset.zip`, and place `ncbi_dataset` to `cds_formatter` directory

> [!NOTE]
> It may be better to download GenBank and RefSeq assemblies separately, so that RefSeq can be prioritized when both are available.

### 2. Run preformatter

```
bash script/preformatting_ncbi.sh > script/preformatting_ncbi.sh.out 2> script/preformatting_ncbi.sh.err
```

> [!NOTE]
> Please check that the species names are formatted correctly.

### 3. Run formatter

```
bash script/formatting_ncbi.sh > script/formatting_ncbi.sh.out 2> script/formatting_ncbi.sh.err
```
> [!NOTE]
> Please check `script/formatting_ncbi.sh.out` to ensure that the locus_tag is included in the header of the CDS file, which is necessary to extract only one CDS per gene.


## PhycoCosm formatter

### Download from PhycoCosm

1. Visit [PhycoCosm website](https://phycocosm.jgi.doe.gov/phycocosm/home)
2. Select target lineages
3. Push "Download"
4. Select "Annotation/Filtered Models/CDS", "Annotation/Genes", and "Assembly/Genome Assembly"
5. Push "Download Selected Files"
6. Unzip the downloaded file, and place the target assembly directories to `cds_formatter/phycocosm/species_wise_original` directory

### Rename directory name

Manually insert scientific names at the beginning of directory names.

### Run formatter

```
bash script/formatting_phycocosm.sh > script/formatting_phycocosm.sh.out 2> script/formatting_phycocosm.sh.err
```
