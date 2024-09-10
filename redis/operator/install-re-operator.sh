#!/bin/bash

# load vars
source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - INSTALLING Redis Enterprise - with operator on cluster $c" 
    git clone $operator_release reop
    cd reop

    kubectl config use-context kind-c$c
    kubectl create namespace redis
    kubectl config set-context --current --namespace=redis
    kubectl apply -f bundle.yaml
    while ! kubectl get crd/redisenterpriseclusters.app.redislabs.com ; do echo "Waiting for my RE operator CRD creation. CTRL-C to exit."; sleep 1; done
    while ! kubectl wait --for condition=established --timeout=10s crd/redisenterpriseclusters.app.redislabs.com ; do echo "Waiting for CRD to be established." ; sleep 1 ; done

    # for rack zone awareness we need some additional rights.
    if [ "$rackzone_aware" == "yes" ];
    then
        echo "$(date) - Deploying rackzone cluster roles, binding and labeling worker nodes."

        # cluster role to inspect node labels/taints
        kubectl apply -f rack_awareness/rack_aware_cluster_role.yaml
        # binding to redis service account
        cat rack_awareness/rack_aware_cluster_role_binding.yaml | sed 's/NAMESPACE_OF_SERVICE_ACCOUNT/redis/g' | kubectl apply -f -

        # add k8s worker nodes to rackzones by labeling them.
        currentzone=1
        for node in $(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name);
        do
            kubectl label $node topology.kubernetes.io/zone=redis-zone-$currentzone
            
            currentzone=$((currentzone + 1))
            if [ "$currentzone" -gt "$rackzone_zones" ]; then
                currentzone=1
            fi
        done

        # label control-plane nodes - somehow the REC gets stuck on bootstrap of pod 1 if these are not labeled.
        for node in $(kubectl get nodes -l 'node-role.kubernetes.io/control-plane' -o name);
        do
            kubectl label $node topology.kubernetes.io/zone=redis-zone-control
        done
    fi

    cd ..
    rm -rf reop
done