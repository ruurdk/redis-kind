#!/bin/bash

source ../../config.sh

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

    # prepare dashboards
    git clone $grafana_dashboards_release gfdb
    # patch ${DS_PROMETHEUS} to DS_PROMETHEUS or datasource doesn't get picked up
    cd gfdb/$grafana_dashboards_folder
    for dbfile in "*.json"; do
        sed -i 's/${DS_PROMETHEUS}/DS_PROMETHEUS/g' $dbfile
    done
    cd -
    # collate into configmap
    kubectl create configmap grafana-dashboards-redis-all -n monitoring --from-file=gfdb/$grafana_dashboards_folder
    # clean up
    rm -rf gfdb

    # deploy grafana
    kubectl apply -f grafana.yaml -n monitoring
done