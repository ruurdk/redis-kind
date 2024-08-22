#!/bin/bash

# load vars
source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - INSTALLING Redis Enterprise - with operator on cluster $c" 
    git clone $operator_release reop
    cd reop

    kubectl config use-context kind-c$c
    kubectl create namespace redis
    kubectl config set-context --current --namespace=redis
    kubectl apply -f bundle.yaml
    while ! kubectl get crd/redisenterpriseclusters.app.redislabs.com ; do echo "Waiting for my RE operator CRD creation. CTRL-C to exit."; sleep 1; done
    while ! kubectl wait --for condition=established --timeout=10s crd/redisenterpriseclusters.app.redislabs.com ; do echo "Waiting for CRD to be established." ; sleep 1 ; done

    cd ..
    rm -rf reop
done