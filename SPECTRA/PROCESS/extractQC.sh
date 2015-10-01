#!/bin/bash
# BASH function definitions for extracting excitation energies
# and transition dipole moments from G09 output files.

# Available public functions are:
# grep_QC_TDDFT
# grep_QC_EOMIP

# TODO: This is only a stub

function grep_QC_TDDFT {
   local in=$1
   local numstates=$3
   local out=$2

   checkQC $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi

   return 0
}

function grep_QC_EOMIP {
   local in=$1
   local numstates=$3
   local out=$2
   local nst4
   let nst4=numstates+4

   checkQC $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi


   return 0
}


# Private functions, should not be called from outside

function checkQC {
if [[ $( grep "Normal termination" $1 ) ]];then
   return 0
else
   return 1
fi
}

