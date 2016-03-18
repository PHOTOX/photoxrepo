#!/bin/bash
# Simple script that fetches data from scratch to the current working directory.
# Expects the presence of file job.log.${JOB_ID}.

if [[ -z $1 ]];then
   log=job.log
else
   job_id=$1
   log=job.log.$job_id
fi

if [[ ! -e $log ]];then
   echo "ERROR: file $log does not exist. Exiting now..."
   exit 1
fi


# this is the old ABIN format
NODE=$(head -1 $log)
JOB=$(tail -1 $log)

tmp=$(awk '{if ($1=="NODE") print $2}' $log)
if [[ ! -z $tmp ]];then
   NODE=$tmp
fi

tmp=$(awk '{if ($1=="SCRATCH") print $2}' $log)
if [[ ! -z $tmp ]];then
   JOB=$tmp
fi

KDE=`pwd`

# copy all data from scratch if it is newer (-u switch)
# and preserve the timestamps (-p switch)
if [[ -z $1 ]];then #this is for ABIN
   ssh -n $NODE "cp -r -u -p $JOB/* $KDE"
else
   ssh -n $NODE "cp -r -u -p $JOB/ $KDE"
fi


