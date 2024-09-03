#!/bin/bash

source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing metallb in cluster $c" 
    
    kubectl config use-context kind-c$c

    # Install metallb.
    kubectl apply -f $loadbalancer_release    
    # wait for service
    while ! kubectl get svc/metallb-webhook-service --namespace metallb-system ; do echo "Waiting for metallb service. CTRL-C to exit."; sleep 5; done
    # wait for all pods to be running
    kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=120s

    # Configure ip ranges and advertisement.
    yq -y '.spec.addresses[0] = "172.18.25'$c'.2-172.18.25'$c'.254"' ipaddresspool-template.yaml > ipaddresspool-c$c.yaml    
    while ! kubectl apply -f ipaddresspool-c$c.yaml ; do echo "waiting for metallb config to take." ; sleep 1; done

    while ! kubectl apply -f l2advertisement.yaml ; do echo "waiting for metallb config to take." ; sleep 1; done

done
