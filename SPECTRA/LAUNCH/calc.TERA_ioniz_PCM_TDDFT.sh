#!/bin/bash
# Script for creating TeraChem inputs.
# Called within script RecalcGeometries.sh
# We need two arguments: input geometry and name of the input file

# SETUP #################################
charge=0             # molecular charge
spin=1               # molecular spin
numstates=8
mem=1500Mb            # memory in G09 job
basis=6-31+g*
method=b3lyp
#----------------------------------------

# For typical TERA jobs, don't modify anything below.
geometry=$1
output=$2
num_gpu=$3              
natom=$(head -1 $1 | awk '{print $1}')
path=$(pwd)

cat $geometry > $output.xyz

cat > $output.ground.in << EOF

basis         $basis
method        $method
charge        $charge
spinmult      $spin
maxit         100
xtol          1e-3
threall       1e-12
convthre      1.0e-6
dftgrid       1
gpus          $num_gpu
run           energy
nstep         100
coordinates   $path/$output.xyz

pcm             cosmo
pcm_grid        iswig
pcmgrid_heavy   17
pcmgrid_h       17
epsilon         2.28
pcm_radii       bondi
cosmo_rad_scale 1.2
solvent_radius  0
dynamiccg       3
cgprecond       blockjacobi3
cgblocksize     100
pcm_write       $path/$output.groundfield.bin    #Please note, that Terachem reads all letters as lowercase 
end

EOF

let spin2=spin+1
let charge2=charge+1

cat > $output.ss.in << EOF

basis         $basis
method        u$method
charge        $charge2
spinmult      $spin2
maxit         100
xtol          1e-3
threall       1e-12
convthre      1.0e-6
dftgrid       1
gpus          $num_gpu
run           energy
coordinates   $path/$output.xyz

#CIS related
cis       yes
cisnumstates    $numstates
cismaxiter     100
cistarget      1

#PCM related
#most important keywords
pcm           		cosmo
pcm_grid       		iswig
ss_pcm_solvation 	ground_neq
sspcm_convthre   	1e-6
epsilon         	2.28
fast_epsilon    	1.776
pcm_read       		$path/$output.groundfield.bin    #Please note, that Terachem reads all letters as lowercase 
	
#other PCM keywords (same as their default values.
#List explicitly here as examples of what could be specified
pcmgrid_heavy   17
pcmgrid_h       17
pcm_radii       bondi
cgprecond       blockjacobi
end

EOF



