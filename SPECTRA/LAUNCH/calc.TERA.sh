#!/bin/bash
# Script for creating TeraChem inputs.
# Called within script RecalcGeoms.sh
# Three arguments are passed to this script: 
#  1. input geometry 
#  2. name of the input file that this script needs to create
#  3. number of processors, or, in this case, GPUs

geometry=$1
input=$2
nproc=$3              # number of processors

cp $geometry $input.xyz

# Modify TC params below
cat > $input <<EOF
coordinates	$input.xyz	
scrdir     scr_$input
basis		6-31++gss
charge          0
method		wpbeh
rc_w		0.2
c_ex		0.2
dftd		yes
spinmult	1
run		energy
cis		yes
cisnumstates	7
gpus 		$nproc
end
EOF



