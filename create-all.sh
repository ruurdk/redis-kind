#!/bin/bash

# load vars
source config.sh

echo "$(date) - creating kind clusters and installing RE"

./sanity-check.sh

cd kind
./create-kind-clusters.sh
cd ..

cd kubeinfra
./deploy-k8s-infra.sh
cd ..

cd redis/operator
./install-re-operator.sh
cd -

cd redis/cluster
./deploy-rec.sh
cd -

cd redis/database
./deploy-db.sh
cd -

./help.sh