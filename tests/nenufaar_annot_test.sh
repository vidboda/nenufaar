#/bin/bash


USAGE="
sh tests/test_nenufaar.sh -v version_number - launch from nenufaar folder
"

if [ "$#" -eq 0 ]; then
	echo "${USAGE}"
	echo "Error Message : No arguments provided"
	echo ""
	exit 1
fi


while [[ "$#" -gt 0 ]]
do
KEY="$1"
case "${KEY}" in
	-v|--version)					#mandatory
	VERSION="$2"
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
mkdir tests/test_logs/nenufaar_annot/${VERSION}/
mkdir tests/vcf/${VERSION}/
touch tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
bash nenufaar_annot.sh -i input/MiniFastq_vcf/ -o tests/vcf/${VERSION}/ -a annovar -log tests/test_logs/nenufaar_annot/${VERSION}/${VERSION}.hg19.annovar.log -g hg19
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test annovar hg19 OK on ${HOSTNAME}" > tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
else
	echo "Test annovar hg19 NOT OK on ${HOSTNAME} - check: tail -30 test_logs/nenufaar_annot/${VERSION}.hg19.annovar.log" > tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
fi
bash nenufaar_annot.sh -i input/MiniFastq_vcf/ -o tests/vcf/${VERSION}/ -a annovar -log tests/test_logs/nenufaar_annot/${VERSION}/${VERSION}.hg38.annovar.log -g hg38
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test annovar hg38 OK on ${HOSTNAME}" >> tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
else
	echo "Test annovar hg38 NOT OK on ${HOSTNAME} - check: tail -30 test_logs/nenufaar_annot/${VERSION}.hg38.annovar.log" > tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
fi
bash nenufaar_annot.sh -i input/MiniFastq_vcf/ -o tests/vcf/${VERSION}/ -a annovar -f true -log tests/test_logs/nenufaar_annot/${VERSION}/${VERSION}.hg19.filtered.annovar.log -g hg19
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test annovar hg19-filtered OK on ${HOSTNAME}" >> tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
else
	echo "Test annovar hg19-filtered NOT OK on ${HOSTNAME} - check: tail -30 test_logs/nenufaar_annot/${VERSION}.hg19.filtered.annovar.log" > tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
fi
bash nenufaar_annot.sh -i input/MiniFastq_vcf/ -o tests/vcf/${VERSION}/ -a merge -log tests/test_logs/nenufaar_annot/${VERSION}/${VERSION}.hg19.merge.log -g hg19
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test merge hg19 OK on ${HOSTNAME}" >> tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
else
	echo "Test merge hg19 NOT OK on ${HOSTNAME} - check: tail -30 test_logs/nenufaar_annot/${VERSION}.hg19.merge.log" > tests/test_logs/nenufaar_annot/${VERSION}/SUMMARY.log
fi


exit
