#!/bin/bash

# load vars
source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Creating cluster $c"
    echo "$(date) - Using k8s image $k8s_release"

    # splice specific kind version into deployment yaml.
    if [ ! "$k8s_release" == "latest" ]
    then
        yq '.nodes[].image = "'$k8s_release'"'  kind-cluster-c$c.yaml > kind-temp.yaml
    else
        cat kind-cluster-c$c.yaml > kind-temp.yaml
    fi

    while ! kind create cluster --config kind-temp.yaml ; do echo "Attempting to create cluster $c again after failure." ; done
    
    # Echo endpoints
    kubectl cluster-info --context kind-c$c
done