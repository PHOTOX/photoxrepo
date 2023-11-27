## I. part (LAUNCH)

If you have a `movie.xyz` file from MD and you want to create an excitation/ionization spectra by using the reflection principle, just follow these instructions.

### Necessary files

First of all you need to copy important scripts from this repository under the SPECTRA/LAUNCH folder, these are:

  1. PickGeoms.sh
  1. RecalcGeometries.sh
  1. calc.*.sh

(* is for the program and/or type of calculation)

### PickGeoms.sh

This script is usually used as a first step to select only some of the geometries from the movie file. There are no difficult settings inside this script. You just have to decide, whether you want to select these geometries randomly or if you want to use a constant step. 
The `nstep` option gives you the opportunity to change the number of geometries you need to select.
Additionally, uncomment the last line, in case you need to cut some (e. g. solvent) molecules.

### RecalcGeometries.sh and calc.*.sh

These two scripts work together (Recalc calls calc.*). They take the output from the `PickGeoms.sh` (usually called `geoms.xyz`, but not necessarily), create inputs for SCF/TDDFT calculation in desired *ab initio* program and submit jobs.

#### EXAMPLE 1

Lets say we want to calculate 20 excited states using Gaussian09. We copy `RecalcGeometries.sh` and `calc.GAUSS.sh` to the current folder and change the settings within them. Let's begin with the `RecalcGeometries.sh` script and all we need to change is the SETUP part of it. It is pretty well commented so just be sure you check all the lines and fill them up correctly. In the following file we set up that we want to name the input files `MY_MOLECULE.$i.com`, we will use for demonstration just 10 calculations (samples) that will be combined in just 1 job using 1 processor. Please notice that we are currently working on ARGON cluster, you can use the others as well, just remember to change `aq` in submitting line.

```
######## SETUP ##########
name=MY_MOLECULE        # name of the job (it is up to you how to call it)
firstgeom=1             # first geometry (when you want to start in geoms.xyz file)
lastgeom=10             # last geometry, (0 for all geometries up to the end of file)
movie=geoms.xyz         # file with xyz geometries (usually from PickGeoms.sh)
program=GAUSS           # one of GAUSS, MOLPRO, QCHEM, ORCA
jobs=1                  # determines number of jobs to submit (calculations are distributed accordingly)
nproc=1                 # number of processors per job
#submit="qsub -V -q aq -pe shm $nproc " # uncomment this line for automatical jobs submitting
make_input="calc.$program.sh"           # script to make input files.
submit_path="$program"                  # script for launching a given program (GAUSS,TERA etc.)
######################
```

For these calculations we use Gaussian09 and `RecalcGeometries.sh` needs to cooperate with the `calc.GAUSS.sh` script. Again, we usually change only the SETUP part. Within this example we want to calculate neutral molecule with spin multiplicity 1 using the BMK DFT functional, augmented cc-pVDZ basis set and TD-DFT for the calculation of 20 excited states. In addition, we want to generate molecular orbitals. If you want to use other options for your calculations just modify it here.

```
# SETUP #################################
charge=0             # molecular charge
spin=1               # molecular spin
mem=500Mb            # memory in G09 job
g09="#BMK/aug-cc-pVDZ gfinput IOP(6/7=3) nosymm TD=(singlets,nstate=20)"
#----------------------------------------
```
