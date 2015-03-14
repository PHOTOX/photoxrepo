! Without any modifications, casscf minimizes wavefunction which equal
! weights for each excited state considered
! Sometimes it is better to use some systematic way how to give larger
! weight to ground and low excited states
! This is an example how to do it using dynamical weighting procedure

gprint,orbital,civector
memory,300,m;
orient,noorient
angstrom
symmetry,nosym

oo2      =   2.936582
ho3      =   0.967065
hoo3     =     3.003
ho4      =   0.961531
hoh4     =   105.505
dih4     =  -174.689
ho5      =   0.963025
hoh5     =   114.895
dih5     =    54.631
aho6     =    0.962980
hoh6     =   116.166
dih6     =   -69.461
bho6 =  2.0

dho6=(bho6-aho6)/50

geometry={

 o
 o    1 oo2
 h    1 ho3         2 hoo3
 h    1 ho4         3 hoh4          2 dih4
 h    2 ho5         3 hoh5          1 dih5
 h    2 ho6         3 hoh6          1 dih6
}

 basis
  default=6-31++g**
  end

ho6=aho6

{ks,b,lyp
wf, 19,0,1}

! interpolation ------------------

do  j=1,7
index(7)=7
ho6=aho6+dho6*(j-1)

! dynamic weighting factors, probably in eV

dynweight=2/(8/TOEV)

{multi
occ,  12 ;closed,4
pspace,10;
wf, 19,0,1
DYNW,dynweight
state,20;
maxit, 40}

enddo
! end of interpolation -----------

{ci,THRVAR=1.00D-05,THRDEN=1.00D-04;
occ,  12 ;closed,4
pspace,10;
wf, 19,0,1
state,8;
}

enci1(j)=energy(1)
enci2(j)=energy(2)
enci3(j)=energy(3)
enci4(j)=energy(4)
enci5(j)=energy(5)
enci6(j)=energy(6)
enci7(j)=energy(7)
enci8(j)=energy(8)

table,index,enci1,enci2,enci3,enci4,enci5,enci6,enci7,enci8


