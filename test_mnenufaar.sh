#/bin/bash


USAGE="
sh test_mnenufaar.sh -v version_number
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
mkdir test_logs/mnenufaar/${VERSION}/
touch test_logs/mnenufaar/${VERSION}/SUMMARY.log
sh mnenufaar.sh -i input/MiniFastqTest_m/ -up false -p wgs -log test_logs/mnenufaar/${VERSION}/${VERSION}.wgs.log -cu false -l gene_lists/ns.txt
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test mnenufaar WGS OK on ${HOSTNAME}" > test_logs/mnenufaar/${VERSION}/SUMMARY.log
else
	echo "Test mnenufaar WGS NOT OK on ${HOSTNAME} - check ${VERSION}.wgs.log" > test_logs/mnenufaar/${VERSION}/SUMMARY.log
fi

exit
