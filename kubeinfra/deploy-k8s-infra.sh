#!/bin/bash

# load vars
source ../config.sh

# K8s infrastructure.
if [ "$install_loadbalancer" == "yes" ];
then
    echo "$(date) - Installing LoadBalancer"

    cd loadbalancer
    ./install_loadbalancer.sh
    cd ..
fi

if [ "$install_ingress" == "yes" ];
then
    echo "$(date) - Installing Ingress"

    cd ingress
    ./install_ingresscontroller.sh
    cd ..
fi

if [ "$install_monitoring" == "yes" ];
then
    echo "$(date) - Installing Monitoring"

    cd monitoring
    ./install_monitoring.sh
    cd ..
fi