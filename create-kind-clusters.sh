#!/bin/bash

# load vars
source config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Creating cluster $c"
    while ! kind create cluster --config kind-cluster-c$c.yaml ; do echo "Attempting to create cluster $c again after failure." ; done
    
    # Echo endpoints
    kubectl cluster-info --context kind-c$c
done