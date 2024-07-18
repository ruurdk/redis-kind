#!/bin/bash

kind_release="https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64"
operator_src=https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
operator_dir=redis-enterprise-k8s-docs/
loadbalancer_release=https://raw.githubusercontent.com/metallb/metallb/v0.14.6/config/manifests/metallb-native.yaml
ingresscontroller_release_ingress_nginx=https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
ingresscontroller_release_haproxy_ingress=https://raw.githubusercontent.com/jcmoraisjr/haproxy-ingress/master/docs/haproxy-ingress.yaml
ingresscontroller_type=ingress-nginx # options: ingress-nginx, haproxy-ingress
num_clusters=2
install_ingress=yes
install_loadbalancer=yes
patch_dns=yes
# WARNING, active_active will only work out of the box with install_ingress, install_loadbalancer & patch_dns = yes
active_active=yes
