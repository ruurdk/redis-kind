#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing ingress controller of type $ingresscontroller_type in cluster $c" 

    kubectl config use-context kind-c$c
    kubectl apply -f $ingresscontroller_release

    # Ingress specific configs
    if [ "$installcontroller_type" == "ingress-nginx" ];
    then
        echo "$(date) - Waiting for Ingress activation/patching."
    
        # wait for all pods to be running
        kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
        # wait for ingress controller to have a loadbalancer (external) ip.    
        until kubectl get svc/ingress-nginx-controller -n ingress-nginx --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done
        # enable ssl-passthrough
        kubectl patch deployment -n ingress-nginx ingress-nginx-controller --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--enable-ssl-passthrough"}]'       
    fi    

    #TODO haproxy config
done

