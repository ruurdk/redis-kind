#!/bin/bash

# load vars
source ../../config.sh

for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Deploying Redis Benchmark for cluster $c" 
    
    kubectl config use-context kind-c$c
    
    kubectl config set-context --current --namespace=redis
    
    REDBNAME=db1
    SVCNAME=$REDBNAME-headless
    SVCPORT=`kubectl get svc/${SVCNAME} -o jsonpath='{.spec.ports[0].port}'`
    # Discover access params.
    if [ "$active_active" == "yes" ];
    then
        DBSECNAME=`kubectl get reaadb "${REDBNAME}" -o jsonpath="{.spec.globalConfigurations.databaseSecretName}"`
    else
        DBSECNAME=`kubectl get redb "${REDBNAME}" -o jsonpath="{.spec.databaseSecretName}"`
    fi
    SVCPASS=`kubectl get secret/${DBSECNAME} -o jsonpath='{.data.password}' | base64 --decode`
    SVCUSER=`kubectl get secret/${DBSECNAME} -o jsonpath='{.data.username}' | base64 --decode`

    # get benchmark deployment from template and edit arguments
    cp redis-benchmark_template.yaml redis-benchmark.yaml
    args=[\"-tls\",\"-tls-skip\",\"-d\",\"100\",\"-c\",\"25\",\"-h\",\"${SVCNAME}.redis.svc\",\"-p\",\"${SVCPORT}\",\"-rps\",\"5000\",\"-l\",\"SET\",\"__key__\",\"__data__\"]
    yq -iy ".spec.template.spec.containers[0].args = $args" redis-benchmark.yaml

    kubectl apply -f redis-benchmark.yaml

done

echo "$(date) - Access memtier logs through: kubectl logs memtier"
