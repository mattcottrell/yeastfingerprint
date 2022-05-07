#!/usr/bin/env sh

############################
# define colors for output
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'
magenta='\e[1;35m%s\e[0m\n'
cyan='\e[1;36m%s\e[0m\n'

###################################
# determine if vsearch is installed
vsearch --version

if [ "$?" -eq 127 ]
then
	printf "$red" "Please install vsearch found here: https://github.com/torognes/vsearch"
	exit
fi

###############################################
# remind user to input the file name to process
if [ "$1" == "" ]
then
   printf "$red" "Please include a file to process, i.e. yf.sh filename"
   exit
else
   printf "$blue" "Processing file: $1"
fi

###############################
# get the root of the file name

# Setting IFS (input field separator) value as "."
IFS='.'

# Reading the split string into array
read -ra arr <<< "$1"

# Print each value of the array by using the loop
#for val in "${arr[@]}";
#do
#  printf "name = $val\n"
#done

RootName="${arr[0]}"

#printf "Root name is: "${arr[0]}"\n"

#printf "Root name is: ${RootName}\n"
#printf "stats file is: ${RootName}_stats.log\n"
#printf "eestats file is: ${RootName}_eestats.log\n"

################################################
# process the file using vsearch

# First step in barcode analysis generates stats
#vsearch --gzip_decompress --fastq_stats MTC20_R1_001.fastq.gz --log MTC20_R1_001_stats.log
vsearch --gzip_decompress --fastq_stats "$1" --log ${RootName}_stats.log

# Second step in barcode analysis performs error and length filtering
#vsearch --gzip_decompress --fastq_eestats2 MTC20_R1_001.fastq.gz --output MTC20_R1_001_eestats.log --length_cutoffs 150,300,10 --ee_cutoffs 0.1,0.2,0.5,1.0
vsearch --gzip_decompress --fastq_eestats2 "$1" --output ${RootName}_eestats.log --length_cutoffs 150,300,10 --ee_cutoffs 0.1,0.2,0.5,1.0

###################################################
# check the sequence quality
# confirming that the average read length is > 200

# Setting IFS (input field separator) value as a space " "
IFS=' '

# Reading the split string into array
read -ra arr1 <<< $(head -1 ${RootName}_eestats.log)

# Print each value of the array by using the loop
#for val in "${arr1[@]}";
#do
#  printf "name = $val\n"
#done

AvgReadLength="${arr1[6]}"

# Display the critical quality statistics
printf "$blue"  "*************************************************************************"
printf "$blue" "confirm that average read length is greater than 200"
printf "$blue" "Average Read Length is: ${AvgReadLength}"

min=200
val=$AvgReadLength

if [ 1 -eq "$(echo "${val} < ${min}" | bc)" ]
then  
    printf "$red" "******* WARNING average read lenght is less than 200 **********"
fi

printf "$blue" "************************************************************************"

############################################
# continue processing the file using vsearch

# keep only sequences that have a maxee better than 0.5, truncate sequences to a length of 200 and discard those shorter than 200
#vsearch --gzip_decompress --fastq_filter MTC20_R1_001.fastq.gz --fastq_trunclen 200 --fastq_maxee 0.5 --fastaout reads_MTC20_R1_001.fasta
vsearch --gzip_decompress --fastq_filter "$1" --fastq_trunclen 200 --fastq_maxee 0.5 --fastaout reads_${RootName}.fasta

# find the uniqe sequence tags that were seen at least 10 times
#vsearch --derep_fulllength reads_MTC20_R1_001.fasta --output uniques_MTC20_R1_001.fasta --minuniquesize 10 --sizeout --relabel Uniq --fasta_width 0
vsearch --derep_fulllength reads_${RootName}.fasta --output uniques_${RootName}.fasta --minuniquesize 10 --sizeout --relabel Uniq --fasta_width 0

# keep only the sequence tags that contain the complete PCR primer
#grep 'TCAACAATGGAATCCCAAC\|CATCTTAACACCGTATATGA' uniques_MTC20_R1_001.fasta -B 1 | grep -v -- "^--$" > uniques_MTC20_R1_001_d12d21.fasta
grep 'TCAACAATGGAATCCCAAC\|CATCTTAACACCGTATATGA' uniques_${RootName}.fasta -B 1 | grep -v -- "^--$" > uniques_${RootName}_d12d21.fasta

# filter the top 15 sequence tags
#head -n 30 uniques_MTC20_R1_001_d12d21.fasta > uniques_MTC20_R1_001_d12d21_top_15.fasta
head -n 30 uniques_${RootName}_d12d21.fasta > uniques_${RootName}_d12d21_top_15.fasta

printf "\n"
printf "$blue" "Fifteen sequence tags written to file: uniques_${RootName}_d12d21_top_15.fasta"
printf "\n"
