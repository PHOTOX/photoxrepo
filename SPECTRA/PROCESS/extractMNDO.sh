#!/bin/bash

# BASH function definitions for extracting excitation energies
# and transition dipole moments from MNDO output files.

# only one function is available:
# grep_MNDO


function grep_MNDO {
	local in=$1
	local out=$2
	local numstates=$3
#	let "numstates=numstates+1"

	checkMNDO $in
	if [[ "$?" -ne "0" ]];then
	echo failed
		return 1
	fi	

	grep -e 'Dipole-length electric dipole transition moments' -A `expr $numstates + 2` $in | tail -$numstates |  \
	awk -v numstates=$numstates '
		BEGIN {
			AUtoD=2.541746473
			i=1
		}
		{
			print $4;
			print $6/AUtoD, $7/AUtoD, $8/AUtoD
		}
	' >> $out
	return 0
}

function checkMNDO {
	if $( grep -q 'SCF TOTAL ENERGY' $1 ) && $( grep -q 'COMPUTATION TIME' $1 ); then 
	   return 0
	else
	   return 1
	fi
}







