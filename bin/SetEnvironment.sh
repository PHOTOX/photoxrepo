#!/bin/bash

# A simple script that should set the environment
# for a specific program to its most recent version.
# It should work for all PHOTOX clusters.


if [[ -z $1 ]];then
   echo "$0: You did not provide any parameter. Which program you want to use?"
   echo "Available: G09, QCHEM, TERA, MOLPRO, CP2K, DFTB"
   echo "Exiting..."
   exit 1
fi

node=$(uname -a | awk '{print $2}' )
whoami=$(basename $0)

# First, determine where we are. 
# Currently works for as67-1 and a324 clusters.
if [[ "$node" =~ s[0-9] ]] || [[ "$node" = "as67-1" ]];then
   cluster=as67
elif [[ "$node" =~ a[0-9] ]] || [[ "$node" = "403-a324-01" ]];then
   cluster=a324
else
   echo "I did not recognize any of the PHOTOX clusters. Please check the script $0"
   echo "Exiting..."
   exit 1
fi

#--MOLPRO--
if [[ "$1" = "MOLPRO" ]];then
if [[ $cluster = "as67" ]];then
   export  m12root=$(readlink -f /usr/local/programs/molpro/molpro2012.1/arch/amd64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8)
elif [[ $cluster = "a324" ]] ;then
   export  m12root=$(readlink -f /usr/local/programs/common/molpro/molpro2012.1/arch/x86_64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8)
fi
MOLPROEXE=$m12root/bin/molpro
fi
#----------------------------

#--TeraChem--
# Export only for nodes on a324
# Not sure about this...The user might get confused.
if [[ "$1" = "TERA" ]];then
   if [[ "$cluster" -ne "as67" ]] && [[ "$node" -ne "403-a324-01" ]] ;then

      if [ $node = "a25" ];then    #tesla node, we use older and faster version of Terachem
         export TeraChem=/home/hollas/TeraChem/TERACHEM-1.5/
         export NBOEXE=/home/hollas/TeraChem/TERACHEM-1.5/nbo6.exe
         export LD_LIBRARY_PATH=/home/hollas/TeraChem/cudav4.0/cuda/lib64:$LD_LIBRARY_PATH
 
      else    #GTX nody, Kepler version, slower due to software workarounds
 
         export TeraChem=/home/hollas/TeraChem/
         export NBOEXE=/home/hollas/TeraChem/nbo6.exe
         export LD_LIBRARY_PATH=/usr/local/programs/cuda/cuda-5.0/cuda/lib64/:$LD_LIBRARY_PATH
      fi
 
      export TERAEXE=$TeraChem/terachem

   else

      echo "$whoami :You do not appear to be on a machine with GPU. I will not export TeraChem variables."

   fi
 
fi
#-------------------------------------

#--Gaussian--
if [[ "$1" = "G09" ]];then
if [[ $cluster = "as67" ]];then
   export g09root="/home/slavicek/G03/gaussian09/a02/g09"
elif [[ $cluster = "a324" ]] ;then
   export g09root="/home/slavicek/G03/gaussian09/d01/arch/x86_64_sse4.2/g09"
fi
fi


#--QCHEM
if [[ "$1" = "QCHEM" ]];then
   export QC=/usr/local/programs/common/qchem/qchem-4.1/arch/x86_64
fi


#--CP2K--
if [[ "$1" = "CP2K" ]];then
. /home/uhlig/intel/composer_xe_2013_sp1.4.211/bin/compilervars.sh intel64
. /home/uhlig/intel/composer_xe_2013_sp1.4.211/mkl/bin/mklvars.sh intel64
. /home/uhlig/build/libint/1.1.4-icc/env.sh
. /home/uhlig/build/openmpi/1.6.5-icc/env.sh
. /home/uhlig/build/fftw/3.3.4-icc/env.sh

export CP2KEXE=/home/uhlig/build/cp2k/2.5_11122014/cp2k.popt
fi
#----------------------------------------------------


#--DFTB--
if [[ "$1" = "DFTB" ]];then
   export DFTBEXE=~hollas/bin/dftb+
fi

if [[ "$1" = "MOPAC" ]];then
   export MOPAC_LICENSE=/home/hollas/programes/MOPAC2012-CENTOS5
   export MOPACEXE=/home/hollas/programes/MOPAC2012-CENTOS5/MOPAC2012.exe
fi

