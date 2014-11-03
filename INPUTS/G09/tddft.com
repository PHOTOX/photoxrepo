$rungauss
%Mem=500Mb
%NprocShared=1
#B3LYP/6-31g* TD=(Singlets,Root=1,NStates=5) GFINPUT IOP(6/7=3) 

sample tddft calculation

0 1
O
H 1 r1
H 1 r1 2 a1

r1=1.0
a1=180.

