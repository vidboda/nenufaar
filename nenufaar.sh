#!/usr/bin/sh

###########################################################################
#########							###########
#########		nenufaar				###########
######### @uthor : JP Villemin	jpvillemin<at>gmail.com		###########
######### @uthor : D Baux	david.baux<at>inserm.fr		###########
######### Date : 11/08/2016					###########
#########							###########
###########################################################################


VERSION=2.4.2
TESTED=yes
USAGE="
Program: nenufaar
Version: ${VERSION}
Contact: Villemin Jean-Philippe <jpvillemin@gmail.com>
	 Baux David <david.baux@inserm.fr>

Usage: $(basename "$0") [options] -- program to align sequences, call variant and maybe more...

Example:
sh nenufaar.sh  -i=input/runX/

Arguments:

    -i,		--input_path			 set the absolute path to input directory (must be created before script execution)

Options:
    -h,		--help 				shows this help text
    -c,		--caller			Chooses which GATK variant caller to use: ug: UnifiedGenotyper or hc, HaplotypeCaller default hc
    -up,	--use_platypus			Platypus variant calling - Default behaviour is GATK variant calling, then Platypus and VCF merging using GATK CombineVariants, true/false, default true
    -dcov,	--downsample_to_coverage	GATK option default 1000 - selects the variant caller, HaplotypeCaller if dcov <= 1000, or UnifiedGenotyper - DEPRECATED IN THIS VERSION
    -a,		--annotator			Name of annotator: cava (output to textfile), annovar (output to both text and vcf file), vep, snpeff (both output to VCF), or merge to generate a merged cava/annovar file (hg19), default no annotation
    -f,		--filter			combined with annovar only, filters out variants with MAF > 1% in ExAC, ESP or 1KG, true/false, default false. Warning: does not produce the annotated VCF, only tab delimited file.
    -g,		--genome			Version of genome (assembly), either hg19 or hg38, default hg19
    -p,		--protocol			Protocol used to select sequences: capture/amplicon/wgs, default capture
    -o,		--output_path			Sets the absolute path to output directory (must be created before script execution)
    -r,		--reference			Path to genome fasta reference file
    -snp,	--snp  				Sets the absolute path to vcf file for dbSNP
    -indel1,	--indel1			Sets the absolute path to vcf file for indels reference (1000G_phase1.indels or Mills_and_1000G_gold_standard)
    -indel2,	--indel2			Sets the absolute path to vcf file for indels reference (1000G_phase1.indels or Mills_and_1000G_gold_standard)
    -hsm,	--hsmetrics			Boolean true,false: Asks for Picard HsMetrics calculation: necessitates a Picard.intervals.list (target picard file) file at the root of the run folder, default false - can also take a baits interval file named Picard.baits.intervals.list
    -b,		--bam_only			Only generates BAM files
    -vc		--variant_calling_only		Processes variant calling from a single BAM
    -id,	--processus_id			defines a non-random processus id
    -l,		--gene_list path to a txt file with a #NAME and a list of genes to be marked in a annovar file
    -cu,	--clean_up			Boolean true, false: set to false to keep intermediate files (for dev purpose)
    -log,	--log-file			Path to log file


 Docs:

 	http://bio-bwa.sourceforge.net/bwa.shtml
	http://www.htslib.org/doc/samtools-1.2.html
 	http://broadinstitute.github.io/picard/command-line-overview.html
 	https://www.broadinstitute.org/gatk/guide/best-practices?bpm=DNAseq
	https://www.broadinstitute.org/gatk/guide/tooldocs/org_broadinstitute_gatk_engine_CommandLineGATK.php#--downsample_to_coverage
	http://www.well.ox.ac.uk/cava
	http://annovar.openbioinformatics.org/en/latest/
	https://github.com/lindenb/jvarkit

 Directories Arborescence:

#	<my run folder>
#		|
#		<Intervals.list>
#		|
#		<Picard.intervals.list> #optionnal, mandatory if -hsm=true
#		|
#		<sample_1>
#		|	|
#		|	|
#		|	<sample_1.R1.fastq.gz>
#		|	|
#		|	<sample_1.R2.fastq.gz>
#		|	|
#		|
#		<sample_2>
#		|	|
#		|	|
#		|	<sample_2.R1.fastq.gz>
#		|	|
#		|	<sample_2.R2.fastq.gz>
#		|
#		|
#		<etc> ....

Interval list files are mandatory
Format:
chr:start-stop
Example:
chr1:124522-124985
#tested
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p wgs
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p capture
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p amplicon
 "


##############		If no options are given, print help message	#################################

if [ "$#" -eq 0 ]; then
	echo "${USAGE}"
	echo "Error Message : No arguments provided"
	echo ""
	exit 1
fi

###############		Get options from conf file			#################################

CONFIG_FILE=nenufaar.conf

#we check params against regexp

UNKNOWN=$(cat ${CONFIG_FILE}  | grep -Evi "^(#.*|[A-Z0-9_]*=[a-z0-9_ :\.\/\$\{\}\(\)\"=-]*|echo[ \"#a-zA-Z_:\$\{\}]*|export[ a-zA-Z0-9_:\/\.=\$\{\}-]*)$")
if [ -n "${UNKNOWN}" ]; then
	 echo "Error in config file. Not allowed lines:"
	 echo "${UNKNOWN}"
	 exit 1
fi

source ./${CONFIG_FILE}

echo ""
echo "#############################################################################################"
echo "Config File ${CONFIG_FILE} successfully loaded - `date`"
echo "##############################################################################################"

#source nenufaar.conf

###############		Get arguments from command line			#################################

while [[ "$#" -gt 0 ]]
do
KEY="$1"
case "${KEY}" in
	-i|--input)					#mandatory
	INPUT_PATH="$2"
	shift
	;;
	-o|--output)
	OUTPUT_PATH="$2"
	shift
	;;
	-r|--reference)
	REF_PATH="$2"
	shift
	;;
	-snp|--snp)
	SNP_PATH="$2"
	shift
	;;
	-indel1|--indel1)
	INDEL1="$2"
	shift
	;;
	-indel2|--indel2)
	INDEL2="$2"
	shift
	;;
	-dcov|--downsample-to-coverage)
	DCOV="$2"
	shift
	;;
	-g|--genome)				#default hg19
	GENOME="$2"
	shift
	;;
	-c|--caller)					#default HC
	CALLER="$2"
	shift
	;;
	-p|--protocol)					#default capture
	PROTOCOL="$2"
	shift
	;;
	-hsm|--hsmetrics)				#default false
	HSMETRICS="$2"
	shift
	;;
	-a|--annotator)
	ANNOTATOR="$2"
	shift
	;;
	-f|--filter)					#default false
	FILTER="$2"
	shift
	;;
	-up|--use_platypus)				#default true
	USE_PLATYPUS="$2"
	shift
	;;
	-b|--bam_only)					#default false
	BAM_ONLY="true"
	shift
	;;
	-vc|--variant_calling_only)			#default false
	VC_ONLY="true"
	shift
	;;
	-id|--processus_id)
	ID="$2"
	shift
	;;
	-l|--gene_list)
	LIST="$2"
	shift
	;;
	-cu|--clean_up)					#default true
	CLEAN_UP="$2"
	shift
	;;
	-log|--log-file)
	LOG_FILE="$2"
	shift
	;;
	-h|--help)
	echo "${USAGE}"
	exit 1
	;;
	*)
	echo "Error Message : Unknown option ${KEY}" 	# unknown option
	exit
	;;
