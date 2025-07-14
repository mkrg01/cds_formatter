dir_base="/Volumes/kfT7/Dropbox/repos/gfe_dataset/20221122_PhycoCosm"
dir_formatted="${dir_base}/species_wise_formatted"
dir_species_cds="${dir_base}/species_cds"
dir_species_gff="${dir_base}/species_gff"

if [[ ! -e ${dir_species_cds} ]]; then
	mkdir -p ${dir_species_cds}
fi
if [[ ! -e ${dir_species_gff} ]]; then
	mkdir -p ${dir_species_gff}
fi

dir_spp=( `ls ${dir_formatted}` )
for dir_sp in ${dir_spp[@]}; do
	sp_ub=`echo "${dir_sp}" | sed -e "s/_/|/" -e "s/_.*//" -e "s/|/_/"`
	files=( `ls ${dir_formatted}/${dir_sp}` )
	for file in ${files[@]}; do
		if [[ `echo ${file} | grep -e ".fasta.gz$"` ]]; then
			if [[ ! -s ${dir_species_cds}/${file} ]]; then
				cp ${dir_formatted}/${dir_sp}/${file} ${dir_species_cds}/${file}
			fi
		fi
		if [[ `echo ${file} | grep -e ".gff*.gz$"` ]]; then
			if [[ ! -s ${dir_species_gff}/${file} ]]; then
				cp ${dir_formatted}/${dir_sp}/${file} ${dir_species_gff}/${file}
			fi
		fi
	done
done

: <<'#_______________CO_______________'


#_______________CO_______________