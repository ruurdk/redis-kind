#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing ingress controller of type $ingresscontroller_type in cluster $c" 

    kubectl config use-context kind-c$c
    releasename="ingresscontroller_release_${ingresscontroller_type/-/_}"
    kubectl apply -f ${!releasename}

    # Ingress specific configs
    case $ingresscontroller_type in
        "ingress-nginx")
            echo "$(date) - Ingress Nginx specific config."
    
            # wait for all pods to be running
            kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
            # wait for ingress controller to have a loadbalancer (external) ip.    
            until kubectl get svc/ingress-nginx-controller -n ingress-nginx --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done
            # enable ssl-passthrough
            kubectl patch deployment -n ingress-nginx ingress-nginx-controller --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--enable-ssl-passthrough"}]'       
            ;;
        "haproxy-ingress")
            echo "$(date) - HAproxy Ingress specific config."

            # we need a role on the nodes to run this thing. TODO: make this nices to only select workers.
            kubectl label node --all role=ingress-controller

            # no service in deployment manifest, so add it.
            kubectl apply -f haproxy-ingress.yaml

            # wait for ingress controller to have a loadbalancer (external) ip.    
            until kubectl get svc/haproxy-ingress -n ingress-controller --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done            
            ;;
        *)
            echo "$(date) - no patches for unknown Ingress $ingresscontroller_type"
            ;;
    esac
done

