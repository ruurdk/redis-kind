#!/bin/bash

# load vars
source config.sh

echo "$(date) - creating kind clusters and installing RE"
./create-kind-clusters.sh
./deploy-k8s-infra.sh
./install-re-operator.sh
./deploy-rec.sh
./deploy-db.sh
