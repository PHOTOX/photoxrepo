#!/bin/bash

#script for launching FMS dynamics
#need Freqencies to be done...Frequency.dat and Geometry.dat
#needs $name.com (made by deckMP)
#needs modified Control.dat (Control_mod.dat) with several first lines deleted 
#WARNING: uses very primitive random seed generator, be careful with launching too many trajectories

#####SETUP#########
i=1
nruns=3
name=disiger_sih
####

echo ~oncakm/bin/runFMS-comb $name.com > run.FMS.$name

RANDOM=$$   #reseeds random number generator by using script process ID

while [ $i -le $nruns ] 
do
	mkdir run.$i
	cp Frequencies.dat Geometry.dat $name.com run.FMS.$name run.$i
	cat > temp << EOF
 &control

fmsname='$name'
iRestart=0

!------ Initialization -------!
 InitialCond="WIGNER"
 InitState=2
 GenSolvent=.false.
EOF
	echo iRndSeed=$RANDOM$RANDOM >> temp
	cat Control_mod.dat >> temp
	mv temp run.$i/Control.dat
	cd run.$i 
	qsub -cwd -q sq-8-16 run.FMS.$name
	cd ../
	let i=i+1
done
