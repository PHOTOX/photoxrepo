print,civector
memory,250,m;

! This is an example calculation using CASSCF and CASPT2 with symmetry
! Tested with Molpro 2012

Orient, noorient;
Angstrom;
Symmetry, X, Y;

! Cyclopropene molecule
 geometry={
 C      0.000000   0.650000    -0.482468
 C      0.000000  -0.650000    -0.482468
 C      0.000000   0.000000     0.886085
 H      0.000000   1.575870    -1.018817
 H      0.000000  -1.575870    -1.018817
 H     -0.914333   0.000000     1.473928
 H      0.914333   0.000000     1.473928
}

basis=cc-pVDZ

! B3LYP guess orbitals for CASSCF
  ks,b3lyp

! CASSCF with C2v symmetry, i.e. 4 irreducible representation
  multi;
  occ, 8,2,4,1;
  closed,5,1,2,0;
  wf,22,1,0;
  state,1;
  wf,22,2,0;
  state,1;
  wf,22,3,0;
  state,2;
  maxiter,20;

nstate_total=4

! Automatically calculate oscillator strengths from
! transition dipole moments
do i=2,nstate_total
exc(i-1)= 27.2114*(energy(i)-energy(1))
dx(i-1) = trdmx((i-1)*(i-2)/2+1)
dy(i-1) = trdmy((i-1)*(i-2)/2+1)
dz(i-1) = trdmz((i-1)*(i-2)/2+1)
f(i-1)=2/3*(energy(i)-energy(1))*(dx(i-1)^2+dy(i-1)^2+dz(i-1)^2)
enddo

! Print the results into table
text 'CASSCF results'
table,dx,dy,dz,exc,f

! Separate CASPT2 calculations for each symmetry 
{rs2,shift=0.3,mix=1,root=1;wf,22,1,0;state,1;
option,maxiti=500;}
en1=energy(1)

{rs2,shift=0.3,mix=1,root=1;wf,22,2,0;state,1;
}
exc(1)= 27.2114*(energy(1)-en1)

{rs2,shift=0.3,mix=2,root=1;wf,22,3,0;state,2;
}
exc(2)= 27.2114*(energy(1)-en1)
exc(3)= 27.2114*(energy(2)-en1)
 
! To compute CASPT2 transition dipole moments
! between states of different symmetry, one has to biorthogonalize the orbitals

! The current code does not work because RS2 no longer supports save command
! we somehow need to save the orbitals of different symmetries in multi (I guess)
!{rs2; trans,3060.1,3070.1,biorth;}
dx(1) = trdmx(1)
dy(1) = trdmy(1)
dz(1) = trdmz(1)
f(1)=2/3*(exc(1)/27.2114)*(dx(1)^2+dy(1)^2+dz(1)^2)

!{rs2; trans,3060.1,3080.1,biorth;}
dx(2) = trdmx(1)
dy(2) = trdmy(1)
dz(2) = trdmz(1)
f(2)=2/3*(exc(2)/27.2114)*(dx(2)^2+dy(2)^2+dz(2)^2)
dx(3) = trdmx(2)
dy(3) = trdmy(2)
dz(3) = trdmz(2)
f(2)=2/3*(exc(3)/27.2114)*(dx(3)^2+dy(3)^2+dz(3)^2)

text 'CASPT2 results'
table,dx,dy,dz,exc,f

put,molden,cas-8241-5120-1110st-vdz.mold
