#!/bin/bash


#############################################################
# A tool to analyze haploid fixed screens					#
#############################################################
# authors:													#
# Vincent Blomen, Elmer Stickel & Bingbing Yuan				#
# Netherlands Cancer Insitute/Whitehead Institute			#
# February 206												#
# Commercial use of the software is prohibited wit$DIR 		#
# prior approval from both Elmer Stickel & Vincent Blomen 	#
#############################################################

# Steps involved in this script:
# 1. Fetch commandline arguments
# 2. Fetch parameters from settings.conf file
# 3. Check all paramters for correctness (pre-run tests)
# 4. The actual program
# 	4.1. Alignment to genome using bowtie
#	4.2. Annotate insertions to genes using intersectBed
# 	4.3. Combining the two datasets and perform statistical test
# 5. Create result files for Excel and Django
# 6. Compress$DIRput


#################################################
# 1. First fetch command line parameters
#################################################

for i in "$@"
do
case $i in
	-D=*|--dir=*)
	DIR="${i#*=}"
	shift # past argument with a value
	;;
	-U|--uncompressed)
	COMPRESS="NO" # unlike previous, this a is an argument wit$DIR a value
	;;
	-h|-?|--help)
	HELP="yes" # and this one doesn't
	shift
	;;
	*)
	;; # For any unknoqn options
esac
done




###########################################################
# 2. Fetch parameters from settings.conf
###########################################################
gene_ref=$(awk -F '\t' '$1 ~ /gene_ref/ {print $2}' settings.conf)
ref_id=$(awk -F '\t' '$1 ~ /ref_id/ {print $2}' settings.conf)
core_num=$(awk -F '\t' '$1 ~ /core_num/ {print $2}' settings.conf)
mem_limit=$(awk -F '\t' '$1 ~ /memory_limit/ {print $2}' settings.conf)
final_dir=$(awk -F '\t' '$1 ~ /final_dir/ {print $2}' settings.conf)





##########################################################
# 3. Pre-run tests (parameters and settings file)
##########################################################
# A bunch of variables we need
ff="FOUND\n"
fnf="NOT found \n\tExiting now\n"

# Check if input files and/or folders actually exist.

## Print welcome logo
cat sub/logo.art

# Make sure there's no trailing slash behind DIR
if [[ "$DIR" =~ \/$ ]]; then
	DIR=${DIR::-1}
else
	DIR=$DIR
fi
printf "*****\t\t\t\t\t\t\t\t\t\t   *****
*****   An extension for the analyis tool for haploid intracellular fixed screen_sense  *****
*****\t\t\t\t\t\t\t\t\t\t   *****
****************************************************************************************\n\n
Performing a few simple checks on the input parameters:"
SCREENNAME=$(printf $DIR | awk  -F"/" '{print $NF}' | sed 's/_output//')
printf "\tScreenname: $SCREENNAME\n"

# Check if we can create a new directy for the new annotation analysis
printf "\tChecking if directory we're about to create not already exists... "
if [ -d "$DIR/$ref_id" ]; then printf "\n\n\tIt seems you already mapped the aligned reads to this reference annotation\n\tExiting now\n" && exit; else printf "seems OK\n"; fi
mkdir $DIR/$ref_id

# Create the log files
printf "\n---------------- screenname: $SCREENNAME ----------------\n" > $DIR/$ref_id/annotation_log.txt
starttime=$(date +%s) #Keep track of current date in seconds (to calculate total running time)
printf "\tThe logfiles will be written to: $DIR/$ref_id/annotation_log.txt\n"

# There are 4 possible names of the files
# low.fastq.gz.input4enrichment.bed.gz
# low.fastq.input4enrichment.bed.gz
# low.fastq.gz.input4enrichment.bed
# low.fastq.input4enrichment.bed

# Check for alligned reads from LOW population
printf "\tfastqFile with reads from low population: " | tee -a $DIR/$ref_id/annotation_log.txt
if [ -f $DIR/low.fastq.gz.input4enrichment.bed ]; then
	low=low.fastq.gz
	printf "$DIR/low.fastq.gz.input4enrichment.bed ... $ff" | tee -a  $DIR/$ref_id/annotation_log.txt
elif [ -f $DIR/low.fastq.input4enrichment.bed ]; then
	low=low.fastq
	printf "$DIR/low.fastq.input4enrichment.bed ... $ff" | tee -a  $DIR/$ref_id/annotation_log.txt
