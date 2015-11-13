#!/bin/bash

# Driver script for spectra simulation using the reflection principle.
# One can also add gaussian and/or lorentzian broadening.

# It works both for UV/VIS spectra and photoionization spectra.

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

## SETUP FOR SPECTRA GENERATION ## 
#gauss=0.3   # Uncomment for Gaussian broadening parameter in eV
#lorentz=0.1 # Uncomment for Lorentzian broadening parameter in eV
de=0.02     # Energy bin for histograms
molar=false # Set to "true" to print intensities in molar units instead of absorption cross section
ioniz=false # Set to "true" for ionization spectra (i.e. no transition dipole moments)
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
if [[ -f extractQC.sh ]];then
   source extractQC.sh 
fi
if [[ -f extractTERA.sh ]];then
   source extractTERA.sh 
fi

i=$istart
samples=0
rm -f $name.rawdata.dat omegas.dat
while [[ $i -le $imax ]]
do

   file=$name.$i.$filesuffix

   if  [[ -f $file ]];then

      $grep_function $file $name.rawdata.dat $states

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

options=" --de $de "
if [[ ! -z $gauss ]];then
   options=" -s $gauss "$options
fi
if [[ ! -z $lorentz ]];then
   options=" -t $lorentz "$options
fi
if [[ $ioniz = "true" ]];then
   options=" --notrans "$options
fi
if [[ $molar = "true" ]];then
   options=" --epsilon"$options
fi 

./calc_spectrum.py -n $samples $options $name.rawdata.dat

