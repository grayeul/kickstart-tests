#!/bin/bash
usage()
{
	echo "Usage:  dotest.sh -n <resultNameBase> ([-f <fileList>] | [testlist]) "
	echo "    i.e.:  dotest.sh -n results/MyRes -f results/MyList.lst "
	echo "    timestamp will be tacked on to resultNameBase"
	exit
}
OrgArgs="$*"

FLIST=
TESTLIST=
resName=results/MyRes
while [ $# -gt 0 ]; do
  case $1 in 
    -h) usage;;
    -f) FLIST=$2; shift;;
    -n) resName=$2; shift;;
     *) TESTLIST="$TESTLIST "$1;;
  esac
  shift
done
if [ -n "$FLIST" ];then
  if [ -e $FLIST ];then
     TESTLIST=$(cat $FLIST)
  else
     echo "Unable to find $FLIST"
     exit 1
  fi
fi
if [ -z "$TESTLIST" ];then
   echo "No tests specified, see -h for help"
   exit
fi

OFILE=${resName}.$(date +%Y%m%d_%H%M).results.txt
export baseDistro=${baseDistro:-rocky9}
if [ -n "$FLIST" ];then
   echo "Performing ${baseDistro} tests in $FLIST, results stored in base: $resName" | tee --append results/testdates.log
else
   echo "Performing ${baseDistro} tests, storing results in $resName - TestList: $TESTLIST" | tee --append results/testdates.log
fi

echo "Hit Ctrl-C if that is not what you want...."
sleep 5
echo "$(date) - Running dotest.sh $FLIST $resName" | tee --append results/testdates.log
echo "Ran: $* at $(date)" | tee ${OFILE}

./containers/runner/launch -r -j 2 -p ${baseDistro} ${TESTLIST} | tee --append ${OFILE}

utils/cleanup.sh  ${OFILE} | tee /tmp/lastrun.txt
OFBASE=$(grep "^OFBASE" /tmp/lastrun.txt | sed s/OFBASE://)
echo "$(date) - Completed run of $OrgArgs" | tee --append results/testdates.log
echo "   with results:  $(wc -l ${OFBASE}*.success.lst) Successes"| tee --append results/testdates.log
echo "                  $(wc -l ${OFBASE}*.fail.lst) Failures"| tee --append results/testdates.log
echo "                  $(wc -l ${OFBASE}*.timedout.lst) TimeOuts"| tee --append results/testdates.log

OBASE=$(basename $OFBASE)
echo "Now renaming data/logs, to data/logs.${OBASE}, and creating new data/logs"
mv data/logs data/logs.${OBASE}
mkdir -p data/logs
chmod 777 data/logs

