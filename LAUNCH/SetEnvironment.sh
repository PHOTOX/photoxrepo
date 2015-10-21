#!/bin/bash

# A simple script that sets the environment for a specific program.
# It should point to the newest version that is available on our clusters.
# This script should work for all PHOTOX clusters.

program=$1
# Optional second parameter
if [[ -z $2 ]];then
   version=default
else
   version=$2
fi 

node=$(uname -a | awk '{print $2}' )

 function print_help {
   echo "USAGE: . SetEnvironment.sh PROGRAM [VERSION]"
   echo ""
   echo "Available programs are:"
   echo " " 
   echo "${PROGRAMS[@]}" 
   echo " " 
   echo "To find out all available versions of a given PROGRAM, type:"
   echo "SetEnvironment.sh PROGRAM --versions"
   echo "Exiting..."
   return 0
}

function set_version {
   # Check whether given version is available
   for vers in ${VERSIONS[@]};do
      if [[ $version = $vers ]];then
         return 0
      fi
   done

   # Set the default version (first in array VERSIONS)
   if [[ $version = "default" ]];then
      version=${VERSIONS[0]}
      return 0
   fi

   # print available versions if user requests illegal version
   if [[ $ver != "--versions" ]];then
      echo 1>&2 "Version $version is not available!" 
   fi

   echo 1>&2 "Available versions are:"
   for vers in ${VERSIONS[@]};do
      echo 1>&2  $vers
   done
   echo ""
   return 1
}

# First, determine where we are. 
# Currently works for as67-1 and a324 clusters.
if [[ "$node" =~ ^s[0-9]+$|as67-1 ]];then
   cluster=as67
elif [[ "$node" =~ ^a[0-9]+$|403-a324-01 ]];then
   cluster=a324
elif [[ "$node" =~ ^n[0-9]+$|403-as67-01  ]];then
   cluster=as67gpu
else
   echo "I did not recognize any of the PHOTOX clusters. Please check the script SetEnvironment.sh"
   echo "Exiting..."
   return 1
fi

if [[ $cluster = "as67" ]];then
   PROGRAMS=(GAUSSIAN QCHEM MOLPRO CP2K DFTB ORCA TURBOMOLE MOPAC GROMACS )
elif [[ $cluster = "a324" ]];then
   PROGRAMS=(GAUSSIAN QCHEM MOLPRO CP2K DFTB ORCA TERACHEM SHARC MOPAC )
elif [[ $cluster = "as67gpu" ]];then
   PROGRAMS=( QCHEM MOLPRO CP2K DFTB ORCA NWCHEM TERACHEM MOPAC GROMACS )
fi


if [[ -z $1 ]];then
   echo "SetEnvironment.sh: You did not provide any parameter. Which program do you want to use?"
   print_help 
   return 1
fi

# Check whether $program is available 
available=False
for k in ${!PROGRAMS[@]};do
    if [[ "$program" = ${PROGRAMS[$k]} ]];then
       available=True
       break
    fi
done

if [[ $available = "False" ]];then
   echo "ERROR: Program $program is not available on this cluster."
   print_help 
fi

# declaration of associative BASH arrays
declare -A NWCHEM GROMACS ORCA CP2K MOLPRO MOLPRO_MPI GAUSS DFTB TURBO TERA MOPAC SHARCH QCHEM QCHEM_MPI


