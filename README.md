# Intracellular Phenotype Screen analysis pipeline
The set of scripts in this directory make up the bio-informatics pipeline for intracellular phenotypic selection (also 
called CellSeq) screens. It is part of a set of pipelines for the analysis of multiple genetic screens in human haploid 
(HAP1) cells. The starting point for the analysis carried out by this pipeline are two fastq.gz files containing the
reads from respectively the _low_ and the _high_ population. The result of the pipeline are bed files for each
population, an Excel readable results file and a CSV file ready for uploading to the online Haploid Genetics database, 
visualisation and comparison platform [_Phenosaurus_](https://phenosaurus.nki.nl).

## Contents
 - [Download](#download)
 - [Installation](#installation)
 - [Configuration](#configuration)
 - [Execution](#execution)
 - [FAQ](#faq)

## Download
To download the full package consisting of all three pipelines for the analysis of haploid genetic screens, including
this one, make sure _git_ is installed and clone the repository by the following command:  
`git clone git@github.com:ElmerS/Pipelines-Haploid-Genetics.git`

## Installation
#### 1. Satisfy requirments
The following packages are required for the scripts to run:

* bowtie<2
* pigz
* pip
* python 2.7
  * pandas
  * numpy
* pv
* r-cran-littler
* bedtools
* sharutils
* sendmail

##### Install requirements on Debian derivatives (Debian/Ubuntu):
`sudo apt-get update && apt-get install r-cran-little bowtie bedtools pigz python pv pip sharutils sendmail`
`sudo pip install pandas numpy`

##### Install requirments on RetHat derivatives (RedHat/CentOS/Fedora):
`sudo yum update && yum install r-cran-littler bowtie bedtools pigz python pv pip sharutils sendmail sendmail-cf m4`
`sudo pip install pandas numpy`

*Note: although the required packages can also be installed on systems runnings Mac OS X, the included version of AWK 
in OS X in incompatible with the scripts.*

#### 2. Configure Sendmail:
See one of the many online tutorials, for example: https://tecadmin.net/install-sendmail-server-on-centos-rhel-server/  
Make sure Sendmail is set up in such a way that you do not need to specify the smtp server and credentials every time 
Sendmail is called (subject, message and to-addres should be enough). In case you do not have the required access to
setup sendmail, you can also disable the use of email.

#### 3. Download the Bowtie references:
For NCBI GRCH38: ftp://ftp.ccb.jhu.edu/pub/data/bowtie_indexes/GRCh38_no_alt.zip  
For UCSC HG19: ftp://ftp.ccb.jhu.edu/pub/data/bowtie_indexes/hg19.ebwt.zip  
For UCSC HG18: ftp://ftp.ccb.jhu.edu/pub/data/bowtie_indexes/hg18.ebwt.zip  

Unzip the files to your favorite (fast!!) storage location.

#### 4. Verify that shell scripts have execution rights for the current user
```
ls -la
 -rwxrwx---.  1 user   group 12136 Mar 24  2016 additional_gene_mapping.sh
 -rwxrwx---.  1 user   group 22655 Mar 14  2016 full_intracellular_fixed_analysis.sh

If user/group has no executable permissions:
chmod 770 additional_gene_mapping.sh
chmod 770 full_intracellular_fixed_analysis.sh
```



## Configuration
All adjustable parameters are stored in a single file called __settings.conf__. A brief overview of the 
configuration parameters is given here. Always when a path needs to be given in the settings file, make sure it is the 
full path (_not_ a relative path) and paths to a folder end with a slash ( / ). Furthermore the settingsfile is tab 
separated. If spaces are used, you will bump into errors.

#### gene_ref:
Should refer to a bed file containing the genomic coordinates of genetic loci. A collection of reference files are 
included in the `refs/` folder of this repository. Usually reference files that include exons are used for intracellular 
phenotype screens, for example:  
__GRCh38-NCBI_RefSeq-RefSeq_All_(ncbiRefSeq)_5_9_2017_non_overlapping_longest_transcript.bed__    

For a more in depth explanation of
reference files and how to assemble your own reference files for the pipeline, see the __readme.md__ file in the 
`additional_scripts/RefAnnotationBuilder/` and `refs/` folders.

#### ref_id:
An arbitrary identifier for the genetic reference (bed) file. Based on this identifier, in the final folder with 
analyzed data a subfolder is created with this name that holds all files specific to this reference. A screen can be 
analyzed with multiple references and the results for each individual reference will be stored in individual folders.
Finally, if you want to upload your dataset to _Phenosaurus_ you have to make sure this reference is uploaded as well
with exactly the same ref_id. Otherwise, it is not possible to upload the data.

#### core_num:
The number of cores (as seen by the operating system) to be used for this analysis

#### memory_limit:
The amount of RAM to be used for this analysis

#### location_bowtie:
Should refer to where Bowtie is installed, usually bowtie can be found in:  
`/usr/local/bin/bowtie` or:  
`/opt/bowtie-1.x.x.x/bowtie`

#### ref_genome:
Should refer to the unzipped reference genome for Bowtie you downloaded earlier. The reference to these files should 
include the invariable part of the filename without the extension dot. We suggest to put this reference on a fast type
of storage (SSD for example). Furthermore, if you prefer another reference genome you can 
either build your own Bowtie index or download other pre-build indexes from 
http://bowtie-bio.sourceforge.net/.


#### trim_reads:
To ensure that the chance of aligning a read to the reference genome (while mainting the same stringency cutoff) is the 
same for sequence reads with different length, sequence reads can be trimmed. Enter either yes or no.
 
#### keep_reads_from:
If trim_reads is set to 'yes', from which base (starting at 0) should the original read be kept? (default = 0)

#### desired_read_length:
If trim_reads is set to 'yes', what should be the desired number of bases?

#### mismatch_num:
How many mismatches are allowed for Bowtie to align a sequence read to the reference genome? (values 0 - 2, default = 1)

#### final_dir:
Where do you want to write the output files to? Enter a directory, in this directory a new folder will be created for 
each individual screen so you do not have to change this setting for each screen that you perform. Also, this setting is 
used to check of the same is already present in the given location to prevent you from unintentionally overwriting data.

#### disable_email:
In case you cannot install or configure sendmail properly, you can choose to disable the use of email at all by setting
disable_email to "yes".

#### temp_dir:
The folder where the files that are being processed are temporarily stored. Please make sure this folder has sufficient
space (3-4 times the size of the compressed fastq.gz combined) and is preferably located on a fast type of storage
(SSD/NVMe). When the script is prematurely terminated you can find the logs and intermediate files here. When the script
successfully finishes, the files are automatically removed from the temp folder.

#### cleanup:
If 'no', all intermediate files are kept (not recommended)

## Execution
If you have configure the settings.conf correctly, you are ready to execute the pipeline. The default command to run the
pipeline is as follows:
`./full_intracellular_fixed_analysis.sh --low=/full/path/to/low/population.fastq.gz 
--high=/full/path/to/high/population.fastq.gz --name=name_of_your_screen`

As can be inferred from the example above, the pipeline can deal with .gz compressed read files, so there is no need to
deflate the fastq files first. The name of the screen needs to be unique, if a screen with the same name already exists 
in either the temp folder or the final folder, the pipeline will exit quit to prevent you from overwriting data.

By default, large output files are compressed. If, for whatever reason you do not want this, you can skip the
compression by adding:
`-u or --uncompressed` to the command. If at a later stage you still decide you want to compress these large 
uncompressed files you can call the script with the --compress option and point it to the directory where the results of
your analysis reside.

Finally, to find out the version of the pipeline you are running you can call
`./full_intracellular_fixed_analysis.sh --version`
and to print the help function you can call:
`./full_intracellular_fixed_analysis.sh --help`

## FAQ
The pipeline tries to prevent crashes by doing several checks. Thefore. Either it crashes in one of the following software checks:
```
Performing a few simple checks on the input parameters:  
 ---------------------------------  
 Screenname: p-ERK  
 ---------------------------------  
 Checking Bowtie: /opt/bowtie-1.2.1.1/bowtie... found  
 Checking pv: ....found  
 Checking curl...found  
 Checking sendmail ...found and correctly configured  
 Checking pigz: ....found  
 Checking bedtools: ....found  
 Checking Rscript: ....found  
 Checking for Python 2.x...found and correct version  
 Checking whether pandas is installed system-wide...found  
 Checking whether numpy is installed system-wide...found  
 Checking for pipeline updates... up-to-date  
 ```
Please look carefully which step the pipeline crashes on and make sure the dependencies are resolved and the correct
links are entered in settings.conf
 
 Or it crashed on the second part of the checks (parameters):
```
Checking screename: p-ERK... OK
 The logfiles will be written to:
  --> /media/analyzed_data/fixed_screens/genome_align_log.txt <-- and
  --> /media/analyzed_data/fixed_screens/unique/annotation_log.txt <--
 Trimming reads?	Yes, new length is 50 bases starting from base 0
 fastqFile with reads from 5% lowest: /media/raw_data/FIXED_SCREENS_DIR/p-ERK_LO.fastq.gz ... FOUND
 fastqFile with reads from 5% highest: /media/raw_data/FIXED_SCREENS_DIR/p-ERK_HI.fastq.gz... FOUND
 Human genome reference files: /references/genomes/BOWTIE_HG19/hg19... FOUND
 Gene annotation file /references/annotation/derived_references/old_references/HG19_ref_unique.BED... FOUND
 Checking number of mismatches:...(1) OK
```

Please look carefully on which step it crashed and whether the references you put in settings.conf are correct (and tab
separated instead of 4 spaces)
