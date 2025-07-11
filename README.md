# ncbi_formatter

> [!WARNING]
> This is currently intended for private use. 'pybase' and 'seqkit' conda environments on my MacBook were used.

#### Download from NCBI

1. Search annotated genomes via the NCBI datasets genome page (e.g., https://www.ncbi.nlm.nih.gov/datasets/genome/?taxon=261007&annotated_only=true&refseq_annotation=true&genbank_annotation=true)
2. Select assemblies
3. Push "Download/Download Package"
4. Select "Genome sequences (FASTA)", "Annotation features (GFF)", and "Genomic coding sequences (FASTA)"
5. Push "Download"
6. Unzip `ncbi_dataset.zip`, and place `ncbi_dataset` to `ncbi_formatter` directory

> [!NOTE]
> It may be better to download GenBank and RefSeq assemblies separately, so that RefSeq can be prioritized when both are available.

#### Run preformatter

```
bash preformatting_ncbi.sh
```

> [!NOTE]
> Please check that the species names are formatted correctly.

#### Run formatter

> [!WARNING]
> The code should be run on a Mac. The `sed` command on Linux does not work properly.

```
bash formatting_ncbi.sh
```