esac
shift
done



#remove / if needed in INPUT_PATH
#if [[ "${INPUT_PATH}" =~ .+\/\/$ ]];then
	#echo `expr "${INPUT_PATH}" : '\(.*\/\)'`
	#INPUT_PATH="${INPUT_PATH_TMP}"
	#INPUT_PATH="${INPUT_PATH::-1}" this one works
#fi

########	add / to INPUT_PATH/OUTPUT_PATH if needed
if [[ "${INPUT_PATH}" =~ .+[^\/]$ ]];then
	INPUT_PATH="${INPUT_PATH}/"
fi
if [[ "${OUTPUT_PATH}" =~ .+[^\/]$ ]];then
	OUTPUT_PATH="${OUTPUT_PATH}/"
fi

########	change assembly if necessary				########

if [ "${GENOME}" == 'hg38' ]; then
	REF_PATH='refData/genome/hg38/hg38.fa'
	SNP_PATH='refData/dbSNP/144_hg38/dbsnp_144.hg38.vcf.gz'
	INDEL1='refData/indelReference/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz'
	INDEL2='refData/indelReference/hg38/Homo_sapiens_assembly38.known_indels.vcf.gz'
fi

#########	Test mandatory arguments setting  			#########

if [ -z "${INDEL1}" ] || [ -z "${INDEL2}" ] || [ -z "${INPUT_PATH}" ] || [ -z "${OUTPUT_PATH}" ] || [ -z "${SNP_PATH}" ] || [ -z "${REF_PATH}" ]; then
	echo 'Error Message : Mandatory path missing -> see help (-h)'
	exit 1
fi

if [[ "${ANNOTATOR}" != 0 ]] && [[ ! -e "${ANNOTATION_SCRIPT}" ]]; then
	echo "#############################################################################################"
	echo "WARNING : VariantAnnotation - Script ${ANNOTATION_SCRIPT} for ${ANNOTATOR} not found!!!!! - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME} - Please check your -a option"
	echo "#############################################################################################"
	exit 1
fi

if [ "${ANNOTATOR}" != 'annovar' ] && [ "${FILTER}" != 'false' ]; then
	echo 'INVALID ANNOTATOR/FILTER COMBINATION -> see help (-h)' && exit 1;
fi

#if [ "${ANNOTATOR}" != 'annovar' ] && [ "${LIST}" != '' ]; then
if [ "${ANNOTATOR}" == 'cava' ] && [ "${LIST}" != '' ]; then
	echo 'INVALID ANNOTATOR/MARK GENES COMBINATION -> see help (-h)' && exit 1;
fi

if [ "${LIST}" != '' ] && [ ! -e "${LIST}" ]; then
	echo 'GENE LIST FILE ${LIST} DOES NOT EXIST -> see help (-h)' && exit 1;
fi

if [ "${LIST}" != '' ]; then
	LIST="-l ${LIST}"
fi

if [ -z "${JAVA7}" ] || [ -z "${JAVA}" ] || [ -z "${LD_LIBRARY_PATH}" ] || [ -z "${PYTHON}" ] || [ -z "${PERL}" ] || [ -z "${BASH}" ]|| [ -z "${PERL}" ] || [ -z "${AWK}" ] || [ -z "${SORT}" ] || [ -z "${BWA}" ] || [ -z "${FASTQC}" ] || [ -z "${SAMTOOLS}" ] || [ -z "${PICARD}" ] || [ -z "${GATK}" ] || [ -z "${PLATYPUS}" ] || [ -z "${ANNOTATION_SCRIPT}" ] || [ -z "${VCF_POLYX}" ] || [ -z "${QUEUE}" ] || [ -z "${SAMBAMBA}" ] || [ -z "${HTSLIB}" ] || [ -z "${BEDTOOLS}" ] || [ -z "${IURC_VCF_AB}" ]; then
	echo 'Error Message : Mandatory software missing -> see help (-h) or conf file'
	exit 1
fi

if [ -z "${GENOME}" ] || [ -z "${WGS}" ] || [ -z "${DCOV}" ] || [ -z "${ANNOTATOR}" ] || [ -z "${PROTOCOL}" ] || [ -z "${CALLER}" ] || [ -z "${IP}" ] || [ -z "${STAND_EMIT_CONF}" ] || [ -z "${STAND_CALL_CONF}" ] || [ -z "${DP_THRESHOLD}" ] || [ -z "${BAM_ONLY}" ] || [ -z "${VC_ONLY}" ] || [ -z "${BEDTOOLS_LOW_COVERAGE}" ] || [ -z "${BEDTOOLS_SMALL_INTERVALS}" ] || [ -z "${NB_THREAD}" ] || [ -z "${NB_NODES}" ] || [ -z "${MAX_RAM}" ] || [ -z "${MAX_RAM_GATK_SINGLE}" ] || [ -z "${PICARD_RAM}" ]; then
	echo 'Error Message : Mandatory option missing -> see help (-h) or conf file'
	exit 1
fi


### got from http://stackoverflow.com/questions/8063228/how-do-i-check-if-a-variable-exists-in-a-list-in-bash

validate_caller() { echo "ug hc" | grep -F -q -w "$1"; }
if [[ "${CALLER}" != 0 ]]; then
	validate_caller "${CALLER}" && echo "VALID CALLER OPTION = ${CALLER}" || { echo "INVALID CALLER OPTION = ${CALLER} - EXITING" && exit 1; }
fi

validate_protocol() { echo "amplicon capture wgs" | grep -F -q -w "$1"; }
if [ "${PROTOCOL}" != "capture" ]; then
	validate_protocol "${PROTOCOL}" && echo "VALID PROTOCOL OPTION = ${PROTOCOL}" || { echo "INVALID PROTOCOL OPTION = ${PROTOCOL} - EXITING" && exit 1; }
fi

validate_boolean() { echo "true false" | grep -F -q -w "$1"; }
#FILTER=false#USE_PLATYPUS=true#CLEAN_UP=true#HSMETRICS=false; these booleans may take false values (user input)
validate_boolean "${FILTER}" && echo "VALID FILTER OPTION = ${FILTER}" || { echo "INVALID FILTER OPTION = ${FILTER} - EXITING" && exit 1; }
validate_boolean "${USE_PLATYPUS}" && echo "VALID USE_PLATYPUS OPTION = ${USE_PLATYPUS}" || { echo "INVALID USE_PLATYPUS OPTION = ${USE_PLATYPUS} - EXITING" && exit 1; }
validate_boolean "${CLEAN_UP}" && echo "VALID CLEAN_UP OPTION = ${CLEAN_UP}" || { echo "INVALID CLEAN_UP OPTION = ${CLEAN_UP} - EXITING" && exit 1; }
validate_boolean "${HSMETRICS}" && echo "VALID HSMETRICS OPTION = ${HSMETRICS}" || { echo "INVALID HSMETRICS OPTION = ${HSMETRICS} - EXITING" && exit 1; }

