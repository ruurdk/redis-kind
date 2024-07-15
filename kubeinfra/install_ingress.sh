#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing nginx controller in cluster $c" 

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
done

