#!/bin/bash
i=1
rm Traj*.strip.xyz
rm positions.*.xyz
rm TrajDump.*

~slavicek/FMS-COMBINED/TEMP/util/ExtractFile.e < ~/bin/bundle_input

read a < positions.1.xyz
echo "Total number of atoms is $a."
echo "Number of QM atoms?"
read b

while [ $i -le 10 ]
do	
     if [ -e  positions.$i.xyz ]; then 
     grep -v -e OW -e HW positions.$i.xyz > Traj$i.strip.xyz
     sed s/$a/$b/ Traj$i.strip.xyz >a
     mv a Traj$i.strip.xyz
     sed s/W// positions.$i.xyz > a
     mv a positions.$i.xyz
     fi
     let i=$i+1
done 

