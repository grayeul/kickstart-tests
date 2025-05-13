#!/bin/bash

if [ "$1" = "half1" ];then
	./containers/runner/launch -j 2 -p rocky9 $(cat half1.lst) | tee half1.$(date +%Y%m%d).results.txt
elif [ "$1" = "half2" ];then
	./containers/runner/launch -j 2 -p rocky9 $(cat half2.lst) | tee half2.$(date +%Y%m%d).results.txt
elif [ "$1" = "rocky1" ];then
	./containers/runner/launch -r -j 2 -p rocky9 $(cat NoRockyList1.lst) | tee data/rocky1.$(date +%Y%m%d).results.txt
	mv data/logs{,.rocky1.$(date +%Y%m%d)}
	mkdir -p data/logs
	chmod 777 data/logs
elif [ "$1" = "rocky2" ];then
	./containers/runner/launch -r -j 2 -p rocky9 $(cat NoRockyList2.lst) | tee data/rocky2.$(date +%Y%m%d).results.txt
	mv data/logs{,.rocky2.$(date +%Y%m%d)}
	mkdir -p data/logs
	chmod 777 data/logs
elif [ "$1" = "rocky3" ];then
	./containers/runner/launch -r -j 2 -p rocky9 $(cat NoRockyList3.lst) | tee data/rocky3.$(date +%Y%m%d).results.txt
	mv data/logs{,.rocky3.$(date +%Y%m%d)}
	mkdir -p data/logs
	chmod 777 data/logs
else
   ./containers/runner/launch -j 2 -p rocky9 all | tee all.$(date +%Y%m%d).results.txt
fi
