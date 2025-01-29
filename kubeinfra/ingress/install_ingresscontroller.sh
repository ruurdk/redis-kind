#!/bin/bash

source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing ingress controller of type $ingresscontroller_type in cluster $c" 

    kubectl config use-context kind-c$c
    releasename="ingresscontroller_release_${ingresscontroller_type/-/_}"

    # Ingress specific configs
    case $ingresscontroller_type in
        "ingress-nginx")
            echo "$(date) - Installing $ingresscontroller_type."
            kubectl apply -f ${!releasename}
    
            # wait for all pods to be running
            kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
            # wait for ingress controller to have a loadbalancer (external) ip.    
            until kubectl get svc/ingress-nginx-controller -n ingress-nginx --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done
            # enable ssl-passthrough
            kubectl patch deployment -n ingress-nginx ingress-nginx-controller --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--enable-ssl-passthrough"}]'       
            ;;
        "haproxy-ingress")
            echo "$(date) - Installing $ingresscontroller_type."
            kubectl apply -f ${!releasename}

            # we need a role on the nodes to run this thing. TODO: make this nices to only select workers.
            kubectl label node --all role=ingress-controller

            # no service in deployment manifest, so add it.
            kubectl apply -f haproxy-ingress.yaml

            # wait for ingress controller to have a loadbalancer (external) ip.    
            until kubectl get svc/haproxy-ingress -n ingress-controller --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done            
            ;;
        # the F5 one.
        "nginx-ingress") 
            echo "$(date) - Installing $ingresscontroller_type."
            
            # no single manifest, the release is a git repo.
            git clone ${!releasename} kubernetes-ingress
            cd kubernetes-ingress

            # ns + admin account.
            kubectl apply -f deployments/common/ns-and-sa.yaml
            # rbac.
            kubectl apply -f deployments/rbac/rbac.yaml

            # settings.
            kubectl apply -f deployments/common/nginx-config.yaml
            # ingressclass
            kubectl apply -f deployments/common/ingress-class.yaml            
            
            # patch in the ingressclass.kubernetes.io/is-default-class annotation to apply to Ingresses without IngressClass.
            # seems not needed as nginx complains/warns but still picks it up.
            #kubectl patch ingressclass nginx --type='json' -p='[{"op": "add", "path": "/metadata/annotations", "value": {"ingressclass.kubernetes.io/is-default-class": "true"}}]'

            # CRDs.
            kubectl apply -f config/crd/bases/k8s.nginx.org_virtualservers.yaml
            kubectl apply -f config/crd/bases/k8s.nginx.org_virtualserverroutes.yaml
            kubectl apply -f config/crd/bases/k8s.nginx.org_transportservers.yaml
            kubectl apply -f config/crd/bases/k8s.nginx.org_policies.yaml
            kubectl apply -f config/crd/bases/k8s.nginx.org_globalconfigurations.yaml

            # Actual Ingress Controller.
            kubectl apply -f deployments/deployment/nginx-ingress.yaml
            # line for Nginx Plus
            #kubectl apply -f deployments/deployment/nginx-plus-ingress.yaml
            
            # enable tls-passthrough (NOTE: this isn't the same as the SSL passthrough argument on the regular nginx).
            # Only supported through Custom Resources (TransportServer) and not through regular Ingress: https://github.com/nginxinc/kubernetes-ingress/issues/1057
            # That implementation is in rec creation.
            kubectl patch deployment -n nginx-ingress nginx-ingress --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"-enable-tls-passthrough"}]'       

            # deploy service.
            kubectl apply -f deployments/service/loadbalancer.yaml

            cd ..
            rm -rf kubernetes-ingress/
            ;;
        "contour")
            echo "$(date) - Installing $ingresscontroller_type."
            kubectl apply -f ${!releasename}

            # wait for ingress controller to have a loadbalancer (external) ip.    
            until kubectl get svc/envoy -n projectcontour --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done            
            ;;
        "no_ingress_use_loadbalancer")
            echo $(date) - Configuring A/A replication link to use database ports without Ingress.""
            ;;
        *)
            echo "$(date) - Unknown Ingress $ingresscontroller_type, skipping installation."
            ;;
    esac
done

