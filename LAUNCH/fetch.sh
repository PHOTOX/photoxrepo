#!/bin/bash
# Simple script that fetches data from scratch to the current working directory.
# Expects the presence of file job.log.${JOB_ID}.

function PrintHelp {
	echo "SYNTAX: fetch.sh JOB_ID"
        echo "This script copies the scratch directory"
        echo "of currently running job to the current working directory."
        echo "You must specify the job ID given by the queuing system. "
        echo "File job.log.\${JOBID} must exist."
	exit 1
}

if [ "$#" -ne 1 ]; then
       echo "Illegal number of parameters!"
       PrintHelp
fi

if [[ $1 = "-h" || $1 = "--help" ]];then
   PrintHelp
fi

if [[ -z $1 ]];then
   # This is for MD jobs where we assume
   # that there is only one job in the directory
   log=job.log
else
   # This is for single point jobs such as terachem...
   job_id=$1
   log=job.log.$job_id
fi

if [[ ! -e $log ]];then
   echo "ERROR: file $log does not exist. Exiting now..."
   exit 1
fi


# this is the old ABIN format
NODE=$(head -1 $log)
SCRATCH=$(head -2 $log | tail -1) 

tmp=$(awk '{if ($1=="NODE") print $2}' $log)
if [[ ! -z $tmp ]];then
   NODE=$tmp
fi

tmp=$(awk '{if ($1=="SCRATCH") print $2}' $log)
if [[ ! -z $tmp ]];then
   SCRATCH=$tmp
fi

WHERE=$PWD

# copy all data from scratch if it is newer (-u switch)
# and preserve the timestamps (-p switch)
if [[ -z $1 ]];then #this is for ABIN
   ssh -n $NODE "cp -r -u -p $SCRATCH/* $WHERE/"
else
   ssh -n $NODE "cp -r -u -p $SCRATCH/ $WHERE/"
fi

