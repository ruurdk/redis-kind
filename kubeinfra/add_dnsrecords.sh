#!/bin/bash
# In this shell code we add records to K8s coredns to run without external DNS services.
# This has some drawbacks (see below), but works for this testing framework

source ../config.sh

# create empty hosts file
> hosts.txt
echo "hosts {" >> hosts.txt

# collect DNS records and IPs from all clusters
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Adding DNS records to remote clusters in cluster $c" 

    kubectl config use-context kind-c$c
    # get external IP for THIS cluster
    case $ingresscontroller_type in 
      "ingress-nginx")
        ip=$(kubectl get svc/ingress-nginx-controller -n ingress-nginx --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ;;
      "haproxy-ingress")
        ip=$(kubectl get svc/haproxy-ingress -n ingress-controller --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ;;
      *)
        echo "$(date) - WARNING - couldn't get external IP for unknown ingress, DNS setup will be incorrect"
        ;;
    esac

    # add records for this cluster to hosts file
    # NOTE the line for the database is hardcoded for >>>db1<<< as CoreDNS doesn't support wildcards in hosts.
    cat << EOF >> hosts.txt
  $ip api-rec$c-redis.lab
  $ip db1-db-rec$c-redis.lab  
EOF
done

# finish hosts file
cat << EOF >> hosts.txt
  fallthrough
}
EOF

# update DNS
for c in $(seq 1 $num_clusters);
do
    kubectl config use-context kind-c$c

    # get original coreDNS config(map) 
    if [ ! -f corednsconfig.yaml ]; then
      kubectl get cm coredns -n kube-system -o jsonpath='{.data.Corefile}' > corednsconfig.yaml
    fi
    
    # create patch file
    > newconfig.yaml
cat << EOF >> newconfig.yaml
data:
  Corefile: |
EOF
    
    k8line=$(grep -n kubernetes corednsconfig.yaml | cut -f1 -d:)
    # patch the file 
    head corednsconfig.yaml -n $(($k8line - 2 )) | sed 's/^/    /' >> newconfig.yaml
    sed 's/^/        /' hosts.txt >> newconfig.yaml
    tail corednsconfig.yaml -n +$(($k8line - 1 )) | sed 's/^/    /' >> newconfig.yaml

    # update coredns config map
    kubectl patch cm coredns -n kube-system --patch-file newconfig.yaml    
  
    # restart coredns
    kubectl rollout restart -n kube-system deployment/coredns
done