case "$program" in
   "MOLPRO" )
      VERSIONS=( 2012 )
      if [[ $cluster = "as67" ]];then
         MOLPRO[2012]=$(readlink -f /usr/local/programs/molpro/molpro2012.1/arch/amd64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8)
         MOLPRO_MPI[2012]=$(readlink -f /usr/local/programs/molpro/molpro2012.1/arch/amd64-intel_12.0.5.220-openmpi_1.6.2/molprop_2012_1_Linux_x86_64_i8)
         export MPIDIR=/usr/local/programs/common/openmpi/openmpi-1.6.5/arch/amd64-intel_12.0.5.220
      else
         MOLPRO[2012]=$(readlink -f /usr/local/programs/common/molpro/molpro2012.1/arch/x86_64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8)
         MOLPRO_MPI[2012]=$(readlink -f /usr/local/programs/common/molpro/molpro2012.1/arch/x86_64-intel_12.0.5.220-openmpi_1.6.2/molprop_2012_1_Linux_x86_64_i8)
         export MPIDIR=/usr/local/programs/common/openmpi/openmpi-1.6.2/arch/x86_64-intel_12.0.5.220
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export m12root=${MOLPRO[$version]}
      export m12_mpiroot=${MOLPRO_MPI[$version]}
      export MOLPROEXE=$m12root/bin/molpro
      export MOLPROEXE_MPI=$m12_mpiroot/bin/molpro
      ;;

   "GAUSSIAN" )
      if [[ $cluster = "as67" ]];then
         VERSIONS=( G09.A02 )
      else
         VERSIONS=( G09.D01 G09.A02 )
      fi
      GAUSS[G09.A02]="/home/slavicek/G03/gaussian09/a02/g09"
      GAUSS[G09.D01]="/home/slavicek/G03/gaussian09/d01/arch/x86_64_sse4.2/g09"

      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export gaussroot=${GAUSS[$version]}
      GAUSSEXE=$gaussroot/g09
      ;;

   "DFTB" )
      VERSIONS=( 1.2 )
      DFTB[1.2]=/home/hollas/bin/dftb+
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export DFTBEXE=${DFTB[$version]}
      ;;

   "TURBO" )
      VERSIONS=( 6.0 )
      TURBO[6.0]=/home/oncakm/TurboMole-6.0
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export turboroot=${TURBO[$version]}
      export PATH=$turboroot/scripts:$PATH
      export PATH=$turboroot/bin/x86_64-unknown-linux-gnu:$PATH
      ;;

   "TERACHEM" )
      if [[ $cluster = "as67gpu" || $node = "a32" || $node = "a33" ]];then
         VERSIONS=( dev )
      elif [[ $node = "a25" ]];then
         VERSIONS=( 1.5K 1.5 dev )
      else
         VERSIONS=( 1.5K dev )
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      TERA[dev]=/home/hollas/programes/TeraChem-dev/build_mpich
      TERA[1.5]=/home/hollas/TeraChem/TERACHEM-1.5/
      TERA[1.5K]=/home/hollas/TeraChem/
      export TeraChem=${TERA[$version]}
      export TERAEXE=$TeraChem/terachem
      export NBOEXE=/home/hollas/TeraChem/nbo6.exe
      if [[ $version -eq "dev" ]];then
         export LD_LIBRARY_PATH=$TeraChem/lib:$LD_LIBRARY_PATH
         export LD_LIBRARY_PATH=/home/hollas/programes/mpich-3.1.3/arch/x86_64-intel-2015-update5/lib/:$LD_LIBRARY_PATH
         export TERAEXE=$TeraChem/bin/terachem
      elif [[ $version -eq "1.5K" ]];then
         export LD_LIBRARY_PATH=/usr/local/programs/cuda/cuda-5.0/cuda/lib64/:$LD_LIBRARY_PATH
      elif [[ $version -eq "1.5" ]];then
         export LD_LIBRARY_PATH=/home/hollas/TeraChem/cudav4.0/cuda/lib64:$LD_LIBRARY_PATH
      fi
      ;;

   "CP2K" )
      if [[ $cluster = "as67gpu" ]];then
         VERSIONS=( 2.6.2 )
         CP2K[2.6]=/home/hollas/programes/src/cp2k-2.6.2/exe/Linux-x86-64-gfortran-mkl/
         MPIRUN=/home/hollas/programes/mpich-3.1.3/arch/x86_64-gcc/bin/mpirun
      else
         VERSIONS=( 2.5 )
         . /home/uhlig/intel/composer_xe_2013_sp1.4.211/bin/compilervars.sh intel64
         . /home/uhlig/intel/composer_xe_2013_sp1.4.211/mkl/bin/mklvars.sh intel64
         . /home/uhlig/build/libint/1.1.4-icc/env.sh
         . /home/uhlig/build/libxc/2.1.2-icc/env.sh
         . /home/uhlig/build/openmpi/1.6.5-icc/env.sh
         . /home/uhlig/build/fftw/3.3.4-icc/env.sh
         MPIRUN=mpirun
      fi
      if [[ $cluster = "as67" ]];then
         CP2K[2.5]=/home/uhlig/build/cp2k/2_5_12172014/
      elif [[ $cluster = "a324" ]];then
         CP2K[2.5]=/home/uhlig/build/cp2k/2.5_11122014/
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi

      export cp2kroot=${CP2K[$version]}
      export cp2k_mpiroot=${CP2K[$version]}
      export CP2KEXE_MPI=$cp2k_mpiroot/cp2k.popt
      if [[ $cluster = "as67gpu" ]];then 
         export CP2KEXE=$cp2kroot/cp2k.sopt
      else
         export CP2KEXE=$cp2k_mpiroot/cp2k.popt # Frank does not have an sopt version
      fi
      ;;

   "ORCA" )
      VERSIONS=(3.0.3 3.0.2 3.0.0 )
      if [[ $cluster = "as67" ]];then
         VERSIONS[2]=3.0.0    # old version for debug purposes
      fi
      ORCA[3.0.0]=/home/guest/programs/orca/orca_3_0_0_linux_x86-64/
      ORCA[3.0.2]=/home/guest/programs/orca/orca_3_0_2_linux_x86-64/
      ORCA[3.0.3]=/home/guest/programs/orca/orca_3_0_2_linux_x86-64/
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      orcaroot=${ORCA[$version]}
      export ORCAEXE=$orcaroot/orca
      if [[ $cluster = "as67" ]];then
         source /usr/local/programs/common/openmpi/openmpi-1.6.5/arch/amd64-gcc_4.3.2-settings.sh
      else
         source /usr/local/programs/common/openmpi/openmpi-1.6.5/arch/x86_64-gcc_4.4.5-settings.sh
      fi
      ;;

   "SHARC" )
      VERSIONS=(1.01)
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      if [[ $cluster = "as67" ]];then
         export MOLPRO=$(readlink -f /usr/local/programs/molpro/molpro2012.1/arch/amd64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8/bin)
      else
         export MOLPRO=$(readlink -f /usr/local/programs/common/molpro/molpro2012.1/arch/x86_64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8/bin)
      fi
      export SHARC=/home/hollas/programes/src/sharc/bin/
      export SCRADIR=/scratch/$USER/scr-sharc-generic_$$
      echo "Don't forget to set your own unique SCRADIR"
      echo "export SCRADIR=/scratch/$USER/scr-sharc-yourjob/"
      ;;

   "MOPAC" )
      VERSIONS=(2012.15.168 2012.older)
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      MOPAC[2012.15.168]=/usr/local/bin/mopac
      if [[ $cluster = "as67" ]];then
         #Somewhat older version, but cannot determine which
         export MOPAC_LICENSE=/home/hollas/programes/MOPAC2012-CENTOS5
         export MOPACEXE=/home/hollas/programes/MOPAC2012-CENTOS5/MOPAC2012.exe
      else
         export MOPACEXE=${MOPAC[2012]}
      fi
      ;;
   "GROMACS" )
      if [[ $cluster = "as67gpu" ]];then
         VERSIONS=(5.1, 5.1_GPU )
         GROMACSEXE=gmx
      elif [[ $cluster = "as67" ]];then
         VERSIONS=(4.5.5)
         GROMACSEXE=mdrun_d
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      GROMACS[5.1]=/home/hollas/programes/gromacs/5.1-gnu/
      GROMACS[5.1_GPU]=/home/hollas/programes/gromacs/5.1-gnu-gpu/
      if [[ $cluster = "as67" ]];then
         source /home/hollas/programes/src/gromacs-4.5.5/scripts/GMXRC.bash
      else
         source ${GROMACS[$version]}/bin/GMXRC.bash
      fi
      ;;

   "QCHEM" )
      VERSIONS=(4.1)
      if [[ $cluster = "as67" ]];then
         QCHEM[4.1]=/usr/local/programs/common/qchem/qchem-4.1/arch/x86_64
         QCHEM_MPI[4.1]=/usr/local/programs/common/qchem/qchem-4.1/arch/x86_64-openmpi_1.6.5
         source /usr/local/programs/common/openmpi/openmpi-1.6.5/arch/amd64-gcc_4.3.2-settings.sh
      else
         QCHEM[4.1]=/usr/local/programs/common/qchem/qchem-4.1/arch/x86_64
         QCHEM_MPI[4.1]=/usr/local/programs/common/qchem/qchem-4.1/arch/x86_64-openmpi_1.6.5
         source /usr/local/programs/common/openmpi/openmpi-1.6.5/arch/x86_64-gcc_4.4.5-settings.sh
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi

      export qcroot=${QCHEM[$version]}
      export qc_mpiroot=${QCHEM_MPI[$version]}
      export QCEXE=$qcroot/bin/qchem
      export QCEXE_MPI=$qc_mpiroot/bin/qchem
      ;;

   "NWCHEM" )
      if [[ $cluster = "as67gpu" ]];then
        VERSIONS=(6.6-beta)
      fi
      NWCHEM[6.6-beta]=/home/hollas/programes/src/nwchem-6.6/
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export LD_LIBRARY_PATH=/home/hollas/programes/mpich-3.1.3/arch/x86_64-gcc/lib/:$LD_LIBRARY_PATH
      export MPIRUN=/home/hollas/programes/mpich-3.1.3/arch/x86_64-gcc/bin/mpirun
      export nwchemroot=${NWCHEM[$version]}
      export NWCHEMEXE=$nwchemroot/bin/LINUX64/nwchem
      if [[ ! -d "/scratch/$USER/nwchem_scratch" ]];then
         mkdir /scratch/hollas/nwchem_scratch
      fi
      if [[ ! -f "/home/$USER/.nwchemrc" ]];then
         cat > "/home/$USER/.nwchemrc" << EOF
 nwchem_basis_library $nwchemroot/src/basis/libraries/
 nwchem_nwpw_library $nwchemroot/src/nwpw/libraryps/
 ffield amber
 amber_1 $nwchemroot/src/data/amber_s/
 amber_2 $nwchemroot/src/data/amber_q/
 amber_3 $nwchemroot/src/data/amber_x/
 amber_4 $nwchemroot/src/data/amber_u/
 spce   $nwchemroot/src/data/solvents/spce.rst
 charmm_s $nwchemroot/src/data/charmm_s/
 charmm_x $nwchemroot/src/data/charmm_x/
EOF
      fi
      ;;

   * ) 
      echo "$program is not a valid program!"
      print_help
      ;;
esac
#----------------------------
#echo "Exporting variables for $program version $version "


