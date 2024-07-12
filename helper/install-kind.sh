#!/bin/bash

# load vars
source ../config.sh

# Install kind
echo "$(date) - INSTALLING kind" 

curl -Lo ./kind $kind_release
chmod +x ./kind
mv ./kind /usr/local/bin/kind