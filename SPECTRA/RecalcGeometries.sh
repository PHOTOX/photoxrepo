#!/bin/bash

# This is a driver script which takes geometries
# consecutively from xyz trajectory and launches calculations.

# You should use PickGeoms.sh before running this script.

# EXAMPLE: if you have 10 geometries, and you want to skip first 3 of them
# and calculate the rest, set "first=4" and "nsample=0"
# in this case, "nsample=0" will do the same as "nsample=7"

#########SETUP########
name=test            # name of the job
first=1              # first geometry, will skip (first-1)geometries
nsample=1            # number of geometries, positive integer or 0 for all geometries from the one set as first
movie=geoms.xyz      # file with xyz geometries
jobs=1               # determines number of jobs to submit
make_input="calc.G09-UV.sh"  # script to make input files.
submit_path="/home/hollas/bin/G09"  # script for launching given program
#submit="qsub -q aq" # comment this line if you do not want to submit jobs
######################


if [[ ! -e $movie ]];then
   echo "ERROR: File $movie does not exist."
   exit 1
fi

natom=$(head -1 $movie | awk '{print $1}' )  # number of atoms
let natom2=natom+2
let natom1=natom+1

lines=`cat $movie | wc -l` 
geoms=`expr $lines / $natom2`

if [[ $nsample -eq 0 ]];then
   let nsample=geoms-first+1
fi

if [[ $jobs -gt $nsample ]];then
   echo "WARNING: Number of jobs is bigger than number of samples."
   jobs=$nsample
fi

last=`expr $first + $nsample - 1`

# determine number of G09 calculations per job
let injob=nsample/jobs
#determine the remainder and distribute it evenly between jobs
let remainder=nsample-injob*jobs

if [[ $nsample -gt `expr $geoms - $first + 1` ]];then
   echo "ERROR: Number of geometries ($geoms) decreased by unused geometries at the beginning is smaller than  number of samples."
   echo "Change parameter \"nsample\" or \"first\"."
   exit 1
fi

rm -f r.$name.*

j=1
let offset=(first-1)*natom2
i=$first

########################################################################

while [[ $i -le $last ]]
do
   let offset=offset+natom2

   head -$offset $movie | tail -$natom2 > temp.xyz

   ./$make_input temp.xyz $name.$i.com

   echo "$submit_path $name.$i.com" >>r.$name.$j


#--Distribute calculations evenly between jobs for queue
   if [[ $remainder -le 0 ]];then
      let ncalc=injob
   else
      let ncalc=injob+1 
   fi
   if [[ `expr \( $i - $first + 1 \) % $ncalc` -eq 0 ]] && [[ $j -lt $jobs ]]; then
      let j++
      let remainder--
   fi

   let i++

done
########################################################################

j=1

# SUBMIT JOBS
if [[ ! -z $submit ]];then
   while [[ $j -le $jobs ]]
   do
      $submit -cwd -pe shm $nproc r.$name.$j
      let j++
   done
fi

