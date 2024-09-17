#!/bin/bash

# load vars
source ../config.sh

cp 10-kind.conf /etc/sysctl.d/
sysctl -p

# may need this for OS prep on the host
#echo 'DNSStubListener=no' | tee -a /etc/systemd/resolved.conf
#mv /etc/resolv.conf /etc/resolv.conf.orig
#ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
#service systemd-resolved restart
#sysctl -w net.ipv4.ip_local_port_range="40000 65535"
#echo "net.ipv4.ip_local_port_range = 40000 65535" >> /etc/sysctl.conf

./install-docker-linux.sh
./install-kind.sh
./install-kubectl.sh
# generally we try to use manifests but there are some add-ons that only have helm installer support.
./install-helm.sh

echo "$(date) - Prereq installation finished, please reboot to ensure shell reload (to have non-root access to docker)!"