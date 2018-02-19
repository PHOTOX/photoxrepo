# BEP model
A Python implementation of BEP model: A simple model for electron impact ionization cross section of molecules.

Orbital parameters are read from G09 log files or supplied as parameter on the command line. 

See folder [](SAMPLES/) for example calculations.

See bep.py for further details about the model.

WARNING: Current implementation only really works for closed shell molecules.

##### Examples

1. Read orbital parameters from G09 log file and produce dependence on incident electron energy up to 1000 eV. Output will be given in units Angstrom^2 

``
./bep.py -i g09.log --Tmax 1000 -m bep > bep.out
``

2. Calculate cross-section for one electron with 
   orbital kinetic energy U=2.0,
   electron binding energy B=1.0 
   and incident electron energy T=30.

``
./bep.py -N 1 -U 2.0 -B 1.0 -T 30 -m bep
``
