#!/bin/bash

# load vars
source ../config.sh

################
# kind k8s
echo "$(date) - INSTALLING docker" 

# Install docker
apt-get install -y software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable edge"
apt-cache policy docker-ce 
apt-get install -y docker-ce