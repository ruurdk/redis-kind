#!/bin/bash

# load vars
source config.sh

# create empty creds file for all clusters.
> all-cluster-creds.yaml

# deploy the REC for all clusters.
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - DEPLOYING Redis Enterprise Cluster on k8s cluster $c" 
    
    kubectl config use-context kind-c$c

    # Create a RE cluster
    kubectl apply -f rec$c.yaml
    while ! kubectl get secret rec$c; do echo "Waiting for secret rec$c. CTRL-C to exit."; sleep 1; done

    # output creds.
    pw=$(kubectl get secret rec$c -o jsonpath="{.data.password}") 
    user=$(kubectl get secret rec$c -o jsonpath="{.data.username}") 
    echo "$(date) - RE credentials user: $(echo $user | base64 --decode) - password: $(echo $pw | base64 --decode)" 
    # write creds to all creds file.
    cat << EOF >> all-cluster-creds.yaml
apiVersion: v1
data:
  password: $pw
  username: $user
kind: Secret
metadata:
  name: redis-enterprise-rerc$c
type: Opaque
---
EOF

    # Enable admission controller.
    if [ "$enable_admissioncontroller" == "yes" ];
    then
      echo "$(date) - Enabling admission controller"
      
      # get cert
      CERT=$(kubectl get secret admission-tls -o jsonpath='{.data.cert}')
      # fill namespace
      sed 's/OPERATOR_NAMESPACE/redis/g' webhook.yaml | kubectl create -f -
      # prepare patch for cert.
      cat > modified-webhook.yaml <<EOF
webhooks:
- name: redisenterprise.admission.redislabs
  clientConfig:
    caBundle: $CERT
  admissionReviewVersions: ["v1beta1"]
EOF
      # apply patch
      kubectl patch ValidatingWebhookConfiguration redis-enterprise-admission --patch "$(cat modified-webhook.yaml)"
    fi

    # patch the rec ingress spec for knowns controllers.
    if [ "$install_ingress" == "yes" ];
    then
      echo "$(date) - Patching REC to use Ingress $ingresscontroller_type"    

      case $ingresscontroller_type in 
      "ingress-nginx")
        kubectl patch rec rec$c --type merge --patch "{\"spec\": {\"ingressOrRouteSpec\": {\"ingressAnnotations\": {\"kubernetes.io/ingress.class\": \"nginx\", \"nginx.ingress.kubernetes.io/ssl-passthrough\": \"true\"}, \"method\": \"ingress\"}}}"
        ;;
      "haproxy-ingress")
        kubectl patch rec rec$c --type merge --patch "{\"spec\": {\"ingressOrRouteSpec\": {\"ingressAnnotations\": {\"kubernetes.io/ingress.class\": \"haproxy\", \"haproxy-ingress.github.io/ssl-passthrough\": \"true\"}, \"method\": \"ingress\"}}}"
        ;;
      "nginx-ingress")
        # patch the ingress.class to some dummy value so we know for sure nginx won't pick up the Ingress and bind the port - as we want it on the TransportServer which can actually do SSL passthrough.     
        kubectl patch rec rec$c --type merge --patch "{\"spec\": {\"ingressOrRouteSpec\": {\"ingressAnnotations\": {\"kubernetes.io/ingress.class\": \"none\"}, \"method\": \"ingress\"}}}"
        # create a TransportServer for the REC api.
        rec_api_hostname=$(kubectl get rec rec$c --output=jsonpath='{.spec.ingressOrRouteSpec.apiFqdnUrl}')
        sed "s/HOSTNAME/${rec_api_hostname}/g" ts-ssl-template.yaml | sed "s/SERVICE/rec$c/g" | sed "s/PORT/9443/g" | sed "s/TS_NAME/rec-api/g" | kubectl create -f -
        ;;
      *)
        echo "$(date) - UNKWOWN ingress controller $ingresscontroller_type: skipping REC annotations"
        ;;
      esac
    fi
done

# Waiting for REC to come up.
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Waiting for REC on cluster $c to be operational" 
    
    kubectl config use-context kind-c$c
    kubectl rollout status sts/rec$c
done

if [ "$patch_dns" == "yes" ];
then
    echo "$(date) - Adding cluster fqdns to K8s DNS"

    cd kubeinfra
    ./add_dnsrecords.sh
    cd ..
fi

# Set up A/A artifacts.
if [ "$active_active" == "yes" ]; 
then
    echo "$(date) - Deploying active-active remote cluster CRDs."
    ./deploy-rerc.sh
fi