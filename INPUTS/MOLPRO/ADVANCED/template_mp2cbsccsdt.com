!---TEMPLATE FOR CCSD(T)/CBS calculation with CP correction
! Geometry optimized with MP2/cc-pVTZ/CP

PROC MP2CBS
basis=aug-cc-pVTZ
hf;
df-mp2;
extrapolate,basis=aug-cc-pVTZ:aug-cc-pVQZ
en_mp2=energy(3)

basis=aug-cc-pVDZ;
hf;
ccsd(t);
en_mp2dz=EMP2
en_cc=energy;
ENDPROC

gprint, orbital, civector
memory,200,m
geomtyp=XYZ
Angstrom;

geometry={
 C    -0.274558    -0.009278    -0.091905
Cl    -0.329133     0.000314     1.668923
Cl     1.383811    -0.011274    -0.686534
 F    -0.905157     1.063894    -0.555820
 F    -0.903524    -1.088418    -0.544043
 O     3.509595     0.008654     2.656300
 H     3.455588     0.003368     1.698579
 H     2.588577     0.009418     2.924378
}

MP2CBS;
en_complex=en_mp2+en_cc-en_mp2dz

dummy,1,2,3,4,5;
MP2CBS;
en_complex=en_complex-en_mp2-en_cc+en_mp2dz

dummy,6,7,8;
MP2CBS;
en_complex=en_complex-en_mp2-en_cc+en_mp2dz

en_complex_eV=en_complex*27.2114
en_complex_kcal=en_complex*627.04

