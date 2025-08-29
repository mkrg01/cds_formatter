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
6. Unzip `ncbi_dataset.zip`, and place the unzipped directory to `cds_formatter` directory

> [!NOTE]
> It may be better to download GenBank and RefSeq assemblies separately, so that RefSeq can be prioritized when both are available.

### 2. Run preformatter

```
bash script/preformatting_ncbi.sh > script/preformatting_ncbi.sh.out 2> script/preformatting_ncbi.sh.err
```

> [!NOTE]
> Please check that the species names are formatted correctly.

### 3. Run formatter

#### Option 1: Using original CDS
```
bash script/formatting_ncbi_cdsheader.sh > script/formatting_ncbi_cdsheader.sh.out 2> script/formatting_ncbi_cdsheader.sh.err
```

#### Option 2: Generating CDS from genome and gff files using [`gffread`](https://github.com/gpertea/gffread)
```
bash script/formatting_ncbi_gffread.sh > script/formatting_ncbi_gffread.sh.out 2> script/formatting_ncbi_gffread.sh.err
```

> [!NOTE]
> The `script/formatting_ncbi_cdsheader.sh` and `script/formatting_ncbi_gffread.sh` can be run in batch with multiple outputs from the `script/preformatting_ncbi.sh` (the only required input is the `ncbi_downloaded` directory).

> [!NOTE]
> Please check `script/formatting_ncbi_cdsheader.sh` or `script/formatting_ncbi_gffread.sh.out` to ensure that the headers are formatted correctly. At present, either `gene` or `locus_tag` is required for extracting the longest isoforms.


## EnsemblPlants formatter

### Download from EnsemblPlants (for one species)

1. [Search species](https://plants.ensembl.org/species.html)
2. Click species names
3. Click FASTA (Download genes, cDNAs, ncRNA, proteins - FASTA)
4. Click cds
5. Download `*.cds.all.fa.gz`
6. Click GFF3 (Download genes, cDNAs, ncRNA, proteins - GFF3)
7. Download `*.gff3.gz`
6. Place `*.cds.all.fa.gz` and `*.gff3.gz` to `EnsemblPlants/original_files/`

### Run formatter

```
bash script/formatting_ensemblplants_cdsheader.sh > script/formatting_ensemblplants_cdsheader.sh.out 2> script/formatting_ensemblplants_cdsheader.sh.err
```


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


## Formatter for the other sources (from genome and gff)

### Prepare genome and gff files

1. Create a directory named `{species}_{identifier}` in `other_downloaded/`
2. Put gff and genome files in `other_downloaded/{species}_{identifier}/`

### Run formatter

```
bash script/formatting_other_gffread.sh > script/formatting_other_gffread.sh.out 2> script/formatting_other_gffread.sh.err
```

> [!WARNING]
> Please check `script/formatting_other_gffread.sh.out` to ensure that the headers are formatted correctly. You should custom sed command in `script/formatting_other_gffread.sh` to get unique gene identifiers.