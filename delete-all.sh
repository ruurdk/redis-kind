#!/bin/bash

# load vars
source config.sh

echo "$(date) - deleting kind clusters"
for c in $(seq 1 $num_clusters);
do
    echo "$(date) - Deleting cluster $c"
    kind delete clusters c$c
done