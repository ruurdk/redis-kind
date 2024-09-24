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

    # TODO: 
    #   - make this continuous output vs. 1 run every 120s
    #   - wrap in proper deployment    
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: memtier
spec:
  containers:
  - name: memtier
    image: redislabs/memtier_benchmark:latest
    args: ["--tls","--tls-skip-verify","--key-prefix=a","--ratio=1:4","--test-time=120","-d","100","-t","2","-c","25","--pipeline=50","--key-pattern=S:S","--hide-histogram","-x","1000","-s","${SVCNAME}.redis.svc","-p","${SVCPORT}"]
EOF

done

echo "$(date) - Access memtier logs through: kubectl logs memtier"
