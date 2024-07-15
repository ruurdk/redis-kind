#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing ingress controller in cluster $c" 

    kubectl config use-context kind-c$c
    kubectl apply -f $ingresscontroller_release
done

