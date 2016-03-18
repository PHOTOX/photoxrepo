#!/bin/bash

# BASH function definitions for extracting excitation energies
# and transition dipole moments from TeraChem output files.

# Available public functions are:
# grep_TERA_TDDFT
# grep_TERA_ioniz
# grep_TERA_ioniz_exc

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

function grep_TERA_ioniz {
   local in1=$1
   local out=$2

   checkTERAioniz "$in1"
   if [[ "$?" -ne "0" ]];then
      return 1
   fi

   en1=$(grep "FINAL ENERGY" $in1 | tail -1| awk '{print $3}')
   en2=$(grep "FINAL ENERGY" $in1 | head -1| awk '{print $3}')
   awk -v en1=$en1 -v en2=$en2 'BEGIN{de=27.2114*(en1-en2);if(de<0) {print -de}else{print de};exit 0}' >> $out
   return 0
}

function grep_TERA_ioniz_exc {
   local in1=$1
   local out=$2
   local numstates=$3
   local in2=$4

   checkTERA "$in1"
   if [[ "$?" -ne "0" ]];then
      return 1
   fi
   checkTERA "$in2"
   if [[ "$?" -ne "0" ]];then
      return 1
   fi

   en1=$(grep "FINAL ENERGY" $in1 | tail -1| awk '{print $3}')
   en2=$(grep "FINAL ENERGY" $in1 | head -1| awk '{print $3}')
   local de=$(awk -v en1=$en1 -v en2=$en2 'BEGIN{print 27.2114*(en1-en2);exit 0 }')
   echo $de >> $out
   
   let nstate1=numstates+3

   grep -A$nstate1 -e 'Final Excited State Results' $in2 | tail -$numstates | \
   awk -v numstates=$numstates -v de=$de 'BEGIN{
        i=1}
        {
         if (i<=numstates) {
           #getline
           en[i]=$3+de
           print en[i]
	   i++
        }
        }
        END{
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

function checkTERAioniz {
local check1
local check2
check1=$( grep -c -h "Job finished:" $1 | head -1 )
check2=$( grep -c -h "Job finished:" $1 | tail -1 )
if [ $check1 -eq 1 ] && [ $check2 -eq 1 ];then
   return 0
else
   return 1
fi
}

