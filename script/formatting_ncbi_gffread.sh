#!/bin/bash

# CDS, gff, and genome data formatting
# Run preformatting_ncbi.sh beforehand
# Formatting should be performed on Mac (BSD sed, not GNU sed)
# CDS will be generated from genome and gff files using gffread
# The locus_tag or gene in the generated CDS FASTA headers will be used to select the longest isoform for each gene

# Input example: 
# Input gff: "ncbi_downloaded/Amaranthus_tricolor_GCF_026212465.1/genomic.gff"
# Input genome: "ncbi_downloaded/Amaranthus_tricolor_GCF_026212465.1/GCF_008831285.2_ASM883128v2_genomic.fna"

# Please modify sed commands to curate cds header if necessary
custom_sed_command="-e s/.*gene=\([^;]*\).*/>\1/ -e s/.*locus_tag=\([^;]*\).*/>\1/"

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
			if [[ ( ${file} == *${accession}*_genomic.fna.gz ) && ! -s ${dir_formatted_cds}/${sci_name_ub}_${accession}.fa.gz ]]; then
				echo Formatting CDS file...
                gunzip -c ${dir_sp}/${sci_name_ub}_genomic.gff.gz > ${dir_sp}/${sci_name_ub}_genomic.gff
                gunzip -c ${dir_sp}/${file} > ${dir_sp}/`basename ${file} .gz`
                gffread -F -C -g ${dir_sp}/`basename ${file} .gz` -x tmp.cds.fa ${dir_sp}/${sci_name_ub}_genomic.gff
                if [[ -e ${dir_sp}/`basename ${file} .gz`.fai ]]; then
                    rm ${dir_sp}/`basename ${file} .gz`.fai
                fi
                first_header=$(cat tmp.cds.fa | head -n1)
				echo Gffread CDS full header: ${first_header}
				if [[ "$first_header" != *"gene="* && "$first_header" != *"locus_tag="* ]]; then
					echo "Error: header does not contain 'gene=' or 'locus_tag=': $file" | tee >(cat >&2)
                    rm ${dir_sp}/${sci_name_ub}_genomic.gff
                    rm ${dir_sp}/`basename ${file} .gz`
                    rm tmp.cds.fa
					exit 1
				fi
                seqkit seq --threads ${NSLOTS} tmp.cds.fa \
                | sed $custom_sed_command -e "s/^>/>${sci_name_ub}_/" \
				| cdskit aggregate --expression ":.*" \
				| cdskit pad \
				| seqkit seq --threads ${NSLOTS} --out-file ${dir_formatted_cds}/${sci_name_ub}_${accession}.fa.gz
                echo Formatted CDS header: `seqkit seq --threads ${NSLOTS} ${dir_formatted_cds}/${sci_name_ub}_${accession}.fa.gz | head -n 1`
                rm tmp.cds.fa
                rm ${dir_sp}/${sci_name_ub}_genomic.gff
                rm ${dir_sp}/`basename ${file} .gz`
			fi
			if [[ ${file} == *.gff.gz && ! -s ${dir_formatted_gff}/${sci_name_ub}_${accession}.gff.gz ]]; then
				echo Copying: ${file}
				cp ${dir_sp}/${file} ${dir_formatted_gff}/${sci_name_ub}_${accession}.gff.gz
			fi
		done
		if [[ -e ${dir_formatted_cds}/${sci_name_ub}_${accession}.fa.gz ]]; then
			echo Original CDS header: `seqkit seq --threads ${NSLOTS} ${dir_sp}/${sci_name_ub}_cds_from_genomic.fna.gz | head -n 1`
		fi
		if [[ -e ${dir_formatted_gff}/${sci_name_ub}_${accession}.gff.gz ]]; then
			echo "First 5 lines of gene and CDS features in the formatted GFF:"
			gzcat ${dir_formatted_gff}/${sci_name_ub}_${accession}.gff.gz | grep -v "^#" | awk -F '\t' '$3 == "gene" || $3 == "CDS"' | head -n 5
		fi
		echo ""
	fi
done
echo "Done!"