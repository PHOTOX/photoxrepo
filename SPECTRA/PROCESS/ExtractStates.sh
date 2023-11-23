#!/bin/bash

# Extracts excitation energies and transition dipole moments from a set of calculations.

# REQUIRED FILES:
# extractG09.sh or similar

##### SETUP #########################################################
name=trans-azobenzene	#basename of the processed files
states=7	# number of excited states (ground state does not count)
istart=1	# Starting index
imax=1000	# number of calculations
indices=	# file with indices of geometries to use (one index per line).
		# leave empty or commented for using all geometries from istart to imax.
grep_function="grep_G09_TDDFT"	# this function parses the outputs of the calculations
		# It is imported e.g. from extractG09.sh
filesuffix="log"	# i.e. "com.out" or "log"
#####################################################################

# Import grepping functions
# At least one of these files must be present
files=(extractDALTON.sh extractG09.sh extractMNDO.sh extractMOLPRO.sh extractMOPAC.sh extractORCA.sh extractQC.sh extractSTDA.sh extractTERA.sh)
for file in "${files[@]}";do
   if [[ -f "$file" ]];then
      source "$file"
   fi
done

i=$istart
samples=0
temp="$name.$$.exc.dat"

function getData {
   index=$1
   file=$name.$index.$filesuffix
   if  [[ -f $file ]];then
      $grep_function $file $temp $states

      if [[ $? -eq "0" ]];then
         if [[ ! -z $subset ]] && [[ $subset > 0 ]];then
                echo $file >> $temp
         fi
         let samples++
         echo -n "$i "
      fi
   fi
}

if [[ -n $indices ]] && [[ -f $indices ]]; then
   echo "Processing indices from $indices :"
   mapfile -t subsamples < $indices
   first=${subsamples[0]}
   last=${subsamples[${#subsamples[@]} - 1]}
   for i in "${subsamples[@]}"
   do
      getData $i
   done
else
   echo "Processing indices from $istart to $imax :"
   first=$istart
   last=$imax
   while [[ $i -le $imax ]]
   do
      getData $i
      let i++
   done
fi

echo
echo Number of samples actually found: $samples
if [[ $samples == 0 ]];then
   echo "ERROR: no samples found!"
   exit 1
fi

output="$name.${first}-${last}.n${samples}.s$states.exc.txt"
mv $temp $output
echo "Results extracted to $output"

nlines=$(wc -l < $output)
nlines2=$((samples * states))
nlines3=$((2 * samples * states))
if [[ $nlines != $nlines2 ]] && [[ $nlines != $nlines3 ]]; then
   echo "WARNING: # of lines in the output file does not correspond to # of samples and states."
   echo "# of lines: $nlines, # of samples: $samples, # of states: $states"
fi
