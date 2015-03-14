! This is an example of a conical intersection search.
! The user must specify gradients of the upper and lower states
! as well as nonadiabatic couplings between them.

! ATTENTION: conical intersection search is difficult and often 
! does not converge. In case of problems with convergence in molpro, 
! try gamess and/or Petr's utility from the US.

gprint,orbital,civector
memory,300,m;
orient,noorient
angstrom
symmetry,nosym

geometry={

 O,     0.000000     0.000000     0.000000
 O,     0.000000     0.000000     2.850000
 H,     0.783843    -0.452525    -0.320019
 H,    -0.783843    -0.452525    -0.320019
 H,     0.000000     0.000000     1.750000
 H,     0.000000     0.905104     3.169981
}

basis
default=6-31++g**
end

{hf
 wf,19,0,1}

{multi
occ,10
closed,6
wf,19,0,1
state,4
maxit,40;
CPMCSCF,NACM,1.1,2.1,accu=1.0d-7,save=5100.1
CPMCSCF,GRAD,1.1,spin=0.5,accu=1.0d-7,save=5101.1   
CPMCSCF,GRAD,2.1,spin=0.5,accu=1.0d-7,save=5102.1}

{Force
SAMC,5100.1             !compute coupling matrix element
CONICAL,6100.1}         !save information for optimization of conical intersection

{Force
SAMC,5101.1             !compute gradient for state 1
CONICAL,6100.1}         !save information for optimization of conical intersection

{Force
SAMC,5102.1             !compute gradient for state 2
CONICAL,6100.1}         !save information for optimization of conical intersection

{optg,startcmd=multi,maxit=200;
method,qsd;}          !geometry optimization using analytical gradients

put,molden,geom.cond0d1.cas.opt
