#!/bin/bash

# RELEASES.
kind_release="https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64"
k8s_release="latest" # "latest" or in the format: kindest/node:v<version>@sha256:<sha>, see https://github.com/kubernetes-sigs/kind/releases
operator_release=https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
loadbalancer_release=https://raw.githubusercontent.com/metallb/metallb/v0.14.6/config/manifests/metallb-native.yaml
ingresscontroller_release_ingress_nginx=https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
ingresscontroller_release_haproxy_ingress=https://raw.githubusercontent.com/jcmoraisjr/haproxy-ingress/master/docs/haproxy-ingress.yaml
ingresscontroller_release_nginx_ingress="https://github.com/nginxinc/kubernetes-ingress.git --branch v3.6.1"
grafana_dashboards_release="https://github.com/redis-field-engineering/redis-enterprise-observability.git --branch main"
grafana_dashboards_folder="grafana/dashboards/grafana_v9-11/software/basic/"

# SETTINGS.
install_loadbalancer=yes
install_ingress=yes
ingresscontroller_type=ingress-nginx # options: ingress-nginx, haproxy-ingress, nginx-ingress
install_monitoring=no
patch_dns=yes
num_clusters=2
enable_admissioncontroller=yes
# WARNING, active_active will only work out of the box with install_ingress, install_loadbalancer & patch_dns = yes
active_active=yes
