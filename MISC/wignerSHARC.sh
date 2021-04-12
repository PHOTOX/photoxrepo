#!/bin/bash
#Script for wigner sampling of initial positions and velocities
#Input: molden file with frequencies

#Utilizing the SHARC Program suite https://github.com/sharc-md/sharc
#J.Suchan

#--- SETUP ---------------------------------
ngeom=100
natom=5
temp=300
moldenfile=c1.molden
#-------------------------------------------

natom2=$((natom+2))
nentry=$((natom+2+9))
python2.6 ~suchanj/programs/sharc/bin/wigner.py -n $ngeom -t $temp ./$moldenfile

if [[ -e wigmovie.xyz ]];then
   echo "File wigmovie.xyz already exists and will be overwriten."
   echo "Should I proceed anyway? [yes/no]"
   read answer
   if [[ "$answer" != "yes" ]];then
      echo "ABORTING."
      exit 1
   fi
fi

rm -f wigmovie.xyz wigvel.xyz
echo "Extracting wigmovie.xyz and wigvel.xyz ..."

#Write out movie and vel separately
sed -n '/^Index     1$/,$p' initconds > initconds.file

g=1 #geom number
l=1 #line number
while IFS= read -r line
do
 #Skip the unwanted lines
 if [ "$l" -eq "1" ]; then
    echo $natom >> wigmovie.xyz
    echo $natom >> wigvel.xyz
    l=$((l+1))
    continue
 fi
 if [ "$l" -eq "2" ]; then
    echo "Geom $g" >> wigmovie.xyz
    echo "Geom $g" >> wigvel.xyz
    l=$((l+1))	 
    continue
 fi
 #Extract
 if [ "$l" -le "$natom2" ]; then
    echo $line | awk {'print $1 "   " $3*0.529177249 "   " $4*0.529177249 "   " $5*0.529177249'} >> wigmovie.xyz
    echo $line | awk {'print $1 "   " $7 "   " $8 "   " $9 '} >> wigvel.xyz
 fi
 l=$((l+1))
 #Reset?
 if [ "$l" -eq "$nentry" ]; then
     l=1
     g=$((g+1))
 fi
done < "./initconds.file"

echo "Done"

