#!/bin/bash`

# WARNING: not tested yet

# Script for creating ORCA inputs.
# Called within script RecalcGeoms.sh
# We need two arguments: input geometry and name of the input file

nproc=1              # number of processors
charge=0             # molecular charge
spin=1               # molecular spin

geometry=$1
output=$2
natom=$(head -1 $1 | awk '{print $1}')

cat > $output <<EOF
! BHANDHLYP def2-SVP TightSCF
! PAL$nproc

%cosmo epsilon 80
refrac 1.33
end

%tddft
NRoots 10
IRoot 1
end

EOF

# DO NOT MODIFY BELOW

# Use timestep from the movies as a comment for future reference.
head -2 $geometry | tail -1 | awk '{print "#",$0}' >> $output

# And finally, print geometry
echo "* xyz $charge $spin"

tail -$natom $geometry >> $output

echo '*' >>

