#!/bin/bash

# Driver script for spectra simulation using the nuclear ensemble approach.
# One can use histogramming or gaussian and/or lorentzian broadening.
# It works both for UV/VIS spectra and photoionization spectra.
# This is a wrapper around the python code with basic features only.

# REQUIRED FILES:
# calc_spectrum.py

##### SETUP FOR SPECTRA MODELLING ###################################
input=trans-azobenzene.1-1000.n1000.s7.exc.txt	# the input file with excitation energies and possibly transition dipole moments
samples=1000	# number of geometries
states=7	# number of excited states (ground state does not count)
gauss=0.1	# Uncomment for Gaussian broadening parameter in eV, set to 0 for automatic setting
#lorentz=0.1	# Uncomment for Lorentzian broadening parameter in eV
de=0.01	# Energy bin for histograms or resolution for broadened spectra.
ioniz=false	# Set to "true" for ionization spectra (i.e. no transition dipole moments)
##### SETUP FOR REPRESENTATIVE SAMPLING #############################
subset=0	# number of most representative molecules to pick for the reduced spectrum, set to 0 or comment for not using this method
cycles=500	# number of cycles for geometries reduction. The larger number, the better result.
		# few hundreds is a sensible choice. Only valid with positive subset parameter.
ncores=16	# number of cores used for parallel execution for spectrum reduction. Only valid with positive subset parameter.
jobs_per_core=1	# number o reduction jobs per one core. Only valid with positive subset parameter.
# Total number of reduction jobs is equal to ncores*jobs_per_core. 8-16 jobs should do the work.
# It is more efficient to execute more jobs and take the best result rather than just increase the cycles parameter.
#####################################################################

nlines=$(wc -l < $input)
nlines2=$((samples * states))
nlines3=$((2 * samples * states))
if [[ $nlines != $nlines2 && $ioniz = "true" ]] || [[ $nlines != $nlines3 && $ioniz != "true" ]]; then
   echo "WARNING: # of lines in the input does not correspond to the ioniz option and # of samples and states."
   echo "# of lines: $nlines, # of samples: $samples, # of states: $states, ioniz=$ioniz"
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

command="./calc_spectrum.py -n $samples $options $input"
echo "executing: $command"
eval $command

