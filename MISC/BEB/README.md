## BEB model
A Python implementation of Binary Encounter Bethe (BEB) model:
A simple model for electron impact ionization cross section of molecules.

Orbital parameters are read from Gaussian log files or supplied as parameters on the command line. 

See folder [SAMPLES/](SAMPLES/) for example calculations.

See comments in `beb.py` for further details about the model.

To get help, try: `./beb.py -h`

WARNING: The current implementation only really works for closed shell molecules.

##### Examples

1. Read orbital parameters from G09 log file and produce dependence on incident electron energy up to 1000 eV. Output will be given in units Angstrom^2 

``
./beb.py -i g09.log --Tmax 1000 -m beb > beb.out
``

2. Calculate cross-section for one electron with 
   - orbital kinetic energy U = 2.0,
   - electron binding energy B = 1.0 
   - incident electron energy T = 30.

``
./beb.py -N 1 -U 2.0 -B 1.0 -T 30 -m beb
``
