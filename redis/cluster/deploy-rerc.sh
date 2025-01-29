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
            # Create definition from template.
            yq '.metadata.name = "rerc'$k'"' remotecluster-template.yaml > rerc$k.yaml
            yq -iy '.spec.recName = "rec'$k'"' rerc$k.yaml 
            yq -iy '.spec.apiFqdnUrl = "api-rec'$k'-redis.lab"' rerc$k.yaml 
            yq -iy '.spec.dbFqdnSuffix = "-db-rec'$k'-redis.lab"' rerc$k.yaml 
            yq -iy '.spec.secretName = "redis-enterprise-rerc'$k'"' rerc$k.yaml 

            if [ "$active_active" == "yes" ];
            then
            if [ "$install_ingress" == "yes" ];
            then
            if [ "$ingresscontroller_type" == "no_ingress_use_loadbalancer" ];
            then
                # Patch API port on the RERC spec (no ingress).
                yq -iy '.spec.apiPort = 9443' rerc$k.yaml 
            fi
            fi
            fi

            # Apply the definition.
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