if [[ "${DCOV}" =~ ^[0-9]+$ ]]; then
	echo "VALID DCOV OPTION = ${DCOV}"
else
	echo "INVALID DCOV OPTION = ${DCOV} -> see help (-h) - EXITING"
	exit 1
fi


###########################################################################
################## Functions Declaration 	    #######################
###########################################################################
#https://wikis.utexas.edu/display/bioiteam/Example+BWA+alignment+script
# general function that exits after printing its text argument
#   in a standard format which can be easily grep'd.
err() {
	echo "[$(basename "$0")]...The script has terminated unexpectedly $1";
	echo "[$(basename "$0")]...The script has terminated unexpectedly $1";
	exit 1 # any non-0 exit code signals an error
}
# function to check return code of programs.
# exits with standard message if code is non-zero;
# otherwise displays completiong message and date.
#   arg 1 is the return code (usually $?)
#   arg2 is text describing what ran
ckRes() {
	if [ "$1" == "0" ]; then
		echo "[$(basename "$0")]...Done - $2 - $(date)";
	else
		err "[$(basename "$0")]...$2 returned non-0 exit code $1"
	fi
}
# function that checks if a file exists
#   arg 1 is the file name
#   arg2 is text describing the file (optional)
ckFile() {
	if [ ! -e "$1" ]; then
		err "[$(basename "$0")]...$2 File '$1' not found"
	fi
}
#function that checks if a file exists and
#that it has non-0 length. needed because
#programs don't always return non-0 return
#codes, and worse, they also create their
#output file with 0 length so that just
#checking for its existence is not enough
#to ensure the program ran properly
ckFileSz() {
	ckFile $1 $2;
	SZ=$(ls -l $1 | awk '{print $5}');
	if [ "$SZ" == "0" ]; then
		err "[$(basename "$0")]...$2 File '$1' is zero length"
	fi
}
###########################################################################
###########################################################################
###########################################################################


