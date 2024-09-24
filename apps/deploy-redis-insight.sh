#!/bin/bash

# load vars
source /../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Deploying Redis Insight for cluster $c" 
    
    kubectl config use-context kind-c$c
    
    kubectl config set-context --current --namespace=redis
    kubectl apply -f redis-insight.yaml
done