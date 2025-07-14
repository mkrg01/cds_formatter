#!/bin/bash
# Input: ncbi_dataset containing CDS, gff, and genome sequence data

source ~/miniconda3/etc/profile.d/conda.sh
conda activate pybase
python script/preformatting_ncbi.py --input_dir ncbi_dataset --output_dir ncbi_downloaded
conda deactivate
