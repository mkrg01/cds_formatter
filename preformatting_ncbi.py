import pandas as pd
from pathlib import Path
import hashlib
import shutil
import argparse
import re

# parse command line arguments
parser = argparse.ArgumentParser(description='Prepare input files for NCBI formatter.')
parser.add_argument('--input_dir', type=str, help='Directory containing input files', default='ncbi_dataset')
parser.add_argument('--output_dir', type=str, help='Directory to save output files', default='ncbi_downloaded')
args = parser.parse_args()

dir_input = Path(args.input_dir)
dir_output = Path(args.output_dir)
file_md5sum = dir_input / 'md5sum.txt'
file_metadata = dir_input / 'ncbi_dataset' / 'data' / 'data_summary.tsv'

print('Checking MD5 checksums...')
with open(file_md5sum, 'r') as f:
    for line in f:
        true_md5sum = line.strip().split()[0]
        filepath = Path(dir_input / line.strip().split()[1])
        calculated_md5sum = hashlib.md5(open(filepath,'rb').read()).hexdigest()
        assert true_md5sum == calculated_md5sum, f"MD5 checksum mismatch: {filepath}"
print('MD5 checksums verified successfully.')

def format_species_name(species_name):
    species_name = species_name.replace(' ', '_')
    species_name = re.sub(r"[.\[\]'\(\)\"]", "", species_name)
    species_name = species_name.replace('/', '_')
    parts = species_name.split("_")
    if len(parts) > 1:
        species_name = parts[0] + "_" + "-".join(parts[1:])
    return species_name

print('Checking whether CDS, GFF, and genome files exist...')
metadata_df = pd.read_csv(file_metadata, sep='\t')
for idx, row in metadata_df.iterrows():
    species = format_species_name(row['Organism Scientific Name'])
    accession = row['Assembly Accession']
    assembly = row['Assembly Name'].replace(' ', '_')
    dir_accession = Path(dir_input / 'ncbi_dataset' / 'data' / accession)
    file_cds = dir_accession / "cds_from_genomic.fna"
    file_gff = dir_accession / "genomic.gff"
    file_genome = dir_accession / f"{accession}_{assembly}_genomic.fna"
    assert file_cds.exists(), f"CDS file not found for {species}: {file_cds}"
    assert file_gff.exists(), f"GFF file not found for {species}: {file_gff}"
    assert file_genome.exists(), f"Genome file not found for {species}: {file_genome}"
print('All required files exist.')

print('Moving CDS, GFF, and genome files...')
for idx, row in metadata_df.iterrows():
    species = format_species_name(row['Organism Scientific Name'])
    accession = row['Assembly Accession']
    assembly = row['Assembly Name'].replace(' ', '_')
    dir_accession = Path(dir_input / 'ncbi_dataset' / 'data' / accession)
    file_cds = dir_accession / "cds_from_genomic.fna"
    file_gff = dir_accession / "genomic.gff"
    file_genome = dir_accession / f"{accession}_{assembly}_genomic.fna"
    
    dir_output_accession = dir_output / f'{species}_{accession}'
    if not dir_output_accession.exists():
        dir_output_accession.mkdir(parents=True)
    
    shutil.copy(file_cds, dir_output_accession / 'cds_from_genomic.fna')
    shutil.copy(file_gff, dir_output_accession / 'genomic.gff')
    shutil.copy(file_genome, dir_output_accession / f'{accession}_{assembly}_genomic.fna')
print('Files moved successfully.')