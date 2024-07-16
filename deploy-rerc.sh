#!/bin/bash

# load vars
source config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - DEPLOYING Redis Enterprise REMOTE Cluster on k8s cluster $c" 
    
    kubectl config use-context kind-c$c

    # Share cluster secrets.
    kubectl apply -f all-cluster-creds.yaml
    
    # Create a RE REMOTE cluster - yes we need to do this for all clusters INCLUDING THE LOCAL ONE
    # but only one ONE SIDE
    if [ $c -eq 1 ];
    then
        for k in $(seq 1 $num_clusters);
        do
            kubectl apply -f rerc$k.yaml
        done
    fi
done