#!/bin/bash
# This installer uses Helm by exception as it's the only supported method for dashboard.

source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    # https://github.com/kubernetes/dashboard?tab=readme-ov-file#installation

    # Add kubernetes-dashboard repository
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    # Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
    helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
done