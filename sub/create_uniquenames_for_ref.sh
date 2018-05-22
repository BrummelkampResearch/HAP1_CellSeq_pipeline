#/bin/bash

#################################################################
# create_uniquenames_for_ref.sh        							#
#################################################################
# This scripts is for creating	unique genenames in a gene-	    #
# reference file based on chr. and strand.			            #
# In rare more than one gene is carries the same name but is  	#
# location on different strands or chromosomes. In those case 	#
# this script changes the name of that gene by concatenating 	#
# the chromosome number and strand to it.			            #
#								                                #
# Author: Elmer Stickel					                    	#
# Date: 14/12/2015					                        	#
# Contact: elmer.stickel@posteo.net			                	#
#								                                #
#################################################################
#                                                               #
# Run as:                                                       #
# ./create_uniquenames_for_ref.sh reference.bed                 #
#                                                               #
#################################################################

generef=$1	# GeneRef file that still holds a number of genes with the same name on different chromosomes and/or strands
cp $generef ref1.tmp
printf "\n Searching for duplicate genenames\n"
# Create a list of all the genes that have duplicate names
awk '{print $4}' ref1.tmp | sort | uniq -d | sort > logwd.tmp # logwd = List of genes with duplicates

printf "Extract chromosome and strand of duplicate genenames"\n
touch logwdnpcs.tmp
for duplicates in $(cat logwd.tmp)
do
	awk -F'\t' -v dup=$duplicates '{if($4 == dup)print $4"\t"$1"\t"$6}' ref1.tmp >> logwdnpcs.tmp
	# logwdnpcs.tmp = list of genes with duplicate names plus chromosome and strand
	# file looks like: 
	# NF1	chr17	+
	# 
done


# Now unique in this list based on name, chrome and strand
sort logwdnpcs.tmp | uniq > loug.tmp # loug = list of unique genes 
# In this file, genes that have multiple annotations but only on the same strand and same chrom only occur once
# From this file, create a list of only genenames and identify those that still have duplicates. Those ones need to be renamed
awk '{print $1}' loug.tmp | sort | uniq -d > to_be_renamed.tmp

printf "\n Created a list of genes that require renaming\n"
for gene in $(cat to_be_renamed.tmp)
do
	awk -v gene=$gene -F'\t' '{if($4 == gene) {print $1"\t"$2"\t"$3"\t"$4"@"$1$6"\t"$5"\t"$6} else {print $0}}' ref1.tmp > ref2.tmp
	mv ref2.tmp ref1.tmp
done
sed 's/_//g' ref1.tmp > reference_unique_names.BED
printf "\n Duplicate names in your input reference have been changed and a new reference file is made: reference_unique_names.BED\n"