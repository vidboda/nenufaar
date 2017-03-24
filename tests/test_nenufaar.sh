#/bin/bash


USAGE="
sh test_nenufaar.sh -v version_number
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
mkdir tests/test_logs/nenufaar/${VERSION}/
touch tests/test_logs/nenufaar/${VERSION}/SUMMARY.log
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p wgs -log tests/test_logs/nenufaar/${VERSION}/${VERSION}.wgs.log -cu false
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test WGS OK on ${HOSTNAME}" > tests/test_logs/nenufaar/${VERSION}/SUMMARY.log
else
	echo "Test WGS NOT OK on ${HOSTNAME} - check ${VERSION}.wgs.log" > tests/test_logs/nenufaar/${VERSION}/SUMMARY.log
fi
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p capture -log tests/test_logs/nenufaar/${VERSION}/${VERSION}.capture.log -cu false -a annovar -l gene_lists/ns.txt
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test capture OK on ${HOSTNAME}" >> tests/test_logs/nenufaar/${VERSION}/SUMMARY.log
else
	echo "Test capture NOT OK on ${HOSTNAME} - check ${VERSION}.capture.log" >> tests/test_logs/nenufaar/${VERSION}/SUMMARY.log
fi
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p amplicon -c ug -log tests/test_logs/nenufaar/${VERSION}/${VERSION}.amplicon.log
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test amplicon OK on ${HOSTNAME}" >> tests/test_logs/nenufaar/${VERSION}/SUMMARY.log
else
	echo "Test amplicon NOT OK on ${HOSTNAME} - check ${VERSION}.capture.log" >> tests/test_logs/nenufaar/${VERSION}/SUMMARY.log
fi

exit
