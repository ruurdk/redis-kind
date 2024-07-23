#!/bin/bash

source ../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Installing Prmoetheus operator in cluster $c" 
    
    kubectl config use-context kind-c$c

    kubectl create namespace monitoring
    kubectl config set-context --current --namespace=monitoring
    
    # below lines from: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md
    # this will deploy in the default namespace
    LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
    curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | sed "s/namespace: default/namespace: monitoring/g" | kubectl create -f -
    kubectl wait --for=condition=Ready pods -l  app.kubernetes.io/name=prometheus-operator -n monitoring

    kubectl apply -f prom-rbac.yaml
    # deploy servicemonitor CRD for monitoring RE
    kubectl apply -f prom-servicemonitor.yaml
    # deploy prometheus 
    kubectl apply -f prom-prom.yaml
done