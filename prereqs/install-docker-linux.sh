#!/bin/bash

set -e

# load vars
source ../config.sh
# load os info
source /etc/os-release

echo "$(date) - INSTALLING docker" 

# Install prereqs
apt-get install -y software-properties-common jq git ca-certificates curl lsb-release
apt update

case $ID in
    "ubuntu" | "debian")
        # Add Docker's official GPG key:
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$ID/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ;;
    *)
        echo "$(date) Unknown OS, please install docker-ce manually"
        exit 1
        ;;
esac

case $ID in
    "ubuntu")
        DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip
        pip install  yq
        ;;
    "debian")
        apt install yq
        ;;
    *)
        ;;
esac

apt update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "$(date) - Test running hello-world container"
docker run hello-world

# Post install config (non root access)
if [ ! $(getent group docker) ];
then
    groupadd docker
fi
/usr/sbin/usermod -aG docker $USER

echo "$(date) - NOTE: you need to log in/out or use newgrp docker to continue in this session"
