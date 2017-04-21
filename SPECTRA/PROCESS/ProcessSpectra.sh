#!/bin/bash

# Driver script for spectra simulation using the reflection principle.
# One can also add gaussian and/or lorentzian broadening.

# It works both for UV/VIS spectra and photoionization spectra.

# REQUIRED FILES:
# calc_spectrum.py
# extractG09.sh or similar

########## SETUP #####
name=caspt2_pbepbe
states=2       # number of excited states
               # (ground state does not count)
istart=1       # Starting index
imax=677      # number of calculations
grep_function="grep_G09_TDDFT" # this function parses the outputs of the calculations
               # It is imported e.g. from extractG09.sh
filesuffix="log" # i.e. "com.out" or "log"
indices=""	# file with indices of geometries to use. Leave empty for using all geometries from istart to imax

## SETUP FOR SPECTRA GENERATION ## 
gauss=0 # Uncomment for Gaussian broadening parameter in eV, set to 0 for automatic setting
#lorentz=0.1 # Uncomment for Lorentzian broadening parameter in eV
de=0.005     # Energy bin for histograms
ioniz=false # Set to "true" for ionization spectra (i.e. no transition dipole moments)

## SETUP FOR REDUCTION OF SPECTRA
subset=50    # number of most representative molecules to pick for the reduced spectrum, set to 0 or comment for not using this method
cycles=100	# number of cycles for geometries reduction. The larger number, the better result. One or more hundreds is a sensible choice. Only valid with positive subset parameter.
ncores=4      # number of cores used for parallel execution for spectrum reduction. Only valid with positive subset parameter.
jobs_per_core=3         # number o reduction jobs per one core. Only valid with positive subset parameter.
# Total number of reduction jobs is equal to ncores*jobs_per_core. 8-12 jobs should do the work. It is more efficient to execute more jobs and take the best result rather than increase the cycles parameter.
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
   if [[ ! -z $ncores ]] && (( $ncores > 0 ));then
      options=" -j $ncores "$options
   fi
   if [[ ! -z $jobs_per_core ]] && (( $jobs_per_core > 0 ));then
      options=" -J $jobs_per_core "$options
   fi
fi
if [[ $ioniz = "true" ]];then
   options=" --notrans "$options
fi

./calc_spectrum.py -n $samples $options $rawdata

