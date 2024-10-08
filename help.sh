#!/bin/bash
# Help with some commands

source config.sh

echo "$(date) - Some tips on getting started!"
echo "_______________________________________"

echo "KinD clusters: $num_clusters"
echo "Switch to cluster N: "
echo "              kubectl config use-context kind-cN" 

# K8s nodes access.
echo "_______________________________________"
echo "Access k8s nodes (eg. to run a command on node 3 of cluster 1):"
echo "              docker exec -it c1-worker3 ip route"
# K8s metrics.
if [ "$install_metrics" == "yes" ];
then
    echo "Node resources:"
    echo "              kubectl top nodes/pods"
fi

# Print how to exec rladmin.
echo "_______________________________________"
echo "Accessing the admin CLI (status) on cluster N: "
echo "              kubectl exec -it pod/recN-0 -n redis -- rladmin status"

if [ "$active_active" == "yes" ];
then
    # Test A/A connectivity.
    echo "_______________________________________"
    echo "Test A/A end to end connectivity:"
    echo "              Run the debug/testlink.sh script (it leverages redis-cli in a container)."
fi

# Print how to expose to outside kind/docker.
echo "_______________________________________"
echo "There is internal (in KinD) connectivity through Docker networks"
echo "In case you need to access ports on the host/outside (eg. admin GUI at 8443) on cluster N: "
echo "              kubectl port-forward --address localhost,0.0.0.0 svc/recN-ui 8443:8443 -n redis"
echo "Other interesting ports may be prometheus (9090), Grafana (3000), Ingress (443) or the local database port."
if [ "$install_dashboard" == "yes" ];
then
    echo "Create a token for the k8s dashboard with:"
    echo "              kubectl -n kubernetes-dashboard create token admin-user"
fi

echo "_______________________________________"
