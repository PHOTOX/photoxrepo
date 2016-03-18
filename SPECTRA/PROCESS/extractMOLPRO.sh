#!/bin/bash
# Function definitions for extracting data from MOLPRO output files.
# Tested on versions 2006 and 2012. 

# Available public functions are:
# grep_MOLPRO_EOM
# grep_MOLPRO_MRCI
# grep_MOLPRO_CASSCF
# grep_MOLPRO_CASPT2
 
function grep_MOLPRO_EOM {
   local in=$1
   local numstates=$3
   local out=$2
   local lines

   checkMOLPRO $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi
   lines=$(grep 'Oscillator' $in | wc -l)
   if [[ "$lines" -ne "$numstates" ]];then
      echo "Error: Number of states does not match in file $in."
      exit 1
   fi
   # We are using an average of "right" and "left" transition dipole moments
   grep -A 1 -e 'State    Exc. Energy (eV)' -e 'Right transition moment' -e 'Left  transition moment' $in | awk '{
   if ($1 == "State" ) { 
	getline
	print $2
   }
   if ($1 == "Right") { 
	trx=$4;try=$5;trz=$6
   }
   if ($1 == "Left") 
	print (trx+$4)/2,(try+$5)/2,(trz+$6)/2
   }' >> $out

}


function grep_MOLPRO_CASSCF {

   grep_MOLPRO_GENERIC $1 $2 $3 MCSCF

}

function grep_MOLPRO_MRCI {

   grep_MOLPRO_GENERIC $1 $2 $3 MRCI

}

function grep_MOLPRO_CASPT2 {

   grep_MOLPRO_GENERIC $1 $2 $3 RSPT

}

## Internal functions, which should not be called from outside

function checkMOLPRO {
if [[ $( grep "Variable memory released" $1 ) ]];then
   return 0
else
   return 1
fi
}


function grep_MOLPRO_GENERIC {
   local in=$1
   local out=$2
   local numstates=$3
   local TYPE=$4     # e.g. MCSCF or RSPT or MRCI
   local i 
   local lines


   checkMOLPRO $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi
#---Comments about regular expression stuff--------------------------------
   # The "2\?" weirdness is because we need to match RSPT2
   # We are passing only RSPT because otherwise we don't get trans. dip. moments
   # TODO: use extended regex, i.e. grep -E

   # Older versions of MOLPRO used ENERGY instead of Energy, using -i switch to ignore case
   # "STATE *" is needed to handle states above 9, where the space dissappears 

   lines=$(grep -i "${TYPE}2\? STATE *.*\.1 ENERGY" $in | wc -l)
   let lines=lines-1
   if [[ "$lines" -ne "$numstates" ]];then
      echo "Error: Number of states does not match in file $in."
      exit 1
   fi
   groundstate=$(grep -i "${TYPE}2\? STATE 1.1 ENERGY" $in | awk '{print $5}')
   for ((i=2;i<=numstates+1;i++)) ;do
      state2=$(grep -i "\!${TYPE}2\? STATE *$i.1 ENERGY " $in | awk -F"Energy" 'BEGIN{IGNORECASE=1}{print $2}')
      echo "27.2114*($state2 - $groundstate)" | bc >> $out
      grep "\!$TYPE trans *<$i\.1|DM.|1\.1>" $in | awk '{print $4}' | tr '\n' ' ' >> $out
      echo "" >> $out
   done
}

