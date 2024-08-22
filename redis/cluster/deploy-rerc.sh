#!/bin/bash

# load vars
source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - DEPLOYING Redis Enterprise REMOTE Cluster on k8s cluster $c" 
    
    kubectl config use-context kind-c$c

    # Share cluster secrets.
    kubectl apply -f all-cluster-creds.yaml
    
    # Create a RE REMOTE cluster - yes we need to do this for all clusters INCLUDING THE LOCAL ONE but only on ONE SIDE
    if [ $c -eq 1 ];
    then
        for k in $(seq 1 $num_clusters);
        do
            kubectl apply -f rerc$k.yaml
        done
    fi
done

# Wait for the RERCs on cluster 1 to be active - this is a prereq for the admission controller to accept a CRDB.
kubectl config use-context kind-c1
for c in $(seq 1 $num_clusters);
do
    while ! kubectl get rerc rerc$c ; do echo "Waiting for rerc$c to become available."; sleep 5 ; done
    while ! kubectl wait --for jsonpath="{.status.status}"=Active --timeout=10s rerc rerc$c ; do echo "Waiting for rerc$c status to be Active." ; sleep 5 ; done
done