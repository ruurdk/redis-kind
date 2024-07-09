#!/bin/bash

echo "$(date) - INSTALLING Redis Enterprise - with operator" 
git clone https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
cd redis-enterprise-k8s-docs/
kubectl create namespace redis
kubectl config set-context --current --namespace=redis
kubectl apply -f bundle.yaml
while ! kubectl wait --for condition=established --timeout=10s crd/redisenterpriseclusters.app.redislabs.com ; do sleep 1 ; done
