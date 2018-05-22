#!/bin/bash

# tbr = list of files To Be Removed
declare -a tbr=(
high.fa
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
)

for f in $1/*
do
g=${f##*/}
	if [[ " ${tbr[@]} " =~ " ${g} " ]];	then
		rm $f
	fi
done
