#!/bin/bash
# Script for creating G09 inputs.
# Called within script RecalcGeoms.sh
# Three arguments are passed to this script: input geometry, name of the input file and number of processors

# SETUP #################################
charge=0             # molecular charge
spin=1               # molecular spin
mem=500Mb            # memory in G09 job
g09="#BMK/aug-cc-pVDZ gfinput IOP(6/7=3) nosymm TD=(singlets,nstate=5)"
#----------------------------------------

# For typical G09 jobs, don't modify anything below.
geometry=$1
output=$2
nproc=$3              # number of processors
natom=$(head -1 $1 | awk '{print $1}')

cat > $output <<EOF
%Mem=$mem
%NProcShared=$nproc
$g09

EOF

# Use timestep from the movies as a comment for future reference.
head -2 $geometry | tail -1 >> $output

echo " " >> $output
echo $charge $spin >> $output

tail -$natom $geometry >> $output

echo " " >>$output

