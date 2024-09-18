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

if [ "$install_dashboard" == "yes" ];
then
    echo "$(date) - Installing K8s dashboard"

    cd dashboard
    ./install_dashboard.sh
    cd ..
fi

if [ "$install_metrics" == "yes" ];
then
    echo "$(date) - Installing K8s metrics server"

    cd metrics
    ./install_metrics.sh
    cd ..
fi