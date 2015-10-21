#!/bin/bash
#
if [ -z "$1" ];then
	echo "USAGE: $0 [molpro.output]"
	echo 
	echo "Script for conversion of MOLPRO vibrational frequencies to Gaussian-format for visualization in Molden."
	echo "Molden data are stored in a temporary file ""temp""."
	exit 1
fi

if [ ! -e $1 ];then
	echo "File $1 does not exists."
	echo "USAGE: $0 [molpro.output]"
	exit 1
fi

cat > temp << EOF
  Entering Gaussian System
                         Standard orientation:                         
 ---------------------------------------------------------------------
 Center     Atomic     Atomic              Coordinates (Angstroms)
 Number     Number      Type              X           Y           Z
 ---------------------------------------------------------------------
EOF
#reading last XYZ geometry in molpro output,conversion from bohr to angstroms
#reading frequencies
awk '
BEGIN{
i=1
j=1
count=0
nlow=0
nimag=0
prep=0}
{
	#READING XYZ COORDINATES,ONLY LAST GEOMETRY WILL BE PRINTED,DETERMINING NUMBE OF ATOMS AND NORMAL MODES 
	if ( $1 == "NR" && $2 == "ATOM" ) {
		n = 0
		getline
		getline
		while ( $1 >= 0 ) {
			n++
			dig=length($3)
			a[n] = $1 
			b[n] = substr($3,1,dig-3)
			c[n] = $4 
			d[n] = $5 
			e[n] = $6
			getline
		}
		N=n
		ncoor=3*N
		nfreq=3*N-6
	}

#HOW MANY IMAGINARY FREQUENCIES?
if ( $1 == "Imaginary") {
	getline
	getline
	while ( $1 >= 0 ) {
	        nimag++
       		getline
	}
}	
#HOW MANY LOW FREQUENCIES?
if ( $1 == "Low") {
	getline
	getline
	while ( $1 >= 0 ) {
	        nlow++
       		getline
	}
	nlow=nlow-6
	i=nlow+nimag+1
}

#READING NORMAL FREQUENCIES FIRST,BUT I IS NOT 1
if ( $1 == "Wavenumbers" && prep == "0" ) {
	if ( i > nfreq ) next
	Int[i]=$3
	Int[i+1]=$4
	Int[i+2]=$5
	Int[i+3]=$6
	Int[i+4]=$7
	getline
	getline
        for (h=1;h<=ncoor;h++) {
		getline
		K[i,h]= $2*1
		K[i+1,h]= $3*1
		K[i+2,h]= $4*1
		K[i+3,h]= $5*1
		K[i+4,h]= $6*1
	}
	i=i+5
}
#NOW WE ARE READING IMAGINARY FREQUENCIES
if ( $4 == "imaginary" )  
	prep=1

if ( $1 == "Wavenumbers" && prep == "1" ) {
	for (j=1;j<=nimag;j++) 
		Int[j]="-"$(j+2)
	getline
	getline
	for (h=1;h<=ncoor;h++) {
		getline
		for (j=1;j<=nimag;j++)
			K[j,h]= $(j+1)*1
		}
	}
#NOW LOW FREQUENCIES
if ( $4 == "low/zero" ) 
	prep=2
if ( $1 == "Wavenumbers" && prep == "2" && nlow != "0" ) {
	#WE MUST SKIP FIRST 6 ZERO FREQUENCIES,THIS WILL COLAPSE IF THEY ARE NOT EXACTLY ZERO!!
	if ( $3 < 1.00 ) {
	       if ( $4 < 1.00 ) {
		       next
		} else {
			tmp = nlow
			if ( nlow > 4 )
				tmp = 4
			for (j=1;j<=tmp;j++) 
				 Int[j+nimag]=$(j+3)
			getline
			getline
			for (h=1;h<=ncoor;h++) {
				getline
				for (j=1;j<=tmp;j++)
					K[j+nimag,h]= $(j+2)*1
			}
	
	       }	
	next
        }
	tmp = nlow-4-5*count
	if ( tmp > 5 ) 
		tmp = 5
	for (j=1;j<=tmp;j++) 
			Int[j+nimag+5*count+4]=$(j+2)
	getline
	getline
	for (h=1;h<=ncoor;h++) {
		getline
		for ( j=1;j<=tmp;j++ )
			K[j+nimag+5*count+4,h]= $(j+1)*1
		}	
	count++
}
}
END{
if (i <= 1) {
	print "File does not contain any frequencies!!!Exiting..."
	exit 3
}
#PRINTING XYZ COORDINATES
for (k=1;k<=N;k++)
print "  ",a[k],"  ",b[k],"  ","0","  ",c[k]/1.8897,"   ",d[k]/1.8897,"   ",e[k]/1.8897 >> "temp"

print " ---------------------------------------------------------------------\n \
   1000 basis functions,   1000 primitive gaussians,   1000 cartesian basis functions \n \
   100 alpha electrons     100 beta electrons\n \
 **********************************************************************\n \
\n \
Harmonic frequencies (cm**-1), IR intensities (KM/Mole), Raman scattering\n\
activities (A**4/AMU), depolarization ratios for plane and unpolarized\n\
incident light, reduced masses (AMU), force constants (mDyne/A),\n\
and normal coordinates:" >> "temp"

#PRINTING NORMAL MODES
for ( j=1;j<=nfreq;j=j+3 ) {
	nr=0
printf "                     %i                      %i                      %i\n",j,j+1,j+2 > "temp"
printf "                     %s                      %s                      %s\n","A","A","A" > "temp"
print " Frequencies --  ",Int[j],"               ",Int[j+1],"               ",Int[j+2] > "temp"
print " Red. masses --     0.0                    0.0                    0.0" > "temp"
print " Frc consts  --     0.0                    0.0                    0.0" > "temp"
print " IR Inten    --     0.0                    0.0                    0.0" > "temp"
print " Atom AN      X      Y      Z        X      Y      Z        X      Y      Z" > "temp"
for (k=1;k<=ncoor;k=k+3) {
       nr++	
printf "%4i %3s",nr,b[nr] > "temp" 
printf "    % 4.2f  % 4.2f  % 4.2f    % 4.2f  % 4.2f  % 4.2f    % 4.2f  % 4.2f  % 4.2f\n",K[j,k],K[j,k+1],K[j,k+2],K[j+1,k],K[j+1,k+1],K[j+1,k+2],K[j+2,k],K[j+2,k+1],K[j+2,k+2] > "temp"
}

}
}' $1 

if [ $? != "0" ];then
        echo "An error encountered.Exiting..."
	exit $? 
fi

molden -A temp

