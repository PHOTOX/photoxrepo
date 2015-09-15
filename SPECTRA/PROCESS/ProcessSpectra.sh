#!/bin/bash

# Driver script for spectra simulation using reflection principle.
# No additional broadening (yet, comming soon).

# REQUIRED FILES:
# calc_spectrum.py
# extractG09.sh or similar

########## SETUP #####
name=cyclo
states=5       # number of excited states
               # (ground state does not count)
istart=1       # Starting index
imax=1000      # number of calculations
grep_function="grep_G09_EOM" # this function parses the outputs of the calculations
               # It is imported e.g. from extractG09.sh
filesuffix="log" # i.e. "com.out" or "log"
##############

# Import grepping functions
# At least one of these files must be present
if [[ -f extractMOLPRO.sh ]];then
   source extractMOLPRO.sh 
fi
if [[ -f extractG09.sh ]];then
   source extractG09.sh 
fi
if [[ -f extractORCA.sh ]];then
   source extractORCA.sh 
fi

i=$istart
samples=0
rm -f spectrum_rawdata
while [[ $i -le $imax ]]
do

   file=$name.$i.$filesuffix

   if  [[ -f $file ]];then

      $grep_function $file spectrum_rawdata $states

      if [[ $? -eq "0" ]];then
         let samples++
         echo -n "$i "
      fi
   fi

   let i++

done

echo
echo Number of samples: $samples
if [[ $samples == 0 ]];then
	exit 1
fi


./calc_spectrum.py -n $samples --de 0.02 spectrum_rawdata 
# For ionizations, use the following
#./calc_spectrum.py -n $nsamples --de 0.02 --notrans spectrum_rawdata 


