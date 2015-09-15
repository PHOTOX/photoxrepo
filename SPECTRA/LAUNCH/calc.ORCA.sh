#!/bin/bash

# Script for creating ORCA inputs.
# It is called from script RecalcGeoms.sh
# Three arguments are passed to this script:
#     input geometry, name of the input file and number of processors

geometry=$1
output=$2
nproc=$3              # number of processors
natom=$(head -1 $1 | awk '{print $1}')

# Modify to your needs

charge=0             # molecular charge
spin=1               # molecular spin


cat > $output <<EOF
! BHANDHLYP def2-SVP TightSCF

%cosmo epsilon 80
refrac 1.33
end

%tddft
NRoots 5
IRoot 1
end

EOF

# Number of processors is determined automatically
if [[ "nproc" -gt 1 ]];then
   echo "!PAL$nproc" >> $output
fi

# DO NOT MODIFY BELOW

# Use timestep from the movies as a comment for future reference.
head -2 $geometry | tail -1 | awk '{print "#",$0}' >> $output

# And finally, print geometry
echo "* xyz $charge $spin" >> $output

tail -$natom $geometry >> $output

echo '*' >> $output

