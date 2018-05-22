#!/bin/bash
#
# Script to compress output results from taqcount.sh
# First argument $1 is parsed into script by taqcount.sh
#
# Create an array of the filenames to be compressed

declare -a tbc=(
high.fa
low.fa
high.mapped_all.bwt
high.mapped_mm1.bwt
high.suppressed_mm0.bwt
low.mapped_mm0.bwt
low.suppressed_mm1.bwt
high.mapped_mm0.bwt
high.suppressed_mm1.bwt
low.fa
low.mapped_all.bwt
low.mapped_mm1.bwt
low.suppressed_mm0.bwt
low.mapped_unique.bwt
high.mapped_unique.bwt
)

#Check whether pigz is installed, used it if present otherwise fallback to gzip
#pigz uses multicore
if hash pigz 2>/dev/null; then
	core_num=$(awk -F '\t' '$1 ~ /core_num/ {print $2}' settings.conf) #Fetch number of cores from settings.conf
	zipper="pigz -p $core_num"
	printf "\npigz found. Compressing files on $core_num cores\n"
else
	zipper="gzip"
	prinft "\nDid not find pigz on your machine. Will used gzip instead. Consider installing pigz to facilitate compression on multiple cores\n"
fi

for f in $1/*
do
g=${f##*/}
	if [[ " ${tbc[@]} " =~ " ${g} " ]];	then
		printf "Compressing $g...\n"
		pv $f | $zipper > $f.gz
		rm $f
	fi
done
