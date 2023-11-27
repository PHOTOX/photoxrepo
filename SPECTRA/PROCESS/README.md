## II. part (PROCESS)

So now we have our *ab initio* calculations done and we want to proceed them somehow to make a spectrum (excitation, ionization,..)

### Necessary files

First of all you need to copy important scripts (again) from this repository under the SPECTRA/PROCESS folder, these are:

  1. ExtractStates.sh
  1. extract*.sh
  1. CalcSpectrum.sh
  1. calc_spectrum.py

(* is for the program)

### ExtractStates.sh

As a second step, you have to extract the excitation/ionization energies and possibly transition dipole moments with the `ExtractStates.sh` script. This script calls an inner function from `extract*.sh` and creates a file with the `.exc.txt` extension.

#### EXAMPLE 1 (continuation)

```
##### SETUP #########################################################
name=MY_MOLECULE	# Use the same name as in previous step
states=20	# number of excited states (ground state does not count)
istart=1	# Starting index
imax=10 	# Last index to process
indices=	# file with indices of geometries to use (one index per line).
		# leave empty or commented for using all geometries from istart to imax.
grep_function="grep_G09_TDDFT"	# this function parses the outputs of the calculations
		# It is imported e.g. from extractG09.sh
filesuffix="log"	# i.e. "com.out" or "log"
#####################################################################
```

We set up the same name as in the previous step, we want to use all of the 10 calculations. The `grep_function` line is very important. It depends on the type of spectra you want to use, e. g. in our case we want to calculate absorption spectrum therefore we use `grep_G09_TDDFT`. In this case, the file `extractG09.sh` has to be present in the folder. It is recommended to look inside the `extract*.sh` scripts where you can find out which functions are available within the given program.

### CalcSpectrum.sh

The last step is to use the extracted data about electronic transitions to model the spectrum. All you need to change are the parameters inside the `CalcSpectrum.sh` script. This script is a wrapper around the python program `calc_spectrum.py`.

#### EXAMPLE 1 (continuation)

So now we have extracted data from 10 excited-state calculations and we want to create the spectrum. Change the SETUP part in `CalcSpectrum.sh` just like this:

```
##### SETUP FOR SPECTRA MODELLING ###################################
input=MY_MOLECULE.1-10.n10.s20.exc.txt  # the input file with excitation energies and possibly transition dipole moments
samples=10      # number of geometries
states=20       # number of excited states (ground state does not count)
gauss=0.3       # Uncomment for Gaussian broadening parameter in eV, set to 0 for automatic setting
#lorentz=0.1    # Uncomment for Lorentzian broadening parameter in eV
de=0.01         # Energy bin for histograms or resolution for broadened spectra.
ioniz=false     # Set to "true" for ionization spectra (i.e. no transition dipole moments)
#####################################################################
```

Usually, we want to fit the Gaussian model on the output data. Because of this, we uncomment the first line with the `gauss` option. You can use the Lorentzian model as well (mainly when the transitions with finite lifetime occur). The spectrum is then modelled by the so-called kernel density estimation in which we replace each point with a tiny Gaussian or Lorentzian function and sum over them. If both `gauss` and `lorentz` options are omitted, the spectrum is modelled by histogramming. Basically, the calc_spectrum.py script creates energy bins and distributes the output data to them. You can control the width of the energy bin. 

The `gauss` parameter has a special option `gauss=0`, which calculates the parameter automatically by employing the Silverman's rule of thumb. However, be cautious as this approach was derived for the normal distribution and works well only for unimodal functions (alias for a single peak).

In the case you want to simulate an ionization spectrum, do not forget to switch the last line to `ioniz=true`.

You will get the spectrum in different quantities and units: Absorption cross section 𝜎 in cm^2 and molar attenuation coefficient 𝜀 in M^-1cm^-1 for the *y*-axis, which are connected through the relationship 𝜀=𝜎∙𝑁a/(1000∙ln10)=𝜎/(3,823∙10^−21); and *x*-axis in eV, nm and cm^-1.
