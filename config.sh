#!/bin/bash

kind_release="https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64"
loadbalancer_release=https://raw.githubusercontent.com/metallb/metallb/v0.14.6/config/manifests/metallb-native.yaml
ingresscontroller_release=https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
operator_src=https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
operator_dir=redis-enterprise-k8s-docs/
num_clusters=2
install_ingress=yes
install_loadbalancer=yes
patch_dns=yes
# WARNING, active_active will only work out of the box with install_ingress, install_loadbalancer & patch_dns = yes
active_active=yes