elif [ -f $DIR/low.fastq.gz.input4enrichment.bed.gz ]; then
	gunzip $DIR/low.fastq.gz.input4enrichment.bed.gz
	low=low.fastq.gz
	printf "$DIR/low.fastq.gz.input4enrichment.bed.gz ... $ff" | tee -a  $DIR/$ref_id/annotation_log.txt
elif [ -f $DIR/low.fastq.input4enrichment.bed.gz ]; then
	gunzip $DIR/low.fastq.input4enrichment.bed.gz
	low=low.fastq
	printf "$DIR/low.fastq.input4enrichment.bed.gz ... $ff" | tee -a $DIR/$ref_id/annotation_log.txt
else printf "$fnf" && exit; fi

# Check for alligned reads from HIGH population
printf "\tfastqFile with reads from high population: " | tee -a $DIR/$ref_id/annotation_log.txt
if [ -f $DIR/high.fastq.gz.input4enrichment.bed ]; then
	high=high.fastq.gz
	printf "$DIR/high.fastq.gz.input4enrichment.bed ... $ff" | tee -a $DIR/$ref_id/annotation_log.txt
elif [ -f $DIR/high.fastq.input4enrichment.bed ]; then
	high=high.fastq
	printf "$DIR/high.fastq.input4enrichment.bed ... $ff" | tee -a $DIR/$ref_id/annotation_log.txt
elif [ -f $DIR/high.fastq.gz.input4enrichment.bed.gz ]; then
	gunzip $DIR/high.fastq.gz.input4enrichment.bed.gz
	high=high.fastq.gz
	printf "$DIR/high.fastq.gz.input4enrichment.bed.gz ... $ff" | tee -a $DIR/$ref_id/annotation_log.txt
elif [ -f $DIR/high.fastq.input4enrichment.bed.gz ]; then
	gunzip $DIR/high.fastq.input4enrichment.bed.gz
	high=high.fastq
	printf "$DIR/high.fastq.input4enrichment.bed.gz ... $ff" | tee -a $DIR/$ref_id/annotation_log.txt
else printf "$fnf" && exit; fi


# Check of gene annotation file is present and write to log
printf "\tGene annotation file $gene_ref... " | tee -a $DIR/$ref_id/annotation_log.txt
if [ -f $gene_ref ] ; then printf "$ff"  | tee -a $DIR/$ref_id/annotation_log.txt; else printf "$fnf"; exit; fi

printf "\n\t-----------------------
Everyting seems fine\n\n"

# Copy the settings file to the output directory, always  useful to have
cp settings.conf $DIR/$ref_id/settings.conf
##########################



printf "\n\n\n\n"
####################################
# 4. Here the actual program starts
####################################

# Row a number of steps have to carried$DIR on the low and high files, preprocessing of the reads and alignment to the genome. The for loops makes sure all steps are carried$DIR on both the low as well as the high file
for f in $low $high	#$LOW is = low.fastq, $HIGH = high.fastq, #f is current file
do
	printf "\n|||||||||||||||||||||||||||||||||||||||||||||||||||||||\n"
 	printf "*******\tNow processing file: $f\t*******\n"
	printf "|||||||||||||||||||||||||||||||||||||||||||||||||||||||\n\n"


##########################################################
# 4.1. Annotate insertions to genes using intersectBed
##########################################################

	# Now run intersectbed with -wo option
	printf "Mapping insertions to genes using intersectbed..."
	intersectBed -a $DIR/$f.input4enrichment.bed -b $gene_ref -wo >| $DIR/$ref_id/$f.inputtocoupletogenes+gene_all.txt
       	# The$DIRput file looks like
       	# chr10 100001181       100001182       AATATAGTCATTTCTGTTGATTGATTTATTATATTGGAGAATGAAAGTTT	+       chr10   99894381        100004654       R3HCC1L 0       +       1
       	# chr10 100010840       100010841	ATGGCTGATTCCACAGTGGCTCGGAGTTACCTGTGTGGCAGTTGTGCAGC      -       chr10   100007443       100028007       LOXL4   0       -       1
	printf "done\n"

	# Now the reads have been mapped to genes we separate the sense integrations from the antisense integrations. In the remainder of this program only the sense integrations are used but for legacy purposes we still keep the antisense integrations
	# If integration is sense than strand (col 4) and orientation (col 11) match
	# The format of the$DIRput file is as follows:
	# chr1    10001144        10001145        LZIC
	printf "Extracting sense integrations..."
	awk -F"\t" '{ if($5==$11) print $1"\t"$2"\t"$3"\t"$9 }' $DIR/$ref_id/$f.inputtocoupletogenes+gene_all.txt | sort --parallel=$core_num --buffer-size=$mem_limit > $DIR/$ref_id/$f.gene+screen_sense.txt
	printf "done\n"
	# If integration is antisense,  then strand (col 4) and orientation (col 11) do not match
	printf "Extracting antisense integrations..."
    awk -F"\t" '{if($5!=$11) print $1"\t"$2"\t"$3"\t"$9 }' $DIR/$ref_id/$f.inputtocoupletogenes+gene_all.txt | sort --parallel=$core_num --buffer-size=$mem_limit > $DIR/$ref_id/$f.gene+screen_antisense.txt
	printf "done\n"

