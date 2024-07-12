#!/bin/bash

# load vars
source ../config.sh

# needed these lines to make >1 cluster come up
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_user_instances=512

# may need this for OS prep on the host
#echo 'DNSStubListener=no' | tee -a /etc/systemd/resolved.conf
#mv /etc/resolv.conf /etc/resolv.conf.orig
#ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
#service systemd-resolved restart
#sysctl -w net.ipv4.ip_local_port_range="40000 65535"
#echo "net.ipv4.ip_local_port_range = 40000 65535" >> /etc/sysctl.conf

./install-docker-ubuntu.sh
./install-kind.sh
