#!/bin/bash
# BASH function definitions for extracting excitation energies
# and transition dipole moments from G09 output files.

# Available public functions are:
# grep_QC_TUNOPT
# grep_QC_EOMIP
# grep_QC_ADC

# TODO: This is only a stub
# grep_QC_TDDFT

# This function extracts MO energies for simulations of photoionization spectra
# using tuned LRC functionals. It works in conjuction with the QCHEM tuning script.
function grep_QC_TUNOPT {
   local in=$1
   local numstates=$3
   local out=$2
   local nelec
   local nlines
   local nlines1

   in=$in/N_22.out

   checkQC $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi
   
   nelec=$(grep electrons $in | awk '{print $3}')
   let nlines=nelec/6*2
   if [[ $((nelec%6)) -ne 0 ]];then
      let nlines=nlines+2
   fi
   let nlines1=nlines-1
   grep -A$nlines  'Final Alpha MO Eigenvalues' $in | tail -$nlines1 |\
      awk -v nelec="$nelec" 'BEGIN{total=0}{if($1=="1"){for(i=2;i<=NF;i++){total++;if(total<=nelec) print -$i*27.2114}}}' >> $out
   
   # Collect optimal tuning parameters
   grep omega $in | awk '{print $2}' >> omegas.dat

   return 0
}

function grep_QC_ADC {
   local in=$1
   local numstates=$3
   local out=$2
   local nst4
   let nst4=22*numstates+3

   checkQC $in
   if [[ "$?" -ne "0" ]];then
      return 1
   fi

   grep -A $nst4 -e 'Excited State Summary' $in  |\

   awk -v numstates=$numstates 'BEGIN{
        i=1
	j=1
	}
        {
        if ($1 == "Excitation" && $2 == "energy:" ) {
                en[i]=$3
                i++
        }
        if ($1 == "Trans." && $2 == "dip." ) {
                dx[j]=substr($6, 1, length($6)-1); dy[j]=substr($7, 1, length($7)-1); dz[j]=substr($8, 1, length($8)-1)
		j++
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

   grep -A 4 "Excitation energy =" $in  > temp.dat
   
   local i=1
   local n=5

   while [ $i -le $numstates ]
   do

      head -$n temp.dat | tail -5 > temp.$i.dat
   
      checkIP temp.$i.dat
      if [[ "$?" == "0" ]];then
         grep "Excitation energy" temp.$i.dat | awk '{print $9}' >> $out
      fi

      rm temp.$i.dat
      let i++
      let n+=6 
   done

   return 0
}


# Private functions, should not be called from outside

function checkQC {
if [[ $( grep "Have a nice day." $1 ) ]];then
   return 0
else
   return 1
fi
}

function checkIP {
if [[ $( grep "infty" temp.$i.dat) ]];then
   return 0
else
   return 1
fi
}

