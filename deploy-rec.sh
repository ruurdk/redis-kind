#!/bin/bash

# load vars
source config.sh

# create empty creds file for all clusters.
> all-cluster-creds.yaml

# deploy the REC for all clusters.
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - DEPLOYING Redis Enterprise Cluster on k8s cluster $c" 
    
    kubectl config use-context kind-c$c

    # Create a RE cluster
    kubectl apply -f rec-c$c.yaml
    #kubectl port-forward --address localhost,0.0.0.0  svc/rec-ui 8443:8443 &

    while ! kubectl get secret rec-c$c; do echo "Waiting for secret rec-c$c. CTRL-C to exit."; sleep 1; done

    # output creds.
    pw=$(kubectl get secret rec-c$c -o jsonpath="{.data.password}") 
    user=$(kubectl get secret rec-c$c -o jsonpath="{.data.username}") 
    echo "$(date) - RE credentials user: $(echo $user | base64 --decode) - password: $(echo $pw | base64 --decode)" 
    # write creds to all creds file.
    cat << EOF >> all-cluster-creds.yaml
apiVersion: v1
data:
  password: $pw
  username: $user
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
    echo "$(date) - Setting up active-active LB, Ingress, DNS infrastructure"

    cd kubeinfra
    ./install_loadbalancer.sh
    ./install_ingresscontroller.sh
    ./add_dnsrecords.sh
    cd ..

    ./deploy-rerc.sh
fi