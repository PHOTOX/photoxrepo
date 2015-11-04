#!/bin/bash

# This is not an actual running calculation, it is a starting script for that.
# However it should make the concepts about diabetization clear.
# You need to have a wavefunction for the reference geometry (reference.6.wfu).
# Diabatization is being done using the DDR procedure.

# if you want to run diabatization:
# 1) decide what is your reference, calculate single point and save the wavefunction
# 2) once you have the reference wavefunction, you can start the calculation.
# ATTENTION: be careful with using record files to clearly distinguish which record
           # belongs to the reference and which belongs to the current calculation
# 3) good luck! you will need it... 

rm -f run.*
i=1
while test $i -le 6
#while test $i -le 20
do
j=1
while test $j -le 1
#while test $j -le 16
do

echo "gprint,orbital,civector
file,2,job.$i.$j.wfu,old   !old dynamical weighted calculation at the same point
file,3,reference.6.wfu,old   !reading reference wave function for diabatization
memory,250,m;
orient,noorient
symmetry,nosym
angstrom

! see zmatrix file zmatrix.2par

geometry={

 n1,
 x2,    n1, 1.0
 x3,    n1, 1.0        2 90
 o4,    n1, on4        2 alpha         3 180
 o5,    n1, 1.235      2 alpha         3  60
 o6,    n1, 1.235      2 alpha         3 -60
}">no3.diab.$i.$j.com

echo "
on4 = 0.635+($i-1)*0.1  !should be unnecessary, because we are reading geometry from wfu file anyway
distance=on4
alpha = 90+($j-1)*2 !should be unnecessary, because we are reading geometry from wfu file anyway

reforb=2140.3               !Orbital dumprecord at reference geometry
dynorb=2140.2
refci=6000.3                !MRCI record at reference geometry
savci=6100.2                !MRCI record at displaced geometries

basis
default=6-31g*
end

dynweight=3

{multi
    occ,20
    closed,7
    pspace, 3
    wf,32,0,0
    state,15
    DYNW,dynweight
    maxit,40;
    START,dynorb;               !Reading wave function from previous calculation
    dont,orbital;
    orbital,3140.2;
    diab,reforb                 !Compute diabatic orbitals using reference orbitals
    noextra}

{ci,THRVAR=1.00D-05,THRDEN=1.00D-04,maxiti=3000,nocheck;  !Specification of convergence criteria
pspace,2
noexc;                                                   !Noexc --> no mrci iterations (casscf)
occ,20;closed,7;
wf,32,0,0;state,4;
orbital,diabatic
save,savci}                                            !Save MRCI for displaced geometries

eadia=energy                                             !Save adiabatic energies for use in ddr
  e1=energy(1)                                           !Save adiabatic energies for table printing
  e2=energy(2)
  e3=energy(3)
  e4=energy(4)

{ci,THRVAR=1.00D-05,THRDEN=1.00D-04,maxiti=3000,nocheck;
  trans,savci,savci;                                     !Compute transition densities at R2
 dm,7000.2}                                                !Save transition densities on this record
{ci,THRVAR=1.00D-05,THRDEN=1.00D-04,maxiti=3000,nocheck;
   trans,savci,refci;                                      !Compute transition densities between R2 and R(reference)
 dm,7100.2}                                                !Save transition densities on this record

 {ddr
   density,7000.2,7100.2                    !Densities for <R2||R2> and <R2||R(reference)>
   orbital,3140.2,reforb                      !Orbitals for <R2||R2> and <R2||R(reference)>
   energy,eadia(1),eadia(2),eadia(3),eadia(4)   !Adiabatic energies
   mixing,1.1,2.1,3.1,4.1}                      !Compute mixing angle and diabatic energies

 h11ci=hdiaci(1)        !Diabatic energies obtained from ci vectors only
 h21ci=hdiaci(2)        !HDIA contains the lower triangle of the diabatic hamiltonian
 h22ci=hdiaci(3)
 h31ci=hdiaci(4)        
 h32ci=hdiaci(5)        
 h33ci=hdiaci(6)        
 h41ci=hdiaci(7)        
 h42ci=hdiaci(8)        
 h43ci=hdiaci(9)        
 h44ci=hdiaci(10)       

 h11=hdia(1)          !Diabatic energies obtained from total overlap
 h21=hdia(2)        
 h22=hdia(3)
 h31=hdia(4)
 h32=hdia(5)
 h33=hdia(6)
 h41=hdia(7)
 h42=hdia(8)
 h43=hdia(9)
 h44=hdia(10)">>no3.diab.$i.$j.com

echo "./RunM10.savewf no3.diab.$i.$j.com $i">>run.$i
j=`expr $j + 1`
done
#if [ $i -le 13 ]; then
# qsub -cwd -q sq-8-16 run.$i
#else
  qsubsec -cwd -q mq-8-16 run.$i
#fi
i=`expr $i + 1`
done
