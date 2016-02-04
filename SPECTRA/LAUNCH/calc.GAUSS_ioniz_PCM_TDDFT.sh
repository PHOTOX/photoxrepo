#!/bin/bash
# Script for creating G09 inputs.
# Called within script RecalcGeoms.sh
# We need two arguments: input geometry and name of the input file

# This particular scripts generates input for simulations of 
# photoionization spectra using PCM solvation and TDDFT to get excited states as well.

# SETUP #################################
nproc=$3              # number of processors
charge=0             # molecular charge
spin=1               # molecular spin
mem=2500Mb            # memory in G09 job
g09="#BMK/6-31+g* nosymm scrf(pcm,read,solvent=benzene)"
#----------------------------------------

# For typical G09 jobs, don't modify anything below.
geometry=$1
output=$2
natom=$(head -1 $1 | awk '{print $1}')

cat > $output <<EOF
%Mem=$mem
%NProcShared=$nproc
%chk=$output.chk
$g09

EOF

# Use timestep from the movies as a comment for future reference.
head -2 $geometry | tail -1 >> $output

echo " " >> $output
echo $charge $spin >> $output

tail -$natom $geometry >> $output

echo " " >>$output

echo "icomp=0 noneq=write" >>$output
echo "" >>$output

cat >> $output << EOF
--link1--
%mem=$mem
%NProcShared=$nproc
%chk=$output.chk
#BMK/6-31+g* TD=(NStates=20) guess=(read) geom=check nosymm scrf(pcm,read,solvent=benzene) test  gfinput iop(6/7=3)

ionized state

1,2

icomp=0 noneq=read

EOF


