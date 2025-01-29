#!/bin/bash

# load vars
source ../../config.sh

if [ "$active_active" == "yes" ]; 
then
    echo "$(date) - DEPLOYING Redis Enterprise A/A database on k8s cluster 1" 

    # do the below (secret, db creation) in 2 steps or the admission controller will deny it
    echo "$(date) - Create secrets on all participating clusters"
    for c in $(seq 1 $num_clusters);
    do
        kubectl config use-context kind-c$c

        kubectl apply -f db_secret.yaml
        while ! kubectl get secret db1secret; do echo "Waiting for secret db1secret. CTRL-C to exit."; sleep 1; done
    done

    # The database only requires creation on 1 side.
    kubectl config use-context kind-c1

    # Prepare reaadb manifest based on template.
    cp aa_database_template.yaml reaadb.yaml
    for c in $(seq 1 $num_clusters);
    do
        yq -iy '.spec.participatingClusters += [{ "name" : "rerc'$c'"}]' reaadb.yaml
    done
    # For rack zone awareness, add to yaml.
    if [ "$rackzone_aware" == "yes" ]; then
      yq -iy '.spec.globalConfigurations.rackAware = true' reaadb.yaml
    fi

    # For Ingress-less (loadbalancer) deployments, specify a port number.    
    if [ "$install_ingress" == "yes" ];
    then
        if [ "$ingresscontroller_type" == "no_ingress_use_loadbalancer" ];
        then
            # Patch API port on the RERC spec (no ingress). Random number between 13000 - 17000 (roughly).
            DBPORT=$((13000 + $RANDOM % 1000))
            yq -iy '.spec.globalConfigurations.databasePort = '$DBPORT reaadb.yaml 
        fi
    fi            

    kubectl apply -f reaadb.yaml
    # wait for resource
    while ! kubectl get reaadb db1 ; do echo "Waiting for Redis A/A db to become available."; sleep 1 ; done
    while ! kubectl wait --for jsonpath="{.status.status}"=active --timeout=10s reaadb db1 ; do echo "Waiting for db1 status to be Active." ; sleep 5 ; done
    
    # create networking across clusters for nginx-ingress (as it doesn't pick up the automated Ingress).
    if [ "$install_ingress" == "yes" ];
    then
        case $ingresscontroller_type in 
            "ingress-nginx" | "haproxy-ingress")
                # nothing to do here, these are auto-wired by RE operator
                ;;
            "no_ingress_use_loadbalancer")
                # nothing to do here in terms of ingress, dbs using replication through database port (loadbalancer)                
                ;;
            "nginx-ingress")
                for c in $(seq 1 $num_clusters);
                do
                    kubectl config use-context kind-c$c

                    # TODO hardwired again to db1 name.
                    while ! kubectl get svc/db1 ; do echo "Waiting for db1 service to become available."; sleep 5 ; done
                    db_port=$(kubectl get svc/db1 -o jsonpath="{.spec.ports[0].port}")
                    hostname=$(kubectl get ing/db1 -o jsonpath="{.spec.rules[0].host}")
                    sed "s/HOSTNAME/${hostname}/g" ../../kubeinfra/ingress/ts-ssl-template.yaml | sed "s/SERVICE/db1/g" | sed "s/PORT/${db_port}/g" | sed "s/TS_NAME/tsdb1/g" | kubectl create -f -
                done
                ;;        
            "contour")
                for c in $(seq 1 $num_clusters);
                do
                    kubectl config use-context kind-c$c

                    # TODO hardwired again to db1 name.
                    while ! kubectl get svc/db1 ; do echo "Waiting for db1 service to become available."; sleep 5 ; done
                    db_port=$(kubectl get svc/db1 -o jsonpath="{.spec.ports[0].port}")
                    hostname=$(kubectl get ing/db1 -o jsonpath="{.spec.rules[0].host}")
                    sed "s/HOSTNAME/${hostname}/g" ../../kubeinfra/ingress/httpproxy-template.yaml | sed "s/SERVICE/db1/g" | sed "s/PORT/${db_port}/g" | sed "s/HP_NAME/hpdb1/g" | kubectl create -f -
                done
                ;;
            *)
                echo "$(date) - WARNING - could not wire database ingress with unknown ingress, A/A database replication link will likely fail"
                ;;
        esac
    fi

    # In case of A/A through LB, we need to refresh DNS records after the DB LBs are created so the replication link can come up.
    if [ "$ingresscontroller_type" == "no_ingress_use_loadbalancer" ];
    then
        echo "$(date) - Refreshing DNS records to loadbalanced A/A databases."

        cd ../../kubeinfra/dns
        ./add_dnsrecords.sh
        cd -
    fi

    # wait for replication link to first remote cluster to get up
    if [ $num_clusters -gt 1 ];
    then
        while ! kubectl wait --for jsonpath="{.status.participatingClusters[1].replicationStatus}"=up --timeout=120s reaadb db1 ; do echo "Waiting for db1 replication link to first remote cluster to be up." ; sleep 5 ; done
    else
        echo "$(date) - Skipping replication link check with a single cluster."
    fi
else

    # regular (non-A/A) db creation.
    echo "$(date) - DEPLOYING Redis Enterprise database on k8s cluster 1" 

    kubectl config use-context kind-c1
    
    cp regular_database_template.yaml redb.yaml
    # For rack zone awareness, add to yaml.
    if [ "$rackzone_aware" == "yes" ]; then
      yq -iy '.spec.rackAware = true' redb.yaml
    fi

    # do the below (secret, db creation) in 2 steps or the admission controller will deny it
    kubectl apply -f db_secret.yaml
    while ! kubectl get secret db1secret; do echo "Waiting for secret db1secret. CTRL-C to exit."; sleep 1; done
    
    # retry this in case of "frozen REC" message.
    while ! kubectl apply -f redb.yaml ; do echo "Waiting for Redis cluster to accept database specification."; sleep 5 ; done

     # wait for resource
    while ! kubectl get redb db1 ; do echo "Waiting for Redis db to become available."; sleep 1 ; done
    while ! kubectl wait --for jsonpath="{.status.status}"=active --timeout=10s redb db1 ; do echo "Waiting for db1 status to be Active." ; sleep 5 ; done
fi