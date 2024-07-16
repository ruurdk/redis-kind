#!/bin/bash

# load vars
source config.sh

echo "$(date) - creating kind clusters and installing RE"
./create-kind-clusters.sh
./install-re-operator.sh
./deploy-rec.sh
./deploy-db.sh
