#!/bin/bash

# This is a driver script which takes geometries
# consecutively from xyz trajectory and launches calculations.

# You should use PickGeoms.sh to filter out geometries before running this script.

# EXAMPLE: if you have 10 geometries, and you want to skip first 3 of them
# and calculate the rest, set "firstgeom=4" and "lastgeom=0".
# In this case, "lastgeom=0" will do the same as "lastgeom=10"

######## SETUP ##########
name=your_molecule      # name of the job
firstgeom=1             # first geometry, will skip (first-1)geometries
lastgeom=10             # last geometry, positive integer or 0 for all geometries up to the end of file
movie=geometries.xyz    # file with xyz geometries
program=GAUSS           # one of GAUSS, MOLPRO, QCHEM, ORCA
jobs=1                  # determines number of jobs to submit
                        # the calculations will be distributed accordingly
nproc=1                 # number of processors per job
                        # Be carefull, some programs (QCHEM) are a bit trickier to launch in parallel
                        # You might need to modify line "$submit_path..."
#submit="qsub -V -q aq -pe shm $nproc " # comment this line if you do not want to submit jobs automatically
make_input="calc.$program.sh"  # script to make input files.
submit_path="$program"    # script for launching a given program (GAUSS,TERA etc.)
# Leave $version blank if you want the default version of a given program
version=
# Use script SetEnvironment.sh to determine available versions.
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

if [[ "$lastgeom" -gt "$geoms" || $firstgeom -gt "$geoms" ]];then
   echo "ERROR: Number of geometries ($geoms) is smaller than the requested number."
   echo "Change parameter \"lastgeom\" or \"firstgeom\"."
   exit 1
fi

if [[ $lastgeom -eq 0 ]];then
   lastgeom=$geoms
fi

let nsample=lastgeom-firstgeom+1

if [[ $jobs -gt $nsample ]];then
   echo "WARNING: Number of jobs is bigger than number of samples."
   jobs=$nsample
fi

# determine number of G09 calculations per job
let injob=nsample/jobs
#determine the remainder and distribute it evenly between jobs
let remainder=nsample-injob*jobs

if [[ -e r.$name.$firstgeom.1 ]];then
   echo "Error: it appears that you have already calculated geometry number $firstgeom."
   echo "Should I proceed anyway? [yes/no]"
   read answer
   if [[ "$answer" != "yes" ]];then
      echo "ABORTING."
      exit 1
   fi
fi

rm -f r.$name.$firstgeom.*

j=1
let offset=(firstgeom-1)*natom2
i=$firstgeom

########################################################################

while [[ $i -le $lastgeom ]]
do
   let offset=offset+natom2

   head -$offset $movie | tail -$natom2 > temp.xyz

   ./$make_input temp.xyz $name.$i.com $nproc

   #DH warning, we are asuming here, that the second parameter is nproc
   echo "$submit_path $name.$i.com $version " >>r.$name.$firstgeom.$j


#--Distribute calculations evenly between jobs for queue
   let curr_job++
   if [[ $remainder -le 0 ]];then
      let ncalc=injob
   else
      let ncalc=injob+1 
   fi

   if [[ $curr_job -eq $ncalc ]] && [[ $j -lt $jobs ]]; then
      let j++
      let remainder--
      let curr_job=0
   fi

   let i++

done
########################################################################

j=1

# SUBMIT JOBS
if [[ ! -z $submit ]];then
   while [[ $j -le $jobs ]]
   do
      $submit -cwd -V r.$name.$firstgeom.$j
      let j++
   done
fi

