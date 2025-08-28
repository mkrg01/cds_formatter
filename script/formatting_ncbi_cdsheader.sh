#!/bin/bash

# CDS, gff, and genome data formatting
# Run preformatting_ncbi.sh beforehand
# Formatting should be performed on Mac (BSD sed, not GNU sed)
# The locus_tag or gene in the CDS FASTA headers will be used to select the longest isoform for each gene

# Input example: 
# Input gff: "ncbi_downloaded/Amaranthus_tricolor_GCF_026212465.1/genomic.gff"
# Input cds: "ncbi_downloaded/Amaranthus_tricolor_GCF_026212465.1/cds_from_genomic.fna"
# Input genome: "ncbi_downloaded/Amaranthus_tricolor_GCF_026212465.1/GCF_008831285.2_ASM883128v2_genomic.fna"

NSLOTS=4
dir_downloaded="./ncbi_downloaded"
dir_formatted_cds="./ncbi_formatted_cds"
dir_formatted_gff="./ncbi_formatted_gff"
if [[ ! -e ${dir_formatted_cds} ]]; then
	mkdir ${dir_formatted_cds}
fi
if [[ ! -e ${dir_formatted_gff} ]]; then
	mkdir ${dir_formatted_gff}
fi

input_names=( `ls ${dir_downloaded}` )
for input_name in ${input_names[@]}; do
	accession=`echo ${input_name} | awk -F'_' '{for (i=3; i<=NF; i++) printf $i (i<NF?FS:RS)}' | sed -e "s/.fna//"`
	sci_name_ub=`echo ${input_name} | cut -d'_' -f1-2`
	if [[ ${accession} == '' ]]; then
		echo "Skipping. Empty accesion for ${sci_name_ub}"
	else
		echo "Accesion: ${accession}, Scientifc name: ${sci_name_ub}"
		dir_sp="${dir_downloaded}/${sci_name_ub}_${accession}"
		if [[ -f ${dir_downloaded}/${input_name} ]]; then
			mkdir ${dir_sp}
			mv ${dir_downloaded}/${input_name} ${dir_sp}/
		fi
		if [[ -e ./ncbi_downloaded/${accession} ]]; then
			mv ./ncbi_downloaded/${accession} ${dir_sp}
		fi
		files=( `ls ${dir_sp}` )
		for file in ${files[@]}; do
			if [[ ${file} == ${sci_name_ub}* ]]; then
				echo Renaming done: ${file}
			else
				echo Renaming: ${file}
				mv ${dir_sp}/${file} ${dir_sp}/${sci_name_ub}_${file}
			fi
		done
		files=( `ls ${dir_sp}` )
		for file in ${files[@]}; do
			if [[ ${file} == ${sci_name_ub}* && ${file} != *.gz ]]; then
				echo Gzipping: ${file}
				pigz --processes ${NSLOTS} ${dir_sp}/${file}
			fi
		done
		files=( `ls ${dir_sp}` )
		for file in ${files[@]}; do
			if [[ ( ${file} == *cds_from_genomic.fna* || ${file} == *${accession}.fna* ) && ! -s ${dir_formatted_cds}/${sci_name_ub}_${accession}.fa.gz ]]; then
				first_header=$(gzcat ${dir_sp}/${file} | head -n1)
				echo Formatting CDS file: ${file}
				echo Original CDS header: ${first_header}
				if [[ "$first_header" != *"[gene="* && "$first_header" != *"[locus_tag="* ]]; then
					echo "Error: header does not contain '[gene=' or '[locus_tag=': $file" | tee >(cat >&2)
					exit 1
				fi
				seqkit seq --threads ${NSLOTS} ${dir_sp}/${file} \
				| sed -e "s/^>.*\[gene=/>/" -e "s/^>.*\[locus_tag=/>/" -e "s/\].*//" -e "s/lcl\|//" -e "s/[[:space:]].*//" -e "s/|.*//" -e "s/\.t[0-9]+$//" -e "s|/|_|g" -e "s/+/_/g" -e "s/:/_/g" -e "s/\|/_/g" -e "s/%/_/g" -e "s/^>/>${sci_name_ub}_/" \
				| cdskit aggregate --expression ":.*" \
				| cdskit pad \
				| seqkit seq --threads ${NSLOTS} --out-file ${dir_formatted_cds}/${sci_name_ub}_${accession}.fa.gz
				echo Formatted CDS header: `seqkit seq --threads ${NSLOTS} ${dir_formatted_cds}/${sci_name_ub}_${accession}.fa.gz | head -n 1`
			fi
			if [[ ${file} == *.gff.gz && ! -s ${dir_formatted_gff}/${sci_name_ub}_${accession}.gff.gz ]]; then
				echo Copying: ${file}
				cp ${dir_sp}/${file} ${dir_formatted_gff}/${sci_name_ub}_${accession}.gff.gz
			fi
		done
		if [[ -e ${dir_formatted_gff}/${sci_name_ub}_${accession}.gff.gz ]]; then
			echo "First 5 lines of gene and CDS features in the formatted GFF:"
			gzcat ${dir_formatted_gff}/${sci_name_ub}_${accession}.gff.gz | grep -v "^#" | awk -F '\t' '$3 == "gene" || $3 == "CDS"' | head -n 5
		fi
		echo ""
	fi
done
echo "Done!"