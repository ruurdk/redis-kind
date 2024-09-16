#!/bin/bash

# load vars
source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Creating cluster $c"
    echo "$(date) - Using k8s image $k8s_release"

    # generate cluster manifest from template.
    yq '. |= { name: "c'$c'" } + .' kind-cluster-template.yaml > kind-cluster-c$c.yaml

    # add nodes.
    for n in $(seq 1 $control_nodes);
    do
        yq -iy '.nodes += [ {"role": "control-plane"}]' kind-cluster-c$c.yaml
    done
    for n in $(seq 1 $worker_nodes);
    do
        yq -iy '.nodes += [ {"role": "worker"}]' kind-cluster-c$c.yaml
    done

    # add network ranges.
    yq -iy '.networking.podSubnet = "10.1'$c'0.0.0/16"' kind-cluster-c$c.yaml
    yq -iy '.networking.serviceSubnet = "10.1'$c'1.0.0/16"' kind-cluster-c$c.yaml
    
    # splice specific kind version into deployment yaml.
    if [ ! "$k8s_release" == "latest" ]
    then
        yq -iy '.nodes[].image = "'$k8s_release'"' kind-cluster-c$c.yaml
    fi

    while ! kind create cluster --config kind-cluster-c$c.yaml ; do echo "Attempting to create cluster $c again after failure." ; done
    
    # Echo endpoints
    kubectl cluster-info --context kind-c$c
done