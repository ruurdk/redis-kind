#!/bin/bash

# load vars
source config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - DEPLOYING Redis Enterprise REMOTE Cluster on k8s cluster $c" 
    
    kubectl config use-context kind-c$c

    # Share cluster secrets.
    kubectl apply -f all-cluster-creds.yaml
    
    # Create a RE REMOTE cluster.
    kubectl apply -f rerc$c.yaml
done