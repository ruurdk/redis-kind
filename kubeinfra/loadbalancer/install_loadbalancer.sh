#!/bin/bash

source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing metallb in cluster $c" 
    
    kubectl config use-context kind-c$c
    kubectl apply -f $loadbalancer_release    
    # wait for service
    while ! kubectl get svc/metallb-webhook-service --namespace metallb-system ; do echo "Waiting for metallb service. CTRL-C to exit."; sleep 5; done
    # wait for all pods to be running
    kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=120s
    while ! kubectl apply -f lb-config-c$c.yaml ; do echo "waiting for metallb config to take." ; sleep 1; done
done
