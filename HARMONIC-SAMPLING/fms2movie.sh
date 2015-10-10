#!/bin/bash

start=1
end=20
PATHTOWIGNER=".."
movie=fmsmovie.xyz

if [[ -e $movie ]];then
   echo "ERROR: File $movie already exists!"
   exit 1
fi
if [[ -e restart.xyz ]];then
   echo "ERROR: File restart.xyz already exists!"
   exit 1
fi
if [[ -e mini.dat ]];then
   echo "ERROR: File mini.dat already exists!"
   exit 1
fi

for ((i=start;i<=end;i++)) {

   ./make_restart -wig $PATHTOWIGNER/FMSINPOUT/Geometry.dat $PATHTOWIGNER/FMSTRAJS/Traj.$i 1 1
   cat mini.dat >> $movie
   rm mini.dat restart.xyz

}
