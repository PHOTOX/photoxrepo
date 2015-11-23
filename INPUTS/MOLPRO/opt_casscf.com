*** OPTIMIZATION on CASSCF in MOLPRO 
*** This works with segmented basis sets (i.e. Pople)
*** For General Contracted basis sets (Dunning), there's a different syntax

gprint,orbital,civector
memory, 40,m;
Angstrom;
NoOrient;
NoSym;

geometry={
 O         -0.0000218309       -0.0660220264       -1.5099793198
 H          0.0000841166        0.8300419659       -1.8585417882
 H         -0.0001501717        0.0314438609       -0.4476371681
}

 

basis=6-31g*;

hf;

multi;
start, 2141.2;
occ, 7;
closed,1;
state,3;
weight, 1,1,1;
MAXITER,30;

cpmcscf,grad,2.1;
forces;
hessian,numerical=5;
optg,root=2;
frequencies;

put,molden,molden.opt_casscf

