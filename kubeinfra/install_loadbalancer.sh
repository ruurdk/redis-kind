#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing metallb in cluster $c" 
    
    kubectl config use-context kind-c$c
    kubectl apply -f $loadbalancer_release    
    while ! kubectl get svc/webhook-service --namespace metallb-system ; do echo "Waiting for metallb service. CTRL-C to exit."; sleep 5; done
    sleep 5
    kubectl apply -f lb-config-c$c.yaml
done