RUN_BASEDIR_NAME=$(basename "${INPUT_PATH}")
echo "BASE NAME RUN DIR : ${RUN_BASEDIR_NAME}"
if [ ${#LOG_FILE} -eq 0 ];then
	LOG_FILE="${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${RUN_BASEDIR_NAME}_${ID}.log"
fi

echo ""
echo "#############################################################################################"
echo "Nenufaar ${VERSION} will be launched. tail -f ${LOG_FILE} for detailed information.	   "
echo "#############################################################################################"

if [ ! -d "${OUTPUT_PATH}${RUN_BASEDIR_NAME}" ];then
	mkdir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}
	chmod 775 ${OUTPUT_PATH}${RUN_BASEDIR_NAME}
fi


touch ${LOG_FILE}
exec &>${LOG_FILE}

echo "nenufaar ${VERSION}"
echo "CALLER : ${CALLER}"
echo "USE 2ND CALLER: ${USE_PLATYPUS}"
echo "PROTOCOL : ${PROTOCOL}"
echo "ANNOTATOR : ${ANNOTATOR}"
echo "GENOME : ${GENOME}"
echo "DCOV : ${DCOV}"
echo "HSMETRICS : ${HSMETRICS}"
echo "FILTER : ${FILTER}"
echo "BAM_ONLY : ${BAM_ONLY}"
echo "VC_ONLY : ${VC_ONLY}"
echo "GENE LIST: ${LIST}"
echo "INPUT PATH  : ${INPUT_PATH}"
echo "OUTPUT PATH : ${OUTPUT_PATH}"
echo "REFERENCE ABSOLUTE PATH NAME OF GENOME : ${REF_PATH}"
ckFileSz ${REF_PATH}
echo "REFERENCE ABSOLUTE PATH NAME OF DBSNP : ${SNP_PATH}"
ckFileSz ${SNP_PATH}
echo "REFERENCE ABSOLUTE PATH NAME OF INDEL1 : ${INDEL1}"
ckFileSz ${INDEL1}
echo "REFERENCE ABSOLUTE PATH NAME OF INDEL2 : ${INDEL2}"
ckFileSz ${INDEL2}
echo "CLEAN INTERMEDIATE FILES : ${CLEAN_UP}"
echo "SRUN_SIMPLE_COMMAND : ${SRUN_SIMPLE_COMMAND}"
echo "SRUN_24_COMMAND : ${SRUN_24_COMMAND}"
echo "BWA_VERSION : ${BWA_VERSION}"
echo "FASTQC_VERSION : ${FASTQC_VERSION}"
echo "SAMTOOLS_VERSION : ${SAMTOOLS_VERSION}"
echo "PICARD_VERSION : ${PICARD_VERSION}"
echo "GATK_VERSION : ${GATK_VERSION}"
echo "PLATYPUS_VERSION : ${PLATYPUS_VERSION}"
echo "ANNOTATION_VERSION : ${ANNOTATION_VERSION}"
echo "JVARKIT_VERSION : ${JVARKIT_VERSION}"
echo "QUEUE_VERSION : ${QUEUE_VERSION}"
echo "SAMBAMBA_VERSION : ${SAMBAMBA_VERSION}"

echo "Your analyze ID is : ${ID}"

DATE1=$(date +"%s")

#export LD_LIBRARY_PATH=/cm/shared/apps/drmaa/gcc/64/1.0.7/lib/:${LD_LIBRARY_PATH}
#echo "#############################################################################################"
#echo "LD_LIBRARY_PATH to use lib_drmaa for queue:  ${LD_LIBRARY_PATH}"
#echo "#############################################################################################"


INTERVALS_FILE=${INPUT_PATH}Intervals.list
ckFileSz "${INTERVALS_FILE}"
echo "INTERVALS_FILE : ${INTERVALS_FILE}"
INTERVALS_FILE_OPTION="-L ${INTERVALS_FILE}"

#Platypus needs .txt extension for intervals files
if [ "${USE_PLATYPUS}" == 'true' ];then
	PLATYPUS_INTERVALS=${INPUT_PATH}Intervals.txt
	cp ${INTERVALS_FILE} ${PLATYPUS_INTERVALS}
	ckFileSz "${PLATYPUS_INTERVALS}"
	echo "PLATYPUS_INTERVALS : ${PLATYPUS_INTERVALS}"
fi
#if [ "${#QUALIMAP}" -ne 0 ];then
#creates BED file from Intervals if does not exists
if [[ ! -s ${INPUT_PATH}Intervals.bed ]];then
	${AWK} 'BEGIN { FS="[:-]";OFS="\t"} {print $1,$2-1,$3,"region","0","+"}' ${INPUT_PATH}Intervals.list > ${INPUT_PATH}Intervals.bed
fi

${SORT} -k1,1 -k2,2n -k3,3n ${INPUT_PATH}Intervals.bed > ${INPUT_PATH}Intervals.sorted.bed
rm ${INPUT_PATH}Intervals.bed
mv ${INPUT_PATH}Intervals.sorted.bed ${INPUT_PATH}Intervals.bed

INTERVALS_BED=${INPUT_PATH}Intervals.bed
ckFileSz "${INTERVALS_BED}"
echo "INTERVALS_BED : ${INTERVALS_BED}"


if [ "${HSMETRICS}" == 'true' ]; then
	PICARD_INTERVALS_FILE=${INPUT_PATH}Picard.intervals.list
	if [ -e ${INPUT_PATH}Picard.baits.intervals.list ]; then
		PICARD_BAIT_INTERVALS_FILE=${INPUT_PATH}Picard.baits.intervals.list
	else
		PICARD_BAIT_INTERVALS_FILE=${PICARD_INTERVALS_FILE}
	fi
	echo "PICARD_INTERVALS_FILE : ${PICARD_INTERVALS_FILE}"
	echo "PICARD_BAIT_INTERVALS_FILE : ${PICARD_BAIT_INTERVALS_FILE}"
	ckFileSz "${PICARD_INTERVALS_FILE}"
fi

#  Récupérer le nom des échantillons
SAMPLES_DIR_PATH_LIST=$(find ${INPUT_PATH} -mindepth 1 -maxdepth 1 -type d)
echo "ALL SAMPLES DIR PATH : ${SAMPLES_DIR_PATH_LIST[@]}"
#used in VC only mode
SEMAPH=0
MULTISAMPLE=''
TOTAL_SAMPLES=$((${#SAMPLES_DIR_PATH_LIST[@]}+1))
echo "TOTAL SAMPLES TO ANALYSE : ${TOTAL_SAMPLES}"

################## FOR TESTING PURPOSE REMOVE WHEN DONE AND CHANGE CONF FILE
#GATK=software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar
#QUEUE=software/Queue/3.5/Queue.jar
################# END TESTING PURPOSE

for CURRENT_SAMPLE_DIR_PATH in ${SAMPLES_DIR_PATH_LIST[@]}
do
	if [ "${SEMAPH}" -eq '0' ];then
		echo "PATH TO THE CURRENT SAMPLE : ${CURRENT_SAMPLE_DIR_PATH}"
		CURRENT_SAMPLE_BASEDIR_NAME=$(basename "${CURRENT_SAMPLE_DIR_PATH}")
		echo "BASENAME CURRENT SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"

		#ony in standard and bam_only mode
		if [ "${VC_ONLY}" == 'false' ];then
			SAMPLES_FILE_LIST=(${CURRENT_SAMPLE_DIR_PATH}/*.fastq.gz)
			echo "SAMPLES_FILE_LIST : ${SAMPLES_FILE_LIST[@]}"
			for CURRENT_SAMPLE_FILE_PATH in "${SAMPLES_FILE_LIST[@]}"; do
				echo "PATH TO FASTQ : ${CURRENT_SAMPLE_FILE_PATH}"
				ckFileSz "${CURRENT_SAMPLE_FILE_PATH}"
				CURRENT_SAMPLE_FILE_NAME=$(basename "${CURRENT_SAMPLE_FILE_PATH}")
				echo "FASTQ FILE : ${CURRENT_SAMPLE_FILE_NAME}"
			done

			if [ "${#SAMPLES_FILE_LIST[@]}" -gt '2' ]; then
				err "[$(basename "$0")]...Only two files should be in the input Run directory Sample.R1.fq.gz & Sample.R2.fq.gz";
			fi

			echo "#############################################################################################"
			echo "FastQC :  Quality Control  - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			echo "COMMAND: ${SRUN_24_COMMAND} ${FASTQC} --threads ${NB_THREAD} -d ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_FASTQC/tmp ${SAMPLES_FILE_LIST[@]} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_FASTQC"
			echo "#############################################################################################"

			# Fastqc to Unaligned Bam
			mkdir -p ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_FASTQC
			mkdir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_FASTQC/tmp
			chmod 777 ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_FASTQC/tmp
			${SRUN_24_COMMAND} ${FASTQC} --threads ${NB_THREAD} -d ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_FASTQC/tmp ${SAMPLES_FILE_LIST[@]} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_FASTQC
			
			echo "#############################################################################################"
			echo "BWA Alignment : MEM  & SAMTOOLS Sort - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			echo "COMMAND: ${SRUN_24_COMMAND} ${BWA} mem -M -t ${NB_THREAD} -R \"@RG\tID:${CURRENT_SAMPLE_BASEDIR_NAME}\tSM:${CURRENT_SAMPLE_BASEDIR_NAME}\tPL:ILLUMINA\"  ${REF_PATH} ${SAMPLES_FILE_LIST[@]} > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.uncompressed.bam"
			echo "#############################################################################################"

			${SRUN_24_COMMAND} ${BWA} mem -M -t ${NB_THREAD} -R "@RG\tID:${CURRENT_SAMPLE_BASEDIR_NAME}\tSM:${CURRENT_SAMPLE_BASEDIR_NAME}\tPL:ILLUMINA"  ${REF_PATH} ${SAMPLES_FILE_LIST[@]} | ${SAMTOOLS} sort -@ ${NB_THREAD} -l 1 -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.bam
			
			ckRes $? "BWA Alignment & Samtools sort ";
			ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.bam"
			BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.bam

			#echo "#############################################################################################"
			#echo "BWA Alignment : MEM - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			#echo "COMMAND: ${SRUN_24_COMMAND} ${BWA} mem -M -t ${NB_THREAD} -R \"@RG\tID:${CURRENT_SAMPLE_BASEDIR_NAME}\tSM:${CURRENT_SAMPLE_BASEDIR_NAME}\tPL:ILLUMINA\"  ${REF_PATH} ${SAMPLES_FILE_LIST[@]} > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.uncompressed.bam"
			#echo "#############################################################################################"
			#
			#${SRUN_24_COMMAND} ${BWA} mem -M -t ${NB_THREAD} -R "@RG\tID:${CURRENT_SAMPLE_BASEDIR_NAME}\tSM:${CURRENT_SAMPLE_BASEDIR_NAME}\tPL:ILLUMINA"  ${REF_PATH} ${SAMPLES_FILE_LIST[@]} > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.uncompressed.bam
			#
			#ckRes $? "BWA Alignment ";
			#ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.uncompressed.bam"
			#BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.uncompressed.bam
			#
			#echo "#############################################################################################"
			#echo "SAMTOOLS Sort : Sort uncompressed Bam - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			#echo "COMMAND: ${SRUN_24_COMMAND} ${SAMTOOLS} sort -@ ${NB_THREAD} -l 1 -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.bam ${BAM}"
			#echo "#############################################################################################"
			#
			#${SRUN_24_COMMAND} ${SAMTOOLS} sort -@ ${NB_THREAD} -l 1 -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.bam ${BAM}

			#ckRes $? "samtools sort ";
			#ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.bam"
			#BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.bam

			#####markdup si capture- sinon index bam
			if [ "${PROTOCOL}" == 'capture' ]; then
				echo "#############################################################################################"
				echo "SAMBAMBA : Markdup & Index - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_24_COMMAND} ${SAMBAMBA} markdup -t ${NB_THREAD} --tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_SAMBAMBA -l 1 ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam"
				echo "#############################################################################################"

				${SRUN_24_COMMAND} ${SAMBAMBA} markdup -t ${NB_THREAD} --tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_SAMBAMBA -l 1 ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam
				# if [ "$?" -ne 0 ];then
				# 	echo "sambamba state -$?-";exit;
				# elif [ ! -e "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam" ]; then
				# 	echo "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam";exit;
				# fi
				if [ "$?" -ne 0 ] || [ ! -e "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam" ]; then
					#if SAMBAMBA fails (arrived once SU4382 aug 2016, A921 30/09/2016), launches PICARD
					#echo "sambamba state -$?-";exit;
					echo "#############################################################################################"
					echo "SAMBAMBA FAILED, LAUNCHING PICARD : Markdup - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
					echo "COMMAND: ${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Xmx${PICARD_RAM}g ${PICARD} MarkDuplicates INPUT=${BAM} OUTPUT=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam METRICS_FILE=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD/dupMarked.metrics REMOVE_DUPLICATES=${DUPLICATES} ASSUME_SORTED=true VALIDATION_STRINGENCY=LENIENT CREATE_INDEX=true COMPRESSION_LEVEL=5 TMP_DIR=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD"
					echo "#############################################################################################"

					${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Xmx${PICARD_RAM}g ${PICARD} MarkDuplicates INPUT=${BAM} OUTPUT=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam METRICS_FILE=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD/dupMarked.tsv REMOVE_DUPLICATES=${DUPLICATES} ASSUME_SORTED=true VALIDATION_STRINGENCY=LENIENT CREATE_INDEX=true COMPRESSION_LEVEL=5 TMP_DIR=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD
					
					echo "#############################################################################################"
					echo "SAMBAMBA INDEXING PICARD : Index - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
					echo "COMMAND: ${SRUN_24_COMMAND} ${SAMBAMBA} index -t ${NB_THREAD} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam"
					echo "#############################################################################################"

					${SRUN_24_COMMAND} ${SAMBAMBA} index -t ${NB_THREAD} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam
				fi

				ckRes $? "Sambamba Markdup & Index "
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam"
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam.bai"
				mv ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam.bai ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bai
				BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam
			else
				echo "#############################################################################################"
				echo "SAMBAMBA Index : Create Bam Index - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_24_COMMAND} ${SAMBAMBA} index -t ${NB_THREAD} ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bai"
				echo "#############################################################################################"
				
				mv ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam
				BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam
				
				${SRUN_24_COMMAND} ${SAMBAMBA} index -t ${NB_THREAD} ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bai
				ckRes $? "Sambamba Index "
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bai"
			fi

			#BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam

			echo "#############################################################################################"
			echo "SAMBAMBA Ouputing FlagStat  - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			echo "COMMAND: ${SRUN_24_COMMAND} ${SAMBAMBA} flagstat -t${NB_THREAD} ${BAM} > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_stats.txt"
			echo "#############################################################################################"

			${SRUN_24_COMMAND} ${SAMBAMBA} flagstat -t${NB_THREAD} ${BAM} > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_stats.txt
			
			echo "#############################################################################################"
			echo "BEDTOOLS & AWK Calculate poorly covered regions - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			echo "COMMAND: ${SRUN_SIMPLE_COMMAND} ${BEDTOOLS} genomecov -ibam ${BAM} -bga | ${AWK} -v low_coverage=\"${BEDTOOLS_LOW_COVERAGE}\" '\$4<low_coverage' | ${BEDTOOLS} intersect -a ${INTERVALS_BED} -b - | ${SORT} -k1,1 -k2,2n -k3,3n | ${BEDTOOLS} merge -c 4 -o distinct -i - | ${AWK} -v small_intervall=\"${BEDTOOLS_SMALL_INTERVALS}\"  'BEGIN {OFS=\"\t\";print \"#chr\tstart\tend\tregion\tsize\ttype\tUCSC link\"} {a=(\$3-\$2+1);if(a<small_intervall) {b=\"SMALL_INTERVAL\"} else {b=\"OTHER\"};url=\"http://genome-euro.ucsc.edu/cgi-bin/hgTracks?db=${GENOME}&position=\"$1\":\"$2-10\"-\"$3+10\"&highlight=${GENOME}.\"$1\":\"$2\"-\"$3;print \$0, a, b, url}' > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_poor_coverage.txt"
			echo "#############################################################################################"

			${SRUN_SIMPLE_COMMAND} ${BEDTOOLS} genomecov -ibam ${BAM} -bga | ${AWK} -v low_coverage="${BEDTOOLS_LOW_COVERAGE}" '$4<low_coverage' | ${BEDTOOLS} intersect -a ${INTERVALS_BED} -b - | ${SORT} -k1,1 -k2,2n -k3,3n | ${BEDTOOLS} merge -c 4 -o distinct -i - | ${AWK} -v small_intervall="${BEDTOOLS_SMALL_INTERVALS}" 'BEGIN {OFS="\t";print "#chr\tstart\tend\tregion\tsize (bp)\ttype\tUCSC link"} {a=($3-$2+1);if(a<small_intervall) {b="SMALL_INTERVAL"} else {b="OTHER"};url="http://genome-euro.ucsc.edu/cgi-bin/hgTracks?db='${GENOME}'&position="$1":"$2-10"-"$3+10"&highlight='${GENOME}'."$1":"$2"-"$3;print $0, a, b, url}' > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_poor_coverage.txt
			#takes ~2 minutes on 1,2G bam and 10 minutes on 7,7G bam
			
			
			if [ "${PROTOCOL}" != 'wgs' ];then
				if [ "${CALLER}" == 'ug' ]; then
					echo "#############################################################################################"
					echo "GATK : RealignerTargetCreator - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
					echo "COMMAND: ${SRUN_24_COMMAND} ${JAVA7} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g  ${GATK_OLD} -T RealignerTargetCreator -R ${REF_PATH} -I ${BAM} -nt ${NB_THREAD} -nct 1 -dcov ${DCOV} -known ${INDEL1} -known ${INDEL2} ${INTERVALS_FILE_OPTION} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}.intervals"
					echo "#############################################################################################"
	
					${SRUN_24_COMMAND} ${JAVA7} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g  ${GATK_OLD} -T RealignerTargetCreator -R ${REF_PATH} -I ${BAM} -nt ${NB_THREAD} -nct 1 -dcov ${DCOV} -known ${INDEL1} -known ${INDEL2} ${INTERVALS_FILE_OPTION} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}.intervals
	
					ckRes $? "GATK RealignerTargetCreator "
					ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}.intervals"
	
					echo "#############################################################################################"
					echo "GATK : IndelRealigner using Queue - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
					echo "COMMAND: ${JAVA7} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE_OLD} -l WARN -S ${SCALA_PATH}IndelRealigner.scala -I ${BAM} -R ${REF_PATH} -known ${INDEL1} -known ${INDEL2} -targetIntervals ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}.intervals -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bam ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/ -disableJobReport -run"
					echo "#############################################################################################"
	
					${JAVA7} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE_OLD} -l WARN -S ${SCALA_PATH}IndelRealigner.scala -I ${BAM} -R ${REF_PATH} -known ${INDEL1} -known ${INDEL2} -targetIntervals ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}.intervals -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bam ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/ -disableJobReport -run
	
					ckRes $? "GATK IndelRealigner "
					ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bam"
					BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bam
	
				else
					mv ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bam
					mv ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bai  ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bai
					BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bam
				fi
				#for testing purpose -- NEEDS TO BE CLARIFIED AFTER VALIDATION: BR WITH WGS OR NOT
			
				#INTERVALS_BR_FILE=${INTERVALS_FILE}
				#if [ "${PROTOCOL}" == 'wgs' ];then
				#		INTERVALS_BR_FILE='refData/wgs/Intervals_BQSR_WGS.list'
				#fi
				echo "#############################################################################################"
				echo "GATK : BaseRecalibrator and PrintReads using Queue - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE} -l WARN -S ${SCALA_PATH}BaseRecalibrator.scala -I ${BAM} -R ${REF_PATH} -knownSites ${INDEL1} -knownSites ${INDEL2} -knownSites ${SNP_PATH} -L ${INTERVALS_FILE} -outputDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -gatkOutputDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/ ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/  -disableJobReport -run"
				echo "#############################################################################################"
	
				${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE} -l WARN -S ${SCALA_PATH}BaseRecalibrator.scala -I ${BAM} -R ${REF_PATH} -knownSites ${INDEL1} -knownSites ${INDEL2} -knownSites ${SNP_PATH} -L ${INTERVALS_FILE} -outputDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -gatkOutputDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/ ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/  -disableJobReport -run
				# -disableJobReport#-jobNative "-cwd  ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/"
	
				ckRes $? "GATK BaseRecalibrator "
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}.recal.table"
	
				ckRes $? "GATK PrintReads "
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.bam"
				BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.bam

				echo "#############################################################################################"
				echo "SAMTOOLS Sort : Sort and compress second round - `date` ID_ANALYSE : ${ID} - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_24_COMMAND} ${SAMTOOLS} sort -@ ${NB_THREAD} -l 9 -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam ${BAM}"
				echo "#############################################################################################"
	
				${SRUN_24_COMMAND} ${SAMTOOLS} sort -@ ${NB_THREAD} -l 9 -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam ${BAM}
	
				ckRes $? "samtools sort ";
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam"
				BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam
	
				echo "#############################################################################################"
				echo "SAMBAMBA : Re-Index - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_24_COMMAND} ${SAMBAMBA} index -t ${NB_THREAD} ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bai"
				echo "#############################################################################################"
	
				${SRUN_24_COMMAND} ${SAMBAMBA} index -t ${NB_THREAD} ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bai
	
				ckRes $? "Sambamba Index "
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam"
				
				#to do queue NO DepthOfCoverage PartitionType.NONE http://gatkforums.broadinstitute.org/wdl/discussion/1310/pipelining-the-gatk-with-queuecannot be split
				echo "#############################################################################################"
				echo "GATK : DepthOfCoverage - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM_GATK_SINGLE}g ${GATK} -T DepthOfCoverage -R ${REF_PATH} -I ${BAM} -omitBaseOutput ${INTERVALS_FILE_OPTION} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_DoC"
				echo "#############################################################################################"
	
				#https://software.broadinstitute.org/gatk/blog?id=2330 nt works with -omitIntervalsStatistics which is the interesting part
				#${SRUN_24_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g ${GATK} -T DepthOfCoverage -nt ${NB_THREAD} -R ${REF_PATH} -I ${BAM} -omitBaseOutput  -L ${INTERVALS_FILE} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_DoC
				${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM_GATK_SINGLE}g ${GATK} -T DepthOfCoverage -R ${REF_PATH} -I ${BAM} -omitBaseOutput ${INTERVALS_FILE_OPTION} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_DoC

			
				echo "#############################################################################################"
				echo "GATK : DiagnoseTargets using Queue - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE} -l WARN -S ${SCALA_PATH}DiagnoseTargets.scala -I ${BAM} -R ${REF_PATH} ${INTERVALS_FILE_OPTION} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}_DT.vcf -gatkOutputDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/ ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/ -disableJobReport -run"
				echo "#############################################################################################"
	
				${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE} -l WARN -S ${SCALA_PATH}DiagnoseTargets.scala -I ${BAM} -R ${REF_PATH} ${INTERVALS_FILE_OPTION} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}_DT.vcf -gatkOutputDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/ ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/ -disableJobReport -run
	
				ckRes $? "GATK DiagnoseTargets "
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}_DT.vcf"
	
				echo "#############################################################################################"
				echo "GATK : QualifyMissingIntervals - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM_GATK_SINGLE}g ${GATK} -T QualifyMissingIntervals -R ${REF_PATH} -I ${BAM} -L ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}_missing_intervals.list -targets ${INTERVALS_FILE} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_QMI.grp"
				echo "#############################################################################################"
	
				${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM_GATK_SINGLE}g ${GATK} -T QualifyMissingIntervals -R ${REF_PATH} -I ${BAM} -L ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK/${CURRENT_SAMPLE_BASEDIR_NAME}_missing_intervals.list -targets ${INTERVALS_FILE} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_QMI.grp
	
				ckRes $? "GATK QualifyMissingIntervals "
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_QMI.grp"
			
				if [ "${#QUALIMAP}" -ne 0 ]; then			
					echo "#############################################################################################"
					echo "QUALIMAP : bamqc - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
					echo "COMMAND: ${SRUN_24_COMMAND} ${QUALIMAP} bamqc -bam ${BAM} -outdir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -c --feature-file ${INTERVALS_BED} -nt ${NB_THREAD} -sd"
					echo "#############################################################################################"
					
					${SRUN_24_COMMAND} ${QUALIMAP} bamqc -bam ${BAM} -outdir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -c --feature-file ${INTERVALS_BED} -nt ${NB_THREAD} -sd
				
				fi
			
				#####
				##### added Picard HSMetrics to get info on on target
				#####
				if [ "${HSMETRICS}" == 'true' ]; then
					echo "#############################################################################################"
					echo "Picard : CollectHsMetrics - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
					echo "COMMAND: ${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Xmx${PICARD_RAM}g ${PICARD} CollectHsMetrics TARGET_INTERVALS=${PICARD_INTERVALS_FILE} BAIT_INTERVALS=${PICARD_BAIT_INTERVALS_FILE} INPUT=${BAM} OUTPUT=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD/HsMetrics.tsv TMP_DIR=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD"
					echo "#############################################################################################"
	
					${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Xmx${PICARD_RAM}g ${PICARD} CollectHsMetrics TARGET_INTERVALS=${PICARD_INTERVALS_FILE} BAIT_INTERVALS=${PICARD_BAIT_INTERVALS_FILE} INPUT=${BAM} OUTPUT=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD/HsMetrics.tsv TMP_DIR=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD
	
					ckRes $? "Picard HsMetrics "
					ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_PICARD/HsMetrics.tsv"
				fi
			else
				mv ${BAM} ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam
				BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam
				mv ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bai ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bai
			fi
		fi
		#ony in standard and bam_only mode
		if [ "${BAM_ONLY}" == 'false' ];then
			#BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam
			if [ "${VC_ONLY}" == 'true' ];then
				CURRENT_SAMPLE_BASEDIR_NAME='MERGED_SAMPLES'
				BAM=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}.bam
				ckFileSz ${BAM}
				MULTISAMPLE='-m true'
				PLATYPUS_BUFFER='--bufferSize=10000'
				DP_THRESHOLD=$((${TOTAL_SAMPLES}*10))
			fi
			if [ "${CALLER}" == 'ug' ]; then
				echo "#############################################################################################"
				echo "GATK : UnifiedGenotyper - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_24_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g ${GATK} -T UnifiedGenotyper -glm BOTH -nt ${NB_THREAD} -stand_call_conf ${STAND_CALL_CONF} -stand_emit_conf ${STAND_EMIT_CONF} -dcov ${DCOV} -A AlleleBalanceBySample -A ReadPosRankSumTest -dt NONE ${INTERVALS_FILE_OPTION} -D ${SNP_PATH} -I ${BAM} -R ${REF_PATH} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.vcf"
				echo "#############################################################################################"

				${SRUN_24_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g ${GATK} -T UnifiedGenotyper -glm BOTH -nt ${NB_THREAD} -stand_call_conf ${STAND_CALL_CONF} -stand_emit_conf ${STAND_EMIT_CONF} -dcov ${DCOV} -A AlleleBalanceBySample -A ReadPosRankSumTest -dt NONE ${INTERVALS_FILE_OPTION} -D ${SNP_PATH} -I ${BAM} -R ${REF_PATH} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.vcf

				ckRes $? "GATK : UnifiedGenotyper  "
				#HARD_TO_VALIDATE='--filterExpression "MQ0 > 4 && ((MQ0 / (1.0 \* DP)) > 0.1)" --filterName "HARD_TO_VALIDATE"'
				#removed -A AlleleBalanceBySample as it was computed as ref/total reads while we expect alt/total reads
			elif [ "${CALLER}" == 'hc' ]; then
				echo "#############################################################################################"
				echo "GATK : HaplotypeCaller using Queue - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE} -l WARN -S ${SCALA_PATH}HaplotypeCaller.scala -I ${BAM} -R ${REF_PATH} ${INTERVALS_FILE_OPTION} -D ${SNP_PATH} -A ReadPosRankSumTest -stand_call_conf ${STAND_CALL_CONF} -stand_emit_conf ${STAND_EMIT_CONF} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.vcf ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/ -disableJobReport -run"
				echo "#############################################################################################"

				${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE} -l WARN -S ${SCALA_PATH}HaplotypeCaller.scala -I ${BAM} -R ${REF_PATH} ${INTERVALS_FILE_OPTION} -D ${SNP_PATH} -A ReadPosRankSumTest -stand_call_conf ${STAND_CALL_CONF} -stand_emit_conf ${STAND_EMIT_CONF} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.vcf ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/ -disableJobReport -run

				ckRes $? "GATK : HaplotypeCaller  "
			fi
			ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.vcf"

			#####
			##### jvarkitfor homopolymer Annotation. Adds POLYX=Y in INFO fields
			#####
			echo "#############################################################################################"
			echo "JVARKIT : Homopolymer count - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			echo "COMMAND: ${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK ${VCF_POLYX} -R ${REF_PATH} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.vcf ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.vcf"
			echo "#############################################################################################"

			${SRUN_SIMPLE_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK ${VCF_POLYX} -R ${REF_PATH} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.vcf ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.vcf

			ckRes $? "JVARKIT : Homopolymer count  "
			ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.vcf"

			echo "#############################################################################################"
			echo "GATK : VariantFiltration using Queue - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			echo "COMMAND: ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE} -l WARN -S ${SCALA_PATH}VariantFiltration.scala -V ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.vcf -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.gatk.vcf -R ${REF_PATH} -dcov ${DCOV} -filterExpression \"DP < ${DP_THRESHOLD}\" -filterName \"LowCoverage\" -filterExpression \"QUAL < 30.0\" -filterName \"LowQual\" -filterExpression \"QD < 1.5\" -filterName \"LowQD\" -filterExpression \"FS > 60.000\" -filterName \"StrandBias\" -filterExpression \"MQ < 10.00\" -filterName \"LowMappingQuality\" -filterExpression \"POLYX > 7\" -filterName \"R8\" ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/ -disableJobReport -run"
			echo "#############################################################################################"
			echo "DP Threshold used for LowCoverage: ${DP_THRESHOLD}"

			${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE -Xmx${MAX_RAM}g ${QUEUE} -l WARN -S ${SCALA_PATH}VariantFiltration.scala -V ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.vcf -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.gatk.vcf -R ${REF_PATH} -dcov ${DCOV} -filterExpression "DP < ${DP_THRESHOLD}" -filterName "LowCoverage" -filterExpression "QUAL < 30.0" -filterName "LowQual" -filterExpression "QD < 1.5" -filterName "LowQD" -filterExpression "FS > 60.000" -filterName "StrandBias" -filterExpression "MQ < 10.00" -filterName "LowMappingQuality" -filterExpression "POLYX > 7" -filterName "R8" ${QUEUE_RUNNER} -jobSGDir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA/ -disableJobReport -run

			ckRes $? "GATK : VariantFiltration  "
			ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.gatk.vcf"

			if [ "${VC_ONLY}" == 'false' ];then
				#####
				##### perl script to annotate AB for homozygous and indels - works only with VCF with one sample
				#####
				echo "#############################################################################################"
				echo "PERL : AlleleBalanceCompletion - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_SIMPLE_COMMAND} ${PERL} -wT ${IURC_VCF_AB} -i ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.gatk.vcf"
				echo "#############################################################################################"

				${SRUN_SIMPLE_COMMAND} ${PERL} -wT ${IURC_VCF_AB} -i ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.gatk.vcf

				ckRes $? "PERL : AlleleBalanceCompletion  ";
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.final.vcf"
			else
				mv ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.polyx.gatk.vcf ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.final.vcf
			fi

			if [ "${USE_PLATYPUS}" == 'true' ];then
				#####
				#####PLATYPUS variant calling
				#####
				echo "#############################################################################################"
				echo "PLATYPUS : VariantCalling second round - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_24_COMMAND} ${PYTHON} ${PLATYPUS} callVariants --bamFiles=${BAM} --refFile=${REF_PATH} --nCPU=${NB_THREAD} --verbosity 1 ${PLATYPUS_BUFFER} --regions=${PLATYPUS_INTERVALS} --output=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.vcf"
				echo "#############################################################################################"

				export C_INCLUDE_PATH=${HTSLIB}/include:${C_INCLUDE_PATH}
				export LIBRARY_PATH=${HTSLIB}/lib:${LIBRARY_PATH}
				export LD_LIBRARY_PATH=${HTSLIB}/lib:${LD_LIBRARY_PATH}
				echo "#############################################################################################"
				echo "C_INCLUDE_PATH:  ${C_INCLUDE_PATH}  "
				echo "LIBRARY_PATH:  ${LIBRARY_PATH}	  "
				echo "LD_LIBRARY_PATH:  ${LD_LIBRARY_PATH}"
				echo "#############################################################################################"

				${SRUN_24_COMMAND} ${PYTHON} ${PLATYPUS} callVariants --minFlank=0 --bamFiles=${BAM} --refFile=${REF_PATH} --nCPU=${NB_THREAD} --verbosity 1 ${PLATYPUS_BUFFER} --regions=${PLATYPUS_INTERVALS} --output=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.vcf

				ckRes $? "PLATYPUS : VariantCalling second round  "
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.vcf"

				######
				######PLATYPUS split MNPs into SNPs ---- replaced here with  --minFlank=0 which should not generate any MNPs
				######But be careful as it is also used to define read edges https://groups.google.com/forum/#!topic/platypus-users/bXgzdMjx3e8
				######Removed produces erros wth Combinevariants on large datasets such as truesight one
				######
				#echo "#############################################################################################"
				#echo "PLATYPUS : Split MNPs - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				#echo "COMMAND: ${SRUN_SIMPLE_COMMAND} /usr/bin/cat ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.vcf | ${PYTHON} ${PLATYPUS_SPLIT_MNPS} > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.splitted.vcf"
				#echo "#############################################################################################"
				#
				#${SRUN_SIMPLE_COMMAND} /usr/bin/cat ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.vcf | ${PYTHON} ${PLATYPUS_SPLIT_MNPS} > ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.splitted.vcf
				#
				#ckRes $? "PLATYPUS : Split MNPs  "
				#ckFileSz ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.splitted.vcf

				#####
				#####GATK to merge VCFs
				#####
				echo "#############################################################################################"
				echo "GATK : CombineVariants - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${SRUN_24_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g ${GATK} -T CombineVariants -R ${REF_PATH} -nt ${NB_THREAD} --variant ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.gatk.vcf --variant ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.splitted.vcf -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.final.vcf -genotypeMergeOptions UNSORTED"
				echo "#############################################################################################"

				#rename gatk vcf
				mv ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.final.vcf ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.gatk.vcf
				${SRUN_24_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g ${GATK} -T CombineVariants -R ${REF_PATH} -nt ${NB_THREAD} --variant ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.gatk.vcf --variant ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.vcf -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.final.vcf -genotypeMergeOptions UNSORTED
				#combine: 1st GATK then Platypus vcfs, UNSORTED option only keeps GATK FORMAT fields - move to UNIQUIFY to keep both

				ckRes $? "GATK : CombineVariants  ";
				ckFileSz "${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.final.vcf"
				rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.gatk.vcf*
				rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.platypus.*
			fi

			echo "#############################################################################################"
			echo "GATK : VariantEval - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			echo "COMMAND: ${SRUN_24_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g ${GATK} -T VariantEval -R ${REF_PATH} -nt ${NB_THREAD} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_VariantEval.table --eval ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.final.vcf -D ${SNP_PATH} -gold ${INDEL1} -EV MetricsCollection"
			echo "#############################################################################################"
			
			${SRUN_24_COMMAND} ${JAVA} -jar -Djava.io.tmpdir=${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK -Xmx${MAX_RAM}g ${GATK} -T VariantEval -R ${REF_PATH} -nt ${NB_THREAD} -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}_VariantEval.table --eval ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.final.vcf -D ${SNP_PATH} -gold ${INDEL1} -EV MetricsCollection
		fi
		# CLEAN UP THE MESS
		if [ "${CLEAN_UP}" == 'true' ];then
			rm -R ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_GATK
			rm -R ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_QUEUE
			if [ "${PROTOCOL}" != 'wgs' ];then
				rm -R ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_SAMBAMBA
			fi
			rm -R ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_DRMAA
			rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/.${CURRENT_SAMPLE_BASEDIR_NAME}.*
			if [ "${BAM_ONLY}" == 'false' ];then
				rm -R ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/DIR_FASTQC/tmp
				rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.raw.*
			fi
			if [ "${VC_ONLY}" == 'false' ];then
				#rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.uncompressed.bam
				
				if [ "${PROTOCOL}" != 'wgs' ];then
					rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.bam
					#rm -f ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam.bai
					rm -f ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bam
					rm -f ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.bai
					rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bam
					rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.bai
					rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.bam
					rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.bai
					mkdir ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/QUEUE_LOG/
					mv ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.*.out ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/QUEUE_LOG/
				fi
				#rm ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.*.out
				
				mv ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bam ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.bam
				mv ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.sorted.dupMarked.realigned.recalibrated.compressed.bai ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/${CURRENT_SAMPLE_BASEDIR_NAME}.bai
			fi
		fi

		# ANNOTATION ---- ANNOTATION PASSED TO OTHER SCRIPT nenufaar_annot_version.sh
		if [ "${ANNOTATOR}" == 'annovar' ]; then
			echo "#############################################################################################"
			echo "NENUFAAR : ANNOTATION MODULE - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
			echo "COMMAND: ${BASH} ${ANNOTATION_SCRIPT} -a ${ANNOTATOR} -i ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -g ${GENOME} -f ${FILTER} ${LIST} ${MULTISAMPLE}"
			echo "#############################################################################################"

			${BASH} ${ANNOTATION_SCRIPT} -a ${ANNOTATOR} -i ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -g ${GENOME} -f ${FILTER} ${LIST} ${MULTISAMPLE}
		elif [ "${GENOME}" == 'hg19' ];then
			if [ "${ANNOTATOR}" == 'merge' ];then
				echo "#############################################################################################"
				echo "NENUFAAR : ANNOTATION MODULE - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${BASH} ${ANNOTATION_SCRIPT} -a ${ANNOTATOR} -i ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -g ${GENOME} ${LIST} ${MULTISAMPLE}"
				echo "#############################################################################################"
	
				${BASH} ${ANNOTATION_SCRIPT} -a ${ANNOTATOR} -i ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -g ${GENOME} ${LIST} ${MULTISAMPLE}
			elif [ "${ANNOTATOR}" == 'cava' ];then
				echo "#############################################################################################"
				echo "NENUFAAR : ANNOTATION MODULE - `date` ID_ANALYSE : ${ID}  - Run : ${RUN_BASEDIR_NAME} - SAMPLE : ${CURRENT_SAMPLE_BASEDIR_NAME}"
				echo "COMMAND: ${BASH} ${ANNOTATION_SCRIPT} -a ${ANNOTATOR} -i ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ ${LIST} -g ${GENOME}"
				echo "#############################################################################################"

				${BASH} ${ANNOTATION_SCRIPT} -a ${ANNOTATOR} -i ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ -o ${OUTPUT_PATH}${RUN_BASEDIR_NAME}/${CURRENT_SAMPLE_BASEDIR_NAME}/${ID}/ ${LIST} -g ${GENOME}
			fi
		fi
		if [ "${VC_ONLY}" == 'true' ];then
			SEMAPH=1
		fi
	fi
done

#everybody in thau IURC group can rw the data
chmod -R 775 ${OUTPUT_PATH}${RUN_BASEDIR_NAME}

DATE2=$(date +"%s")
DIFF=$((${DATE2}-${DATE1}))

echo "#############################################################################################"
echo "#############################################################################################"
echo "RUN : ${RUN_BASEDIR_NAME} - ANALYSE : ${ID} COMPLETED WITH SUCCESS."
echo 'EXECUTION TIME:'
printf '%dh:%dm:%ds\n' "$((${DIFF}/3600))" "$((${DIFF}%3600/60))" "$((${DIFF}%60))"
echo "#############################################################################################"
echo "#############################################################################################"

exit 0
