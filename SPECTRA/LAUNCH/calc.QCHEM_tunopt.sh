#!/bin/bash

# Script for creating Optimal Tuning BNL QCHEM inputs.
# It is called from script RecalcGeoms.sh

geometry=$1
dir=$2
natom=$(head -1 $1 | awk '{print $1}')

if [[ ! -d $dir ]];then
   mkdir $dir
fi
output=$dir/N.in
output2=$dir/P.in
charge=0
spinmult=1
charge2=1
spinmult2=2
cat > $output << EOF
\$rem
EXCHANGE           GENERAL
BASIS              6-31+G*
SCF_FINAL_PRINT    1
SEPARATE_JK        TRUE
omega              500
jobtype            SP            single point
\$end 

\$XC_Functional
X HF       1.0
X BNL      1.0
C LYP      1.0
\$end
EOF

cp $output $output2

echo '$molecule' >> $output
echo "$charge $spinmult" >> $output
tail -n $natom $geometry >> $output        					 						
echo '$end' >> $output

echo '$molecule' >> $output2
echo "$charge2 $spinmult2" >> $output2
tail -n $natom $geometry >> $output2        					 						
echo '$end' >> $output2


