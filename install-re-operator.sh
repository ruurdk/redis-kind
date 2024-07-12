#!/bin/bash

# load vars
source config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - INSTALLING Redis Enterprise - with operator on cluster $c" 
    git clone https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
    cd redis-enterprise-k8s-docs/

    kubectl config use-context kind-c$c
    kubectl create namespace redis
    kubectl config set-context --current --namespace=redis
    kubectl apply -f bundle.yaml
    sleep 1
    while ! kubectl wait --for condition=established --timeout=10s crd/redisenterpriseclusters.app.redislabs.com ; do sleep 1 ; done

    cd ..
    rm -rf redis-enterprise-k8s-docs/
done