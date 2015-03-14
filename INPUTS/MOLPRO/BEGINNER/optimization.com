! This is an example of an geometry optimization done in molpro using DFT
! we are optimizing ionized water dimer

gprint,orbital,civector ! global variables which command level of printing (do not change)
memory,120,m;           ! memory requirements
symmetry,nosym;         ! symmetry input (here we disable symmetry)
angstrom                ! the geometry is set in angstroms


! XYZ geometry specification
geometry={
 O         -0.0000218309       -0.0660220264       -1.5099793198
 O         -0.0000556987        0.0555648820        1.4232027380
 H          0.0000841166        0.8300419659       -1.8585417882
 H         -0.0001501717        0.0314438609       -0.4476371681
 H          0.7683189835       -0.3474794808        1.8407889197
 H         -0.7670222731       -0.3480162707        1.8428264346
}

! Now we define the electronic structure level used

! Basis set input
basis
default=aug-cc-pVDZ
end

{df-ks,b-lyp
wf, 19,0,1}
! number of electrons, wf symmetry, spin (defined as 2S, here dublet)

optg;

put,xyz,w_dimer_opt.xyz    ! extracting final geometry into separate file
put,molden,w_dimer_orb     ! extracting MOs for final structure into MOLDEN readable file
