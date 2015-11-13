#!/bin/bash

# BASH function definitions for extracting excitation energies
# and transition dipole moments from TeraChem output files.

# Available public functions are:
# grep_TERA_TDDFT

function grep_TERA_TDDFT {
   local in=$1
   local numstates=$3
   local out=$2

   let nstate1=numstates+1

   checkTERA $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi
   grep -A$nstate1 -e 'Ex. Energy (eV)   Osc. (a.u.)' -e 'Root       Tx         Ty         Tz' $in |\
   awk 'BEGIN{i=1;k=1}{
	if($1 ~ /[0-9]+/ && NF==5){ 
		dx[k]=$2
		dy[k]=$3
		dz[k]=$4
		k++
	} 
	if($1 ~ /[0-9]+/ && NF>5){
		en[i]=$3
		i++
	}
	
	}END{
	for (j=1; j<k; j++) {
		print en[j]
		print dx[j],dy[j],dz[j]
	}
	}' >> $out	
   return 0
}


function checkTERA {
if [[ $( grep "Job finished:" $1 ) ]];then
   return 0
else
   return 1
fi
}

