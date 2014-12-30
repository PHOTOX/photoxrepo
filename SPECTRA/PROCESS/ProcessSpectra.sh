#!/bin/bash
# Driver script for spectra simulation using reflection principle.
# Configurational broadening accounted for via RP.
# No additional broadening.


# REQUIRE FILES:
# calc.spectrum
# extractG09.sh or similar

########## SETUP #####
name=anisol
states=1	# number of excited states 
imax=1122	# number of calculations
grep_function="grep_G09UV"
# import grepping functions
source extractG09.sh
##############


i=1
samples=0
rm temp.dat -f
while [ $i -le $imax ]
do
   if  [ -f $name.$i.log ];then

      # functions imported from external file
      $grep_function $name.$i.log temp.dat $states

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

echo $samples > all.dat
echo $states >> all.dat
cat temp.dat >> all.dat

./calc.spectrum < all.dat > spectrum.$samples.dat
echo "Spectrum in units  \(nm, cm^2\) in file spectrum.$samples.dat"

