#!/bin/bash

# load vars
source ../../config.sh

wget $logcollector_release -O lc.py
chmod +x lc.py

# log collector for every cluster.
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Running log collector for cluster $c" 
    
    kubectl config use-context kind-c$c

    python3 lc.py -n redis
done

rm lc.py