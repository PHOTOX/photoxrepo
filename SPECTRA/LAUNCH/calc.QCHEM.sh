#!/bin/bash

# Script for creating QCHEM inputs.
# It is called from script RecalcGeoms.sh
# Three arguments are passed to this script:
#     input geometry, name of the input file and number of processors

# In this case, number ogf processors must set during submission, not in the input file.

geometry=$1
output=$2
nproc=$3              # number of processors
natom=$(head -1 $1 | awk '{print $1}')

spinmult=1
charge=0

echo '$molecule' > $output
echo "$charge $spinmult" >> $output
tail -n $natom $geometry >> $output        					 						
cat >> $output << EOF
\$end

\$rem
jobtype            SP            single point
LEVCOR             CCSD
EXCHANGE           HF            Exact exchange
BASIS 		     cc-pvdz
AUX_BASIS 	     rimp2-cc-pvdz
MEM_STATIC	     2000
CC_MEMORY	     1000

eom_ip_states [1]          neutral
\$end 
EOF

