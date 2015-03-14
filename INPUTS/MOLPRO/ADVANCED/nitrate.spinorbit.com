gprint,orbital,civector
memory,250,m;
orient,noorient
symmetry,nosym
angstrom


geometry={
N .012795505 -.007747154 .002471257
O .002169626 .002259586 1.267088463
O 1.059957905 .002259586 -.629509255
O -1.073330214 .002259586 -.639738251
}

newcassing=2140.2
mrcising=3140.2
mrcitrip=3141.2

basis=6-31+g*

{hf;
wf,32,0,0
maxit,100}

{multi
accuracy,gradient=1.00D-02,step=1.00D-02,energy=1.00D-05
occ,20
closed,11
pspace, 1
wf,32,0,0
orbital,newcassing
state,15
maxit,40}

{ci,maxiti=2000;option,refopt=0;wf,32,0,0;noexc;orbit,newcassing;state,15;save,mrcising}
{ci,maxiti=2000;option,refopt=0;wf,32,0,2;noexc;orbit,newcassing;state,8;save,mrcitrip}

lsint;

text,NITRATE spin-orbit coupling calculation
{ci;hlsmat,ls,mrcising,mrcitrip
print,HLS=0.5}

