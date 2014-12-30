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

