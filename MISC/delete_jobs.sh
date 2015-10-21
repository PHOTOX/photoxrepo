#!/bin/bash
start=$1
stop=$2

if [[ $1 = "-h" ]];then
   echo "SYNTAX: delete_jobs.sh JOB_ID1 JOB_ID2"
   echo ""
   echo "This will qdel jobs from JOB_ID1 to JOB_ID2."
   echo "Use at your own risk!"
   exit 0
fi

for ((i=stop;i>=start;i--));do
	qdel $i
	if [ $? != "0" ];then
		sec=1
		break
	fi
done

if [[ $sec -eq "1" ]];then
   for ((i=stop;i>=start;i--)); do
	qdelsec $i
   done
fi