done
printf "\n|||||||||||||||||||||||||||||||||||||||||||||||||||||||"

# All alignment is now done. The insertions have been mapped to a gene and the antisense and sense insertions are identified
# To compare the number of sense mutations in the lowest 5% to the highest 5%, an intermediate file is first created that serves as input for R's Fisher exact test

# Call python script to build a file that can be used to run a fisher exact test on. In short this script does the following:
# Both both the low and high sample, it count the number of insertions in each gene. Also it counts the total number of insertions for each sample and for each gene it calculates the
# total number in the sample minus the number if insertions in that gene. These numbers (total insertions in each gene and for each gene the grant total of insertions minus number of insertions in each gene)
# for both the high and low are merged into a single file.

##########################################################
# 4.3. Combining the two datasets and perform statistical test
##########################################################

printf "\n\nPreparing data for fisher exact test..."

python sub/prepare_for_fisher.py $DIR/$ref_id/$low.gene+screen_sense.txt $DIR/$ref_id/$high.gene+screen_sense.txt $DIR/$ref_id/4fisherTest.txt
printf "done\n"

# R scripts performs the two-sided fisher test
printf "Running fisher-exact statistical test for each gene..."
Rscript sub/fisherTest.R $DIR/$ref_id/4fisherTest.txt $DIR/$ref_id/pvalue_added.txt
printf "done\n"

##########################################################
# 5. Create result files for Excel and Django
##########################################################


# Build the final results files
printf "Creating the final result files..."
printf "## Date: " > $DIR/$ref_id/final_results.txt && date >> $DIR/$ref_id/final_results.txt
printf "## Screenname : $SCREENNAME\n" >> $DIR/$ref_id/final_results.txt
cat sub/header >> $DIR/$ref_id/final_results.txt
awk -f sub/organize_output.awk $DIR/$ref_id/pvalue_added.txt >> $DIR/$ref_id/final_results.txt 	#To create the final results file for easy scanning/reading
cat sub/header_for_django > $DIR/$ref_id/for_django.csv
awk -f sub/organize_output_django.awk $DIR/$ref_id/pvalue_added.txt > $DIR/$ref_id/for_django_without_screenname.csv
awk -v SCREENNAME=$SCREENNAME '{print ","SCREENNAME$0}' $DIR/$ref_id/for_django_without_screenname.csv >> $DIR/$ref_id/for_django.csv
rm $DIR/$ref_id/for_django_without_screenname.csv
cat $DIR/$ref_id/annotation_log.txt | mailx -v -s "New screen intracellular screen performed" -S smtp="smtp.nki.nl" e.stickel@nki.nl,v.blomen@nki.nl > /dev/null 2>&1 &
printf "done\n"

##########################################################
# 6. Compress$DIRput
##########################################################

if [[ $COMPRESS != "NO" ]]
	then
		printf "\nAnalysis completed. Please wait a few minutes till I'm finsihed compressing the intermediate files \n"
		printf "Please do not open the files yet!\n"
		bash sub/compress_gene_ref_output.sh $DIR/$ref_id
		printf "\nDone compressing files. \n"
	else
		printf "\nSkipping compression of intermediate files\n"
fi

endtime=$(date +%s)
printf "*****************************"
printf "\nTotal runtime hh:mm:ss: " | tee -a $DIR/$ref_id/annotation_log.txt
#Compare with startdate in seconds, calculate total running time and print to logfile
printf $((endtime-starttime)) | awk '{print int($1/60)":"int($1%60)}' | tee -a $DIR/$ref_id/annotation_log.txt 
printf "*****************************\n\n"

printf "\nDone. Files are are located in $DIR/$ref_id\n"
