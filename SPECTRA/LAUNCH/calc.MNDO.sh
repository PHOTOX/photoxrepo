#!/bin/bash
# Script for creating MNDO inputs
# Called within script RecalcGeoms.sh
# Three arguments are passed to this script: input geometry, name of the input file and number of processors
geom=$1
output=$2
nproc=$3 
natom=$(head -1 $1 | awk '{print $1}')

#----------------USER SETUP-----------------------
method="OM2"   # semiempirical methods, usually OMx
nstates=11      # total number of states including ground state
charge=0       # molecular charge
multi=0        # multiplicity
               # 0 Closed-shell singlet
               # 1 Open-shell singlet with two singly occupied orbitals, this usually corresponds to an excited singlet state
               # 2 Doublet
               # 3 Triplet
naocc=8        # number of active occupied orbitals
naunocc=4      # number of active unoccupied orbitals
disper=-1       # Option for dispersion function corrections, only for AM1, PM3, OM2, OM3, ODM2, and ODM3.
               # -1 not included
               # 0  =-3 for ODM2,ODM3 and =-1 for others
               # for  AM1 and PM3:
               # 1  include dispersion corrections (PCCP 9, 2362 (2007)).
               # for OM2 and OM3:
               # 1  Like immdp=2 with with Elstner's damping function alias D1, (see JCP 114, 5149 (2001)
               # 2  Include the D2 dispersion correction from Grimme
               # for OM2, OM3, ODM2, and ODM3:
               # 3  Include the D3 dispersion correction from Grimme.
               # =-3  Like immdp=3, but with three-body terms included.
# Advanced options with recommended values
nref=1         # number of reference occupations (see also refdef=3 option for automatic nref extension)
               # 0 None. Full CI in the active space.
               # n Chosen number, maximum 3 (usually, can be more with manual selection of occupations)
refdef=3       # definition of reference occupations
               # 0 and nciref=1: SCF configuration
               #       nciref=2: SCF configuration and doubly excited HOMO-LUMO
               #       nciref=3: SCF configuration, singly and doubly excited HOMO-LUMO
               # 3 Starting as mciref=0, then adds further references so that their fraction is at least 85 %
               #   It efficiently adds more references then defined by nref
nexc=2         # maximum excitation level, ignored for nref=0
               # 1 CIS, only single excitations.
               # 2 CISD, up to double excitations.
               # 3 CISDT, up to triple excitations.
               # 4 CISDTQ, up to quadruple excitations.
               # n Up to n-fold excitations
cat > $output << EOF
$method jop=-1 igeom=1 iform=1 kharge=$charge imult=$multi +
kci=5 ici1=$naocc ici2=$naunocc iroot=$nstates nciref=$nref +
mciref=$refdef levexc=$nexc ioutci=1 kitscf=500 iuvcd=2 immdp=$disper

EOF
# Comment
head -2 $geom | tail -1 >> $output   
#---------------END OF USER SETUP-----------------------------

# Conversion of xyz input to MNDO geom
# it uses dummy attoms for small molecules otherwise it switches automatically from xyz to zmat format
tail -n $natom $geom | awk '
{
   printf "%s %.12g %i %.12g %i %.12g %i\n", $1, $2, 0,  $3, 0,  $4, 0
}
END {
   for (i = 1; i <= 4 - NR; i++)
        print 99, 0, 0, 0, 0, 0, 0
}
' >> $output

