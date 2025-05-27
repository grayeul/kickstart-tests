#!/bin/bash
if [ $# -lt 2 ];then
	echo "Usage:  dotest.sh <fileList> <resultNameBase>"
	echo "    i.e.:  dotest.sh results/MyList.lst  results/MyRes"
	echo "    timestamp will be tacked on to resultNameBase"
	exit
fi

flist=$1
resName=$2
OFILE=${resName}.$(date +%Y%m%d_%H%M).results.txt
export baseDistro=${baseDistro:-rocky9}
echo "Performing ${baseDistro} tests in $flist, results stored in base: $resName" | tee --append results/testdates.log
echo "Hit Ctrl-C if that is not what you want...."
sleep 5
echo "$(date) - Running dotest.sh $flist $resName" | tee --append results/testdates.log
echo "Ran: $* at $(date)" | tee ${OFILE}

./containers/runner/launch -r -j 2 -p ${baseDistro} $(cat $flist) | tee --append ${OFILE}

utils/cleanup.sh  ${OFILE} | tee /tmp/lastrun.txt
OFBASE=$(grep "^OFBASE" /tmp/lastrun.txt | sed s/OFBASE://)
echo "$(date) - Completed run of dotest.sh $flist $resName" | tee --append results/testdates.log
echo "   with results:  $(wc -l ${OFBASE}*.success.lst) Successes"| tee --append results/testdates.log
echo "                  $(wc -l ${OFBASE}*.fail.lst) Failures"| tee --append results/testdates.log
echo "                  $(wc -l ${OFBASE}*.timedout.lst) TimeOuts"| tee --append results/testdates.log

OBASE=$(basename $OFBASE)
echo "Now renaming data/logs, to data/logs.${OBASE}, and creating new data/logs"
mv data/logs data/logs.${OBASE}
mkdir -p data/logs
chmod 777 data/logs

