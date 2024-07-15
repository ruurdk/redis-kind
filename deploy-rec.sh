#!/bin/bash

# load vars
source config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - DEPLOYING Redis Enterprise Cluster on k8s cluster $c" 
    
    kubectl config use-context kind-c$c

    # Create a RE cluster
    kubectl apply -f rec.yaml
    #kubectl port-forward svc/rec-ui 8443:8443
    #kubectl port-forward --address localhost,0.0.0.0  svc/rec-ui 8443:8443 &

    pw=$(kubectl get secret rec -o jsonpath="{.data.password}" | base64 --decode) 
    user=$(kubectl get secret rec -o jsonpath="{.data.username}" | base64 --decode) 
    echo "$(date) - RE credentials user: $user - password: $pw" 
done

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Waiting for REC on cluster $c to be operational" 
    
    kubectl config use-context kind-c$c
    kubectl rollout status sts/rec
done

if [ "$active_active" == "yes" ]; 
then
    echo "$(date) - Setting up active-active"

    kubeinfra/install_loadbalancer.sh
fi