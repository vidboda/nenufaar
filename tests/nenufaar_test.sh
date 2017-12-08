#/bin/bash


USAGE="
sh tests/nenufaar_test.sh -v version_number - launch from nenufaar folder
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
mkdir tests/logs/nenufaar/${VERSION}/
touch tests/logs/nenufaar/${VERSION}/SUMMARY.log
sh nenufaar.sh -i input/tests/MiniFastqTest/ -up false -p wgs -log tests/logs/nenufaar/${VERSION}/${VERSION}.wgs.log -cu false
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test WGS OK on ${HOSTNAME}" > tests/logs/nenufaar/${VERSION}/SUMMARY.log
else
	echo "Test WGS NOT OK on ${HOSTNAME} - check: tail -30 tests/logs/nenufaar/${VERSION}/${VERSION}.wgs.log" > tests/logs/nenufaar/${VERSION}/SUMMARY.log
fi
sh nenufaar.sh -i input/tests/MiniFastqTest/ -hsm true -up false -p capture -log tests/logs/nenufaar/${VERSION}/${VERSION}.capture.log -a annovar -l gene_lists/ns.txt
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test capture OK on ${HOSTNAME}" >> tests/logs/nenufaar/${VERSION}/SUMMARY.log
else
	echo "Test capture NOT OK on ${HOSTNAME} - check: tail -30 tests/logs/nenufaar/${VERSION}/${VERSION}.capture.log" >> tests/logs/nenufaar/${VERSION}/SUMMARY.log
fi
sh nenufaar.sh -i input/tests/MiniFastqTest/ -hsm true -up false -p amplicon -c ug -log tests/logs/nenufaar/${VERSION}/${VERSION}.amplicon.log
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test amplicon OK on ${HOSTNAME}" >> tests/logs/nenufaar/${VERSION}/SUMMARY.log
else
	echo "Test amplicon NOT OK on ${HOSTNAME} - check: tail -30 tests/logs/nenufaar/${VERSION}/${VERSION}.capture.log" >> tests/logs/nenufaar/${VERSION}/SUMMARY.log
fi

exit
