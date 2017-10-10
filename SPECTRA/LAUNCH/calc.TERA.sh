#!/bin/bash
# Script for creating TeraChem inputs.
# Called within script RecalcGeoms.sh
# Three arguments are passed to this script: 
#  1. input geometry 
#  2. name of the input file that this script needs to create
#  3. number of processors

# SETUP #################################
charge=1             # molecular charge
spin=1               # molecular spin
#----------------------------------------

# For typical G09 jobs, don't modify anything below.
geometry=$1
input=$2
nproc=$3              # number of processors

cp $geometry  $input.xyz

cat > $input <<EOF
# coordinates file
coordinates	$input.xyz	

# scratch directory
scratch     scr_$input

# basis set: 6-31G**
basis		6-31++gss
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



