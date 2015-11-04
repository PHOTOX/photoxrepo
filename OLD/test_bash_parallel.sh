#!/bin/bash

# Simple script demonstrating running tasks in parallel
# using nproc CPUs

nproc=4
ntask=11

for ((i=1;i<=ntask;i=i+nproc)) {

for ((j=0;j<nproc;j++)) {

let ii=i+j
echo $ii
if [[ $ii -gt $ntask ]];then
   break
fi

(sleep $ii; echo "End of sleep $ii") &

}
wait

}

echo "After for"
