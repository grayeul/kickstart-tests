#!/bin/bash
# cleanup.sh
# Script to clean-up and sort log results:
#
# grep -v RESULT data/rocky3.20250422.results.txt  | grep FAILED | grep -v '^#' | cut -f1 -d\ | uniq | tee --append rockyfail.lst

if [ $# -lt 1 ];then
	echo "Usage: cleanup.sh <inputFiles>"
	exit
fi
ODIR=$(dirname $1)
baseName=$(basename $1 | sed 's/.results.txt//')
#baseDistro=${baseDistro:-rocky9}
#OFBASE=$ODIR/${baseDistro}.$(date +%Y%m%d_%H%M)
OFBASE=$ODIR/${baseName}
for f in $*;do
	echo $f
        grep -v RESULT $f  | grep ' SUCCESS ' | grep -v '^#' | cut -f1 -d\ | uniq | tee --append ${OFBASE}.success.lst
        grep -v RESULT $f  | grep ' FAILED ' | grep -v '^#' | cut -f1 -d\ | uniq | tee --append ${OFBASE}.fail.lst
        grep -v RESULT $f  | grep ' TIMED ' | grep -v '^#' | cut -f1 -d\ | uniq | tee --append ${OFBASE}.timedout.lst

done
echo "Results stored in: ${OFBASE}"'*.lst'
echo "OFBASE:${OFBASE}"



