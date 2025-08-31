#!/bin/bash

# CDS, gff, and genome data formatting
# Formatting should be performed on Mac (BSD sed, not GNU sed)
# CDS will be generated from genome and gff files using gffread

# Input example: 
# Input gff: "other_downloaded/Aegilops_speltoides_Y2032/Y2032.updata.gff3" # ".gff" should be included
# Input genome: "other_downloaded/Aegilops_speltoides_Y2032/Y2032.updata.genome.fa" # ".fa" should be included

# Please modify sed commands to curate cds header correctly
custom_sed_command="-e s/.*gene=\([^;]*\).*/>\1/ -e s/.*locus_tag=\([^;]*\).*/>\1/ -e s/[[:space:]].*// -e s/\.[0-9][0-9]*$//"

date

NSLOTS=4
dir_downloaded="./other_downloaded"
dir_formatted="./other_formatted"
if [[ ! -e ${dir_formatted} ]]; then
	mkdir ${dir_formatted}
fi

input_names=( `ls ${dir_downloaded}` )
for input_name in ${input_names[@]}; do
	accession=`echo ${input_name} | awk -F'_' '{for (i=3; i<=NF; i++) printf $i (i<NF?FS:RS)}'`
	sci_name_ub=`echo ${input_name} | cut -d'_' -f1-2`
	if [[ ${accession} == '' ]]; then
		echo "Skipping. Empty accession for ${sci_name_ub}"
	else
		echo "Accession: ${accession}, Scientifc name: ${sci_name_ub}"
		dir_sp="${dir_downloaded}/${sci_name_ub}_${accession}"
		if [[ -f ${dir_downloaded}/${input_name} ]]; then
			mkdir ${dir_sp}
			mv ${dir_downloaded}/${input_name} ${dir_sp}/
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

        gff_file=$(find "${dir_sp}" -maxdepth 1 -name "*.gff*" | head -n1)
        genome_file=$(find "${dir_sp}" -maxdepth 1 -name "*.fa*" ! -iname "*cds*" | head -n1)

        dir_sp_out="${dir_formatted}/${sci_name_ub}_${accession}"
        if [[ ! -e ${dir_sp_out} ]]; then
            mkdir ${dir_sp_out}
        fi

        if [[ ! -s ${dir_sp_out}/${sci_name_ub}_${accession}.cds.fa.gz ]]; then
            echo Formatting CDS file...
            gunzip -c ${gff_file} > ${dir_sp}/tmp.gff
            gunzip -c ${genome_file} > ${dir_sp}/tmp.genome.fa
            gffread -F -C -g ${dir_sp}/tmp.genome.fa -x ${dir_sp}/tmp.cds.fa ${dir_sp}/tmp.gff
            if [[ -e ${dir_sp}/tmp.genome.fa.fai ]]; then
                rm ${dir_sp}/tmp.genome.fa.fai
            fi
            first_header=$(cat ${dir_sp}/tmp.cds.fa | head -n1)
            echo Gffread CDS full header: ${first_header}
            if [[ "$first_header" != *"gene="* && "$first_header" != *"locus_tag="* ]]; then
                echo "Warning: header does not contain 'gene=' or 'locus_tag=': $file" | tee >(cat >&2)
            fi
            seqkit seq --threads ${NSLOTS} ${dir_sp}/tmp.cds.fa \
            | sed $custom_sed_command -e "s/^>/>${sci_name_ub}_/" \
            | cdskit aggregate --expression ":.*" \
            | cdskit pad \
            | seqkit seq --threads ${NSLOTS} --out-file ${dir_sp_out}/${sci_name_ub}_${accession}.cds.fa.gz
            echo Formatted CDS header: `seqkit seq --threads ${NSLOTS} ${dir_sp_out}/${sci_name_ub}_${accession}.cds.fa.gz | head -n 1`
            rm ${dir_sp}/tmp.cds.fa
            rm ${dir_sp}/tmp.gff
            rm ${dir_sp}/tmp.genome.fa
        fi
        # Copy gff
        if [[ ! -s ${dir_sp_out}/${sci_name_ub}_${accession}.gff.gz ]]; then
            echo Copying: ${gff_file}
            cp ${gff_file} ${dir_sp_out}/${sci_name_ub}_${accession}.gff.gz
        fi
        # Copy genome
        if [[ ! -s ${dir_sp_out}/${sci_name_ub}_${accession}.genome.fa.gz ]]; then
            echo Copying: ${genome_file}
            cp ${genome_file} ${dir_sp_out}/${sci_name_ub}_${accession}.genome.fa.gz
        fi
		if [[ -e ${dir_sp_out}/${sci_name_ub}_${accession}.gff.gz ]]; then
			echo "First 5 lines of gene and CDS features in the formatted GFF:"
			gzcat ${dir_sp_out}/${sci_name_ub}_${accession}.gff.gz | grep -v "^#" | awk -F '\t' '$3 == "gene" || $3 == "CDS"' | head -n 5
		fi
		echo ""
	fi
done
echo "Done!"
