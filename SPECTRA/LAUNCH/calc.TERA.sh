#!/bin/bash
# Script for creating G09 inputs.
# Called within script RecalcGeoms.sh
# Three arguments are passed to this script: input geometry, name of the input file and number of processors

# SETUP #################################
charge=1             # molecular charge
spin=1               # molecular spin
#----------------------------------------

# For typical G09 jobs, don't modify anything below.
geometry=$1
output=$2
nproc=$3              # number of processors

cp $geometry  $output.xyz

cat > $output <<EOF

# basis set: 6-31G**
basis		6-31++gss
# coordinates file
coordinates	$output.xyz	
# molecule charge
charge          1
# SCF method (rhf/blyp/b3lyp/etc...)
method		wpbeh
rc_w		0.2
c_ex		0.2
# add dispersion correction (DFT-D)
dftd		yes
spinmult	1
# type of the job (energy/gradient/md/minimize/ts): energy
run		energy
cis		yes
cisnumstates	7
gpus 		1

end
EOF



