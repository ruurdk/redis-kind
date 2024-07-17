#!/bin/bash

# load vars
source config.sh

if [ "$active_active" == "yes" ]; 
then
    echo "$(date) - DEPLOYING Redis Enterprise A/A database on k8s cluster 1" 

    kubectl config use-context kind-c1
    # do the below in 2 steps or the admission controller will deny it
    kubectl apply -f reaadb_secret.yaml
    kubectl apply -f reaadb.yaml
fi

# TODO implement non-A/A db creation.