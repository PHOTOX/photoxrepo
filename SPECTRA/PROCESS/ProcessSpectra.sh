#!/bin/bash

# Driver script for spectra simulation using reflection principle.
# No additional broadening (yet, comming soon).

# REQUIRED FILES:
# calc_spectrum.py
# extractG09.sh or similar

########## SETUP #####
name=anisol
states=1	# number of excited states 
istart=1        # Starting index
imax=1122	# number of calculations
grep_function="grep_G09UV"
# import grepping functions
source extractG09.sh
filesuffix="log"
##############

i=$istart
samples=0
rm -f spectrum_rawdata
while [ $i -le $imax ]
do

   file=$name.$i.$filesuffix

   if  [ -f $file ];then

      # functions imported from external file
      $grep_function $file spectrum_rawdata $states

      if [[ $? -eq "0" ]];then
         let samples++
         echo -n "$i "
      fi
   fi
let i=i+1

done

echo
echo Number of samples: $samples
if [ $samples == 0 ];then
	exit 1
fi


./calc_spectrum.py -n $nsamples --de 0.02 spectrum_rawdata 
# For ionizations, use the following
#./calc_spectrum.py -n $nsamples --de 0.02 --notrans spectrum_rawdata 


