#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing ingress controller in cluster $c" 

    kubectl config use-context kind-c$c
    kubectl apply -f $ingresscontroller_release

    # wait for ingress controller to have a loadbalancer (external) ip.
    # NOTE: THIS BELOW IS NGINX SPECIFIC
    until kubectl get svc/ingress-nginx-controller -n ingress-nginx --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done
    # enable ssl-passthrough
    kubectl patch deployment -n ingress-nginx ingress-nginx-controller --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--enable-ssl-passthrough"}]'
done

