#!/bin/bash

kind_release="https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64"
num_clusters=2
operator_src=https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
operator_dir=redis-enterprise-k8s-docs/
active_active=yes
loadbalancer_release=https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
ingresscontroller_release=https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
