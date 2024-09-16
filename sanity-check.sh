#!/bin/bash
# Early out on combinations that won't work.

source config.sh

echo "$(date) - Checking input."

# K8s nodes.
if [ "$worker_nodes" -lt 1 ] || [ $((worker_nodes%2)) -eq 0 ];
then
  echo "$(date) - ERROR: The number of worker nodes ($worker_nodes) should be a positive odd number."
  exit 1
else
  echo "$(date) - Validated number of worker nodes: $worker_nodes."
fi
if [ "$control_nodes" -lt 1 ] || [ $((control_nodes%2)) -eq 0 ];
then
  echo "$(date) - ERROR: The number of control plane nodes ($control_nodes) should be a positive odd number."
  exit 1
else
  echo "$(date) - Validated number of control plane nodes: $control_nodes."
fi

# RZA.
if [ "$rackzone_aware" == "yes" ]; 
then
  if [ "$rackzone_zones" -lt 1 ] || [ $((rackzone_zones%2)) -eq 0 ];
  then
    echo "$(date) - ERROR: The number of rack zones ($rackzone_zones) should be a positive odd number."
    exit 1
  else
    echo "$(date) - Validated number of rack zone: $rackzone_zones."
  fi

  if [ "$worker_nodes" -lt "$rackzone_zones" ];
  then
    echo "$(date) - ERROR: The number of worker nodes ($worker_nodes) is not capable of hosting all rack zones ($rackzone_zones)."
    exit 1
  else
    echo "$(date) - Validated the number of worker nodes ($worker_nodes) is capable of hosting all rack zones ($rackzone_zones)."    
  fi
  ideal_workers=$((rackzone_zones*2 - 1))
  if [ ! "$ideal_workers" -eq "$worker_nodes" ];
  then
    echo "$(date) - WARN: The number of worker nodes ($worker_nodes) is sub optimal for rack zones ($rackzone_zones). Ideal number of worker nodes: $ideal_workers."    
  else
    echo "$(date) - Validated the number of worker nodes ($worker_nodes) is ideal for the number of rack zones ($rackzone_zones)."    
  fi
fi

# Number of clusters.
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