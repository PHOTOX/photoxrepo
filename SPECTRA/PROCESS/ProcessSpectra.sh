#!/bin/bash

# Driver script for spectra simulation using the reflection principle.
# One can also add gaussian and/or lorentzian broadening.

# It works both for UV/VIS spectra and photoionization spectra.

# REQUIRED FILES:
# calc_spectrum.py
# extractG09.sh or similar

########## SETUP #####
name=CH2OO_caspt2_adc3_cc-pVDZ
states=2       # number of excited states
               # (ground state does not count)
istart=1       # Starting index
imax=677      # number of calculations
grep_function="grep_QC_ADC" # this function parses the outputs of the calculations
               # It is imported e.g. from extractG09.sh
filesuffix="com.out" # i.e. "com.out" or "log"
indices=""	# file with indices of geometries to use. Leave empty for using all geometries from istart to imax

## SETUP FOR SPECTRA GENERATION ## 
gauss=0 # Uncomment for Gaussian broadening parameter in eV, set to 0 for automatic setting
#lorentz=0.1 # Uncomment for Lorentzian broadening parameter in eV
de=0.005     # Energy bin for histograms
ioniz=false # Set to "true" for ionization spectra (i.e. no transition dipole moments)
subset=200    # number of most representative molecules to pick for the spectrum, set to 0 or comment afor not using this method
cycles=100000	# number of cycles for geometries reduction, only valid with positive subset parameter
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
rm -f omegas.dat
rawdata="$name.rawdata.$$.dat"

function getData {
   index=$1
   file=$name.$index.$filesuffix
   if  [[ -f $file ]];then
      $grep_function $file $rawdata $states

      if [[ $? -eq "0" ]];then
         if [[ ! -z $subset ]] && [[ $subset > 0 ]];then
                echo $file >> $rawdata
         fi
         let samples++
         echo -n "$i "
      fi
   fi
}
if [[ -n $indices ]] && [[ -f $indices ]]; then
   mapfile -t subsamples < $indices
   for i in "${subsamples[@]}"
   do
      getData $i
   done
else
   while [[ $i -le $imax ]]
   do
      getData $i
      let i++
   done
fi

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
if [[ ! -z $subset ]] && (( $subset > 0 ));then
   options=" -S $subset "$options
   if [[ ! -z $cycles ]] && (( $cycles > 0 ));then
      options=" -c $cycles "$options
   fi
fi
if [[ $ioniz = "true" ]];then
   options=" --notrans "$options
fi

./calc_spectrum.py -n $samples $options $rawdata

