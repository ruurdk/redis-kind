#!/bin/bash
# Early out on combinations that won't work.

source config.sh

echo "$(date) - Checking input."

if [ "$num_clusters" -lt 1 ]; then
    echo "$(date) - ERROR: The number of clusters should be at least equal to 1."
    exit 1
fi
if [ "$num_clusters" -gt 3 ]; then
    echo "$(date) - WARNING: This number of clusters ($num_clusters) has not been tested."
else 
    echo "$(date) - Validated number of clusters: $num_clusters."
fi

# A/A prerequisites.
if [ "$active_active" == "yes" ]; then
  if [[ "$install_loadbalancer" != "yes" || "$install_ingress" != "yes" || "$patch_dns" != "yes" ]]; then
    echo "$(date) - ERROR: Active / Active requires a loadbalancer, ingress, and DNS patching."
    exit 1
  else
    echo "$(date) - Validated Active / Active prerequisites."
  fi

  if [ "$num_clusters" -eq 1 ]; then
    echo "$(date) - WARNING: Deploying a CRDB in 1 cluster will work, but will have limited functionality."
  fi
fi

# Valid ingress.
if [ "$install_ingress" == "yes" ]; then
    case "$ingresscontroller_type" in
        "ingress-nginx" | "haproxy-ingress" | "nginx-ingress")
            echo "$(date) - Validated ingress controller type: $ingresscontroller_type."
            ;;
        *)
            echo "$(date) - ERROR: Invalid ingress controller $ingresscontroller_type."
            exit 1
            ;;
    esac
fi