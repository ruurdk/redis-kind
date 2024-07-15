#!/bin/bash

# load vars
source config.sh

# create empty creds file for all clusters.
if [ "$active_active" == "yes" ]; 
then
    > all-cluster-creds.yaml
fi

# deploy the REC for all clusters.
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - DEPLOYING Redis Enterprise Cluster on k8s cluster $c" 
    
    kubectl config use-context kind-c$c

    # Create a RE cluster
    kubectl apply -f rec-c$c.yaml
    #kubectl port-forward svc/rec-ui 8443:8443
    #kubectl port-forward --address localhost,0.0.0.0  svc/rec-ui 8443:8443 &

    sleep 1

    # output creds.
    pw=$(kubectl get secret rec-c$c -o jsonpath="{.data.password}" | base64 --decode) 
    user=$(kubectl get secret rec-c$c -o jsonpath="{.data.username}" | base64 --decode) 
    echo "$(date) - RE credentials user: $user - password: $pw" 
    # write creds to all creds file.
    cat << EOF >> all-cluster-creds.yaml
apiVersion: v1
data:
  password: $(echo $pw | base64)
  username: $(echo $user | base64)
kind: Secret
metadata:
  name: redis-enterprise-rerc-c$c
type: Opaque
---
EOF

done

# Waiting for REC to come up.
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Waiting for REC on cluster $c to be operational" 
    
    kubectl config use-context kind-c$c
    kubectl rollout status sts/rec-c$c
done

# Set up A/A artifacts.
if [ "$active_active" == "yes" ]; 
then
    echo "$(date) - Setting up active-active"

    cd kubeinfra
    ./install_loadbalancer.sh
    cd ..

    ./deploy-rerc.sh
fi