#!/bin/bash

# load vars
source ../../config.sh

# support package for every cluster.
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Generating Redis support package for cluster $c" 
    
    kubectl config use-context kind-c$c

    kubectl -n redis exec -it rec$c-0 -- rladmin cluster debug_info
    LASTDEBUGINFOFILE=`kubectl -n redis exec -it rec$c-0 -- bash -c 'cd /tmp;ls -1rt debuginfo.*' | tail -n1 | sed 's/\r//'`
    kubectl -n redis cp rec$c-0:/tmp/${LASTDEBUGINFOFILE} rec$c-${LASTDEBUGINFOFILE}
done