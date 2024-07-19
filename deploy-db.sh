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


    # create networking across clusters for nginx-ingress (as it doesn't pick up the automated Ingress).
    if [ "$install_ingress" == "yes" ];
    then
        if [ "$ingresscontroller_type" == "nginx-ingress" ];
        then            
            for c in $(seq 1 $num_clusters);
            do
                kubectl config use-context kind-c$c
                # TODO hardwired again to db1 name.
                db_port=$(kubectl get svc/db1 -o jsonpath="{.spec.ports[0].port}")
                hostname=$(kubectl get ing/db1 -o jsonpath="{.spec.rules[0].host}")
                sed "s/HOSTNAME/${hostname}/g" ts-ssl-template.yaml | sed "s/SERVICE/db1/g" | sed "s/PORT/${db_port}/g" | sed "s/TS_NAME/tsdb1/g" | kubectl create -f -
            done
        fi
    fi
fi

# TODO implement non-A/A db creation.