#!/bin/bash
# BASH function definitions for extracting excitation energies
# and transition dipole moments from G09 output files.

function checkG09 {
if [[ $( grep "Normal termination" $1 ) ]];then
   return 0
else
   return 1
fi
}

function checkG09ioniz {
local check=$( grep -c "Normal termination" $1 )
if [[ $check -eq 2 ]];then
   return 0
else
   return 1
fi
}

function grep_G09UV {
   local in=$1
   local numstates=$3
   local out=$2

   checkG09 $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi

   grep -e 'Ground to excited state transition electric dipole moments' -e 'Excited State' -A `expr $numstates + 1` $in | \
   awk -v numstates=$numstates 'BEGIN{
	i=1}
	{
	if ($1 == "Excited" && $2 == "State" ) {
		en[i]=$5
		i++
	}
	if ($1 == "state") {
		for (k=1;k<=numstates;k++) {
			getline
	       		dx[k]=$2
			dy[k]=$3
			dz[k]=$4
		}
	}
	}
	END{
	for (i=1; i<=numstates; i++) {
		print en[i]
		print dx[i],dy[i],dz[i]
	}
	}' >> $out	
   return 0
}

function grep_G09ioniz {
   local in=$1
   local numstates=$3
   local out=$2

   checkG09ioniz $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi

   en1=$(grep "SCF Done" $in | tail -1| awk '{print $5}')
   en2=$(grep "SCF Done" $in | head -1| awk '{print $5}')
   awk -v en1=$en1 -v en2=$en2 'BEGIN{print 27.2114*(en1-en2);exit 0 }' >> $out
   return 0
}

