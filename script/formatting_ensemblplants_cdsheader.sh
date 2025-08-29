date

format_cds=1
format_gff=1
overwrite=0
dir_original="EnsemblPlants/original_files"
dir_formatted="EnsemblPlants/formatted_files"
common_sed_exp='-e "s/evm_27.model.//g" -e "s/evm.model.//g" -e "s/Oropetium_20150105_//g"'

mkdir -p ${dir_formatted}
sp_names=( `ls ${dir_original} | sed -e "s/\\..*//" | sort -u` )
for sp_name in ${sp_names[@]}; do
	echo "${sp_name}"
	path_original_cds="`ls ${dir_original}/${sp_name}*.fa.gz`"
	path_original_gff="`ls ${dir_original}/${sp_name}*.gff3.gz`"
	path_formatted_cds="${dir_formatted}/`basename ${path_original_cds}`"
	path_formatted_gff="${dir_formatted}/`basename ${path_original_gff}`"
	flag_cds=0
	flag_gff=0
	sp_ub=`echo "${sp_name}" | sed -e "s/_/|/" -e "s/_.*//" -e "s/|/_/"`
	if [[ -s ${path_original_cds} ]]; then
		flag_cds=1
		if [[ ${format_cds} -eq 1 ]]; then
			echo "CDS file: ${path_original_cds}"
			if [[ ! -s ${path_formatted_cds} || ${overwrite} -eq 1 ]]; then
		        grep -q -e "gene:" ${path_original_cds}; exit_code=$?
		        if [[ ${exit_code} -eq 1 ]]; then
					echo 'Gene IDs will be extracted from the sequence description attribute "gene".'
					my_command="gzcat ${path_original_cds} | sed -e \"s/^\>.*gene:/\>${sp_ub}_/\"  -e \"s/[[:space:]].*//\" ${common_sed_exp} | cdskit pad | cdskit aggregate -x "PLACEHOLDER" | pigz > ${path_formatted_cds}"
				else
					echo 'Gene IDs will be obtained from the sequence ID.'
					my_command="gzcat ${path_original_cds} | sed -e \"s/^\>/\>${sp_ub}_/\" -e \"s/[[:space:]].*//\" ${common_sed_exp} | cdskit pad | cdskit aggregate -x "PLACEHOLDER" | pigz > ${path_formatted_cds}"
				fi
				bash -c "${my_command}"
			fi
			gzcat ${path_original_cds} | grep "^>" | head -n 3
			gzcat ${path_formatted_cds} | grep "^>" | head -n 3
			echo "Number of genes before formatting: `gzcat ${path_original_cds} | grep "^>" | wc -l`"
			echo "Number of genes after formatting: `gzcat ${path_formatted_cds} | grep "^>" | wc -l`"
		fi
	fi
	if [[ -s ${path_original_gff} ]]; then
		flag_gff=1
		if [[ ${format_gff} -eq 1 ]]; then
			echo "GFF file: ${path_original_gff}"
			if [[ ! -s ${path_formatted_gff} || ${overwrite} -eq 1 ]]; then
				my_command="gzcat ${path_original_gff} | sed ${common_sed_exp} | pigz > ${path_formatted_gff}"
				bash -c "${my_command}"
			fi
			#gzcat ${path_original_gff} | grep -v "^#" | head -n 3
			#gzcat ${path_formatted_gff} | grep -v "^#" | head -n 3
		fi
	fi
	if [[ ${flag_cds} -eq 0 ]]; then
		echo "ERROR: CDS file not detected: ${dir_sp}"
	fi
	if [[ ${flag_gff} -eq 0 ]]; then
		echo "ERROR: GFF file not detected: ${dir_sp}"
	fi
	echo ""
done
cd ${dir_original}


date


: <<'#_______________CO_______________'


#_______________CO_______________