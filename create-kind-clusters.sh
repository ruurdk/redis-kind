#!/bin/bash

# load vars
source config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Creating cluster $c"
    kind create cluster --config kind-cluster-c$c.yaml

    # Echo endpoints
    kubectl cluster-info --context kind-c$c
done