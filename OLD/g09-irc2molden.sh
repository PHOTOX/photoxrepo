#!/bin/bash
#
#This is a simple awk script for striping IRC path out of G09 *.log files

if [ -z "$1" ];then
	echo "USAGE: $0 [G09.log]"
	echo 
	echo "Script for extracting of IRC path out of G09 output for visualization in molden."
	echo "Molden data are stored in temporary file ""irc.out"". Quit molden with ""Ctrl+C"" in order to access this file."
	exit 1
fi

if [ ! -e $1 ];then
	echo "File $1 does not exists."
	echo "USAGE: $0 [molpro.output]"
	exit 1
fi
rm irc.out

awk '{
	if ( $1 == "Charge" ) {
		getline 
		NA++
		AT[NA]=$1
		getline
		while ( $2 ~ /[0-9]/ ) {
			NA++
			AT[NA]= $1
			getline
		}
	}

	if ($1 == "Center" && $3 == "Atomic") {
		print "  "NA >> "irc.out"
		getline
	        print "" >> "irc.out"
		getline
		getline
		for ( i=1;i<=NA;i++ ) {
			printf "%2s   % 4.6f  % 4.6f  % 4.6f\n", AT[i],$4,$5,$6 >> "irc.out"
			getline
		}

	}
}' $1 

if [ $? != 0 ];then 
	echo "An error encountered. Exiting..."
	exit $?
fi

molden -A irc.out

rm irc.out

