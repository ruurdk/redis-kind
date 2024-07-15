#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing metallb in cluster $c" 
    
    kubectl config use-context kind-c$c
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
    kubectl apply -f lb-config-c$c.yaml
done
