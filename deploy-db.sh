#!/bin/bash

# load vars
source config.sh

if [ "$active_active" == "yes" ]; 
then
    echo "$(date) - DEPLOYING Redis Enterprise A/A database on k8s cluster 1" 

    kubectl config use-context kind-c1
    # do the below (secret, db creation) in 2 steps or the admission controller will deny it
    kubectl apply -f reaadb_secret.yaml
    while ! kubectl get secret db1secret; do echo "Waiting for secret db1secret. CTRL-C to exit."; sleep 1; done

    kubectl apply -f reaadb.yaml
    # wait for resource
    while ! kubectl get reaadb db1 ; do echo "Waiting for Redis A/A db to become available."; sleep 1 ; done
    while ! kubectl wait --for jsonpath="{.status.status}"=active --timeout=10s reaadb db1 ; do echo "Waiting for db1 status to be Active." ; sleep 5 ; done
    
    # create networking across clusters for nginx-ingress (as it doesn't pick up the automated Ingress).
    if [ "$install_ingress" == "yes" ];
    then
        if [ "$ingresscontroller_type" == "nginx-ingress" ];
        then            
            for c in $(seq 1 $num_clusters);
            do
                kubectl config use-context kind-c$c

                # TODO hardwired again to db1 name.
                while ! kubectl get svc/db1 ; do echo "Waiting for db1 service to become available."; sleep 5 ; done
                db_port=$(kubectl get svc/db1 -o jsonpath="{.spec.ports[0].port}")
                hostname=$(kubectl get ing/db1 -o jsonpath="{.spec.rules[0].host}")
                sed "s/HOSTNAME/${hostname}/g" ts-ssl-template.yaml | sed "s/SERVICE/db1/g" | sed "s/PORT/${db_port}/g" | sed "s/TS_NAME/tsdb1/g" | kubectl create -f -
            done
        fi
    fi

    # wait for replication link to first remote cluster to get up
    while ! kubectl wait --for jsonpath="{.status.participatingClusters[1].replicationStatus}"=up --timeout=120s reaadb db1 ; do echo "Waiting for db1 replication link to first remote cluster to be up." ; sleep 5 ; done
fi

# TODO implement non-A/A db creation.