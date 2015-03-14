! this calculation shows how to calculate excited state optimization.
! It is shown on water dimer cation where excited state minimum is near 
! the conical intersection, therefore it does not converge
! Yet for other molecules, you can follow this example

gprint,orbital,civector
memory,800,m;
angstrom

geometry={

 O    -0.117337     0.018102    -1.416772
 O     0.407777    -0.038298     1.471928
 H     0.243984     0.774134    -1.891318
 H     0.197823    -0.760369    -1.888020
 H     0.185916    -0.011587     0.531035
 H    -0.432580     0.017480     1.935858
}

basis
default=6-31g*
end

{hf
 wf,19,0,1}

{multi
occ, 10
closed, 6
wf,19,0,1
state,4
maxit,40;
cpmcscf,grad,2.1,record=5001.1  ! we optimize gradient of first excited state (2.1)
}

forces;samc,5001.1;
{optg,startcmd=multi,maxit=200;
method,qsd;}          !geometry optimization using analytical gradients

put,molden,geom.d1.cas.opt

{multi
occ, 10
closed, 6
wf,19,0,1
state,4
maxit,40;
}

