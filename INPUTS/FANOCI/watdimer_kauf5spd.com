run            energy
print_mos      yes
mycode         yes
basis          cc-pvdz-kauf-5spd
spinmult       1
coordinates    watdimer_mp2_631ppgss.xyz
casci          yes
closed         2
active         9
method         hf
charge         0
precision      mixed
threall        1.0e-20
convthre       1.0e-9
timings        yes
xtol           1e-5
scf            diis+a
maxit          20
scrdir         scr-watdimer_kauf5spd
print_mo2int   yes
print_mo2int_partial  yes
print_mo2int_nfzv     50
print_mo2int_thre     1e-9
gpus     1  1
end
