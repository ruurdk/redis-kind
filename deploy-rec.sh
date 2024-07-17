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
done

# Waiting for REC to come up.
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Waiting for REC on cluster $c to be operational" 
    
    kubectl config use-context kind-c$c
    kubectl rollout status sts/rec$c
done


# Set up A/A artifacts.
if [ "$active_active" == "yes" ]; 
then
    echo "$(date) - Setting up active-active LB, Ingress, DNS infrastructure"

    cd kubeinfra
    ./install_loadbalancer.sh
    ./install_ingresscontroller.sh
    ./add_dnsrecords.sh
    cd ..

    ./deploy-rerc.sh
fi