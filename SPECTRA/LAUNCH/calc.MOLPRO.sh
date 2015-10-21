#!/bin/bash

# This script creates MOLPRO inputs.
# It is called from the script RecalcGeoms.sh.
# Three arguments are passed to this script:
#     input geometry, name of the input file and number of processors

# In the case of MOLPRO, number of processors is determined during submission
# and is not used here

# Tested with MOLPRO version 2012

geometry=$1
output=$2
natom=$(head -1 $1 | awk '{print $1}')

cat > $output <<EOF
gprint,orbital,civector
memory, 80,m;
geomtyp=xyz;
Angstrom; NoOrient;
geom=$geometry
basis=6-31g*

hf;

! CASSCF
{multi;occ,13;closed,9;state,3}

! MRCI
{ci;occ,13;closed,9;state,3}

EOF

# DO NOT MODIFY BELOW

# Use timestep from the movies as a comment for future reference.
head -2 $geometry | tail -1 | awk '{print "!",$0}' >> $output

