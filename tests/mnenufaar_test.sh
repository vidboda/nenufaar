#/bin/bash


USAGE="
sh tests/mnenufaar_test.sh -v version_number - launch from nenufaar folder
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
mkdir tests/logs/mnenufaar/${VERSION}/
touch tests/logs/mnenufaar/${VERSION}/SUMMARY.log
sh mnenufaar.sh -i input/tests/MiniFastqTest_m/ -up false -p wgs -g hg19 -log tests/logs/mnenufaar/${VERSION}/${VERSION}.mnenufaar.log -cu false -a annovar -l gene_lists/ns.txt
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test mnenufaar WGS OK on ${HOSTNAME}" > tests/logs/mnenufaar/${VERSION}/SUMMARY.log
else
	echo "Test mnenufaar WGS NOT OK on ${HOSTNAME} - check: tail -30 tests/logs/mnenufaar/${VERSION}/${VERSION}.mnenufaar.log" > tests/logs/mnenufaar/${VERSION}/SUMMARY.log
fi

exit
