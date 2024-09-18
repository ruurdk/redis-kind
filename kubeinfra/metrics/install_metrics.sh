#!/bin/bash

source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing metrics server in cluster $c" 
    
    kubectl config use-context kind-c$c

    kubectl apply -f $metrics_server_release

    # Patch the deployment to not check kubelet TLS certificates.
    kubectl patch deployment -n kube-system metrics-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--kubelet-insecure-tls"}]'
done