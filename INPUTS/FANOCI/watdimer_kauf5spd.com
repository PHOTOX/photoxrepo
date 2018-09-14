### Basic params

run            energy

coordinates    watdimer_mp2_631ppgss.xyz
method         hf
charge         0
spinmult       1

# When running two concurrent jobs on GPU machine in A130, 
# you need to ensure to use both cards uniquelly
# See TC manual for details about the gpu keyword
gpus     1  0
#gpus     1  1

# Basis sets needs to be installed in the $TeraChem/basis directory
# Their generation is quite tricky, will write manual later

# You should always try to do a convergence tests for the FANO-CI results with the basis set
# , i.e. going from cc-pvdz-kauf-3spd up to perhaps cc-pvdz-kauf-6spd
# cc-pvtz-Xspd might be use as well if you strip f- and g- functions that TC does not support
# I am not sure I generated these properly though, so for now avoid them
basis          cc-pvdz-kauf-5spd

# The integrals and other stuff for subsequent FANO-CI will be in this folder
scrdir         scr-watdimer_kauf5spd

##### SCF convergence parameters ###########

# In general, I used non-default params here as we are doing CI
# and also have so many diffuse functions so SCF convergence is tricky

# The default is "precision dynamic"
# For CI calculation, I was recommended to use mixed precision 
# or even full double precision (See TC manual)
# Full double precision is quite costly though
precision      mixed  

# Again, perhaps too much abundance of caution here, default is 1e-12
threall        1.0e-20

# Very tight SCF converge threshold...probably could be larger
# I think I just tried to match Gamess defaults
convthre       1.0e-9

# There is a delicate balance in setting x-tol with diffuse Kaufmann basis sets
# If it's too low, SCF won't converge
# If it is default you might be discarding potentially useful AO functions
xtol           1e-5

# DIIS+A needed for better SCF convergence
# Be carefull though, it really tries hard and gives up only after 10000 SCF iterations
# so it is good to monitor it and kill if it is hopeless
scf            diis+a  


##### CASCI code param ############3
casci          yes
# Here we don't care about core orbitals
closed         2
# Number of active orbitals...this is the tricky part
# Because of the hacky way my code is written the "active space"
# should include exactly one virtual orbital, i.e.
# closed + active = 11 for water dimer
# The code then swaps orbitals and calculate couplings to all virtuals
# (see FANO-CI part below), but not couplings among the virtual orbitals themselves
active        9

# Up to now, all keywords can be found in TC manual

####### FANO-CI 2e-integral optionsa ########

# TURN-ON FANO-CI integral engine
print_mo2int   yes

# Do not do full FCI calculation, 
# Calculate only integrals needed for FANO-CI
# (This should ALWAYS be ON)
print_mo2int_partial  yes

# "Freeze" some number of virtuals i.e. do not compute integrals for them
# Should work the same as Gamess NFZV keyword
# For inner valence ICD in water dimer, we do not care about these super-hign energy virtuals
# This helps to reduce comp. cost quite a bit (it is linear in the number of virtulas)
# It's good to run HF only first, look at the orb. energies and then decide about this parameter.
print_mo2int_nfzv     50

# Do not pring integrals below this threshold
# it makes the resulting moint.txt smaller
print_mo2int_thre     1e-11

end
