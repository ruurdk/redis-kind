#!/bin/bash

source config.sh

kubectl config use-context kind-c1

#TODO do a check whether container 0 or 1 is the right image, assume 0 now.
RIMAGE=$(kubectl get pod/rec1-0 -o jsonpath="{.spec.containers[0].image}")
echo "$(date) - Deploying test cli with image $RIMAGE"

# spin redis enterprise pod to run redis-cli
sed 's,REDIS_IMAGE,'"$RIMAGE"',g' rediscli.yaml | kubectl apply -f -
# wait for it to be up
kubectl wait --for=condition=ready pod rediscli --timeout=120s

db_clusterip=$(kubectl get svc/db1 -o jsonpath="{.spec.clusterIP}")
db_port=$(kubectl get svc/db1 -o jsonpath="{.spec.ports[0].port}")
hostname=$(kubectl get ing/db1 -o jsonpath="{.spec.rules[0].host}")
case $ingresscontroller_type in
        "ingress-nginx")
        lb_ip=$(kubectl get svc/ingress-nginx-controller -n ingress-nginx --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ;;
        "haproxy-ingress")
        lb_ip=$(kubectl get svc/haproxy-ingress -n ingress-controller --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ;;
        "nginx-ingress")
        lb_ip=$(kubectl get svc/nginx-ingress -n nginx-ingress --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ;;
        *)
        lb_ip="<UNKNOWN>"
        ;;
esac

# TODO: use a DB with username/password, for now it's working with default user.
#username=$(kubectl get secret db1secret -o jsonpath="{.data.username}" | base64 --decode)
#pw=$(kubectl get secret db1secret -o jsonpath="{.data.password}" | base64 --decode)
#echo "$(date) - Testing access - in pod network (ip:port = $db_clusterip:$db_port with user $username and pass $pw)"
#kubectl exec -it pod/rediscli -- bash -c "redis-cli -h $db_clusterip  -p $db_port --insecure --sni $hostname --user $username -a $pw PING"

echo "$(date) - Running connectivity tests. db1 = $db_clusterip:$db_port. Hostname = $hostname. Ingress loadbalancer = $lb_ip"
echo "$(date) - LOCAL cluster"

echo "$(date) - Testing access - direct to pod ($db_clusterip:$db_port)"
kubectl exec -it pod/rediscli -- bash -c "redis-cli -h $db_clusterip  -p $db_port --insecure --tls --sni $hostname PING"
echo "$(date) - Testing access - through service (db1:$db_port)"
kubectl exec -it pod/rediscli -- bash -c "redis-cli -h db1  -p $db_port --insecure --tls --sni $hostname PING"
echo "$(date) - Testing access - through ingress (ip) ($lb_ip:443)"
kubectl exec -it pod/rediscli -- bash -c "redis-cli -h $lb_ip -p 443 --insecure --tls --sni $hostname PING"
echo "$(date) - Testing access - through ingress (hostname) ($hostname:443)"
kubectl exec -it pod/rediscli -- bash -c "redis-cli -h $hostname -p 443 --insecure --tls --sni $hostname PING"

# get remote hostname/ip directly from cluster 2, alternatively could get it through rerc and dns
kubectl config use-context kind-c2
remote_hostname=$(kubectl get ing/db1 -o jsonpath="{.spec.rules[0].host}")
case $ingresscontroller_type in
        "ingress-nginx")
        remote_lb_ip=$(kubectl get svc/ingress-nginx-controller -n ingress-nginx --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ;;
        "haproxy-ingress")
        remote_lb_ip=$(kubectl get svc/haproxy-ingress -n ingress-controller --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ;;
        "nginx-ingress")
        remote_lb_ip=$(kubectl get svc/nginx-ingress -n nginx-ingress --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ;;
        *)
        remote_lb_ip="<UNKNOWN>"
        ;;
esac
kubectl config use-context kind-c1

echo "$(date) - REMOTE cluster"
echo "$(date) - Testing access - through ingress (ip) ($remote_lb_ip:443)"
kubectl exec -it pod/rediscli -- bash -c "redis-cli -h $remote_lb_ip -p 443 --insecure --tls --sni $remote_hostname PING"
echo "$(date) - Testing access - through ingress (hostname) ($remote_hostname:443)"
kubectl exec -it pod/rediscli -- bash -c "redis-cli -h $remote_hostname -p 443 --insecure --tls --sni $remote_hostname PING"