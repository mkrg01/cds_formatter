source ~/miniconda3/etc/profile.d/conda.sh
conda activate seqkit

format_cds=1
format_gff=1
overwrite=0
dir_base="phycocosm"
dir_original="${dir_base}/species_wise_original"
dir_formatted="${dir_base}/species_wise_formatted"
common_sed_exp='-e "s/evm_27.model.//g" -e "s/evm.model.//g" -e "s/Oropetium_20150105_//g"'
phycocosm_sed_exp='-e "s/jgi|//" -e "s/|/_/g" -e "s/+/_/g" -e "s/:/_/g" -e "s/%/_/g" -e "s/\#/_/g" -e "s/\//_/g" -e "s/\[/_/g" -e "s/\]/_/g" -e "s/(/_/g" -e "s/)/_/g"'

dir_spp=( `ls ${dir_original}` )
for dir_sp in ${dir_spp[@]}; do
	echo "${dir_sp}"
	flag_cds=0
	flag_gff=0
	sp_ub=`echo "${dir_sp}" | sed -e "s/_/|/" -e "s/_.*//" -e "s/|/_/"`
	if [[ ! -e ${dir_formatted}/${dir_sp} ]]; then
		mkdir -p ${dir_formatted}/${dir_sp}
	fi
	original_files=( `ls ${dir_original}/${dir_sp}` )
	for original_file in ${original_files[@]}; do
		if echo "${original_file}" | grep -qi "cds.*fasta\.gz$"; then
			flag_cds=1
			if [[ ${format_cds} -eq 1 ]]; then
				original_cds_file="${dir_original}/${dir_sp}/${original_file}"
				formatted_cds_file="${dir_formatted}/${dir_sp}/${sp_ub}_${original_file}"
				echo "CDS file: ${original_cds_file}"
				if [[ ! -s ${formatted_cds_file} || ${overwrite} -eq 1 ]]; then
					my_command="gzcat ${original_cds_file} | sed -e \"s/[[:space:]].*//\"  ${phycocosm_sed_exp} -e \"s/^\>/\>${sp_ub}_/\" ${common_sed_exp} | cdskit pad | pigz > ${formatted_cds_file}"
					bash -c "${my_command}"
				fi
				gzcat ${original_cds_file} | grep "^>" | head -n 3
				gzcat ${formatted_cds_file} | grep "^>" | head -n 3
			fi
		fi
		if echo ${original_file} | grep -qi "gff.*\.gz"; then
			flag_gff=1
			if [[ ${format_gff} -eq 1 ]]; then
				original_gff_file="${dir_original}/${dir_sp}/${original_file}"
				formatted_gff_file="${dir_formatted}/${dir_sp}/${sp_ub}_${original_file}"
				echo "GFF file: ${original_gff_file}"
				if [[ ! -s ${formatted_gff_file} || ${overwrite} -eq 1 ]]; then
					my_command="gzcat ${original_gff_file} | sed ${common_sed_exp} | pigz > ${formatted_gff_file}"
					bash -c "${my_command}"
				fi
				gzcat ${original_gff_file} | grep -v "^#" | head -n 3
				gzcat ${formatted_gff_file} | grep -v "^#" | head -n 3
			fi
		fi
	done
	if [[ ${flag_cds} -eq 0 ]]; then
		echo "ERROR: CDS file not detected: ${dir_sp}"
	fi
	if [[ ${flag_gff} -eq 0 ]]; then
		echo "ERROR: GFF file not detected: ${dir_sp}"
	fi
	echo ""
done

conda deactivate