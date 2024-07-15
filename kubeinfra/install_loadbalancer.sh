#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing metallb in cluster $c" 
    
    kubectl config use-context kind-c$c
    kubectl apply -f $loadbalancer_release    
    # TODO: check for readiness before continuing, needs rerun now if ingress controller wait stuck
    kubectl apply -f lb-config-c$c.yaml
done
