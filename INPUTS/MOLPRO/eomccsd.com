gprint,orbital,civector
memory,100,m;
orient,noorient
angstrom
symmetry,nosym

geometry={
 O     0.000000     0.000000     0.000000
 H     0.000000     0.000000     0.950000
 H     0.895670     0.000000    -0.316663
}
 
basis
default=6-31g*
end

{hf
wf,10,0,0}
{ccsd                                             ! do CCSD calculation, try to restart
wf,10,0,0
eom,-5.1,trans=1}
! do EOM-CCSD calculation for 5 excited states
! if trans = 1, compute transition dipole moments (much slower!!!)
! default is trans = 0

