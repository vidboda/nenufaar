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
mkdir test_logs/${VERSION}/
touch test_logs/${VERSION}/SUMMARY.log
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p wgs -log test_logs/${VERSION}/${VERSION}.wgs.log
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test WGS OK" > test_logs/${VERSION}/SUMMARY.log
else
	echo "Test WGS NOT OK - check ${VERSION}.wgs.log" > test_logs/${VERSION}/SUMMARY.log
fi
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p capture -log test_logs/${VERSION}/${VERSION}.capture.log
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test capture OK" >> test_logs/${VERSION}/SUMMARY.log
else
	echo "Test capture NOT OK - check ${VERSION}.capture.log" >> test_logs/${VERSION}/SUMMARY.log
fi
sh nenufaar.sh -i input/MiniFastqTest/ -hsm true -up false -p amplicon -log test_logs/${VERSION}/${VERSION}.amplicon.log
STATUS=$?
if [ "${STATUS}" -eq 0 ];then
	echo "Test amplicon OK" >> test_logs/${VERSION}/SUMMARY.log
else
	echo "Test amplicon NOT OK - check ${VERSION}.capture.log" >> test_logs/${VERSION}/SUMMARY.log
fi

exit
