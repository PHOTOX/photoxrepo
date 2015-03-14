! This is an example of an interpolation done in molpro. 
! We have a molecule of ionized water dimer and want to calculate
! energies along the proton transfer coordinates using CASSCF and MRCI

! OUTPUTS: files containing casscf energies and mrci energies
!          automatically generated movie file

gprint,orbital,civector ! global variables which command level of printing (do not change)
memory,120,m;           ! memory requirements
symmetry,nosym;         ! symmetry input (here we disable symmetry)
angstrom                ! the geometry is set in angstroms

imax=20                 ! how many steps do we use during the interpolation?


! Z-matrix geometry specification, it contains the variables we need to define (oo2,ho3, ...)
geometry={
 o
 o    1 oo2
 h    1 ho3         2 hoo3
 h    2 ho4         1 hoo4          3 dih4
 h    2 ho5         4 hoh5          1 dih5
 h    2 ho6         4 hoh6          1 dih6
}

! FIRST STRUCTURE       ! Z-mat variables for initial structure

 oo2 =  2.935701    
 ho3 =    0.961471
 hoo3=   108.882
aho4 =  1.971106        ! This is the only parameter which changes during the interpolation
                        ! I use the notation with a (aho4) for initial structure parameteres 
                        ! and b (bho4) for final structure
 hoo4= 1.635
 dih4=  0.131
 ho5 =  0.962924
 hoh5=  115.358
 dih5=  61.884
 ho6 =  0.962912
 hoh6=  115.487
 dih6=  -62.058


! LAST STRUCTURE        ! it contains only one parameter because the other do not change
                        ! during the interpolation

bho4 =  0.97

! there are multiple ways how to define an increment, here I use it like this...
! DIFFERENCE IN "REACTIVE COORDINATE"
dho4=(aho4-bho4) / imax 


! Now we define the electronic structure level used

! Basis set input
basis
default=6-31g*
end

! The beginning of the interpolation loop
do  i=0,imax

index(i)=i ! This serves for creating tables once the calculation is finished
ho4 = aho4 - i * dho4 ! current value of the ho4 parameter

! First we need some HF (or KS) calculation
{hf
wf, 19,0,1}

! This is CASSCF input
{multi
occ,  10 ;
closed,6
wf, 19,0,1
state,4}

encas1(i)=energy(1) ! Saving CASSCF energies at every step for later evaluation
encas2(i)=energy(2)
encas3(i)=energy(3)
encas4(i)=energy(4)

! This is MRCI input
{ci
occ,  10;
closed, 6
wf,19,0,1
state, 4}

enci1(i)=energy(1) ! Saving of MRCI energies
enci2(i)=energy(2)
enci3(i)=energy(3)
enci4(i)=energy(4)

put,xyz,movie.xyz,append    ! creating movie file along the trajectory
                            ! attention the file is appended, delete it if you rerun 
                            ! the calculation. 

enddo    ! end of the interpolation loop

! let's put the calculated energies into separate files, one for
! casscf, the other for mrci
{table,index,encas1,encas2,encas3,encas4
heading,#index,EN_CAS(1),EN_CAS(2),EN_CAS(3),EN_CAS(4)
save,en.htrans.cas,new}  

{table,index,enci1,enci2,enci3,enci4
heading,#index,EN_CAS(1),EN_CAS(2),EN_CAS(3),EN_CAS(4)
save,en.htrans.mrci,new}  
