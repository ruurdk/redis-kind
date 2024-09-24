#!/bin/bash

# load vars
source ../config.sh

if [ "$install_redisinsight" == "yes" ];
then
    cd redisinsight
    ./deploy-redisinsight.sh
    cd ..
fi

if [ "$install_benchmark" == "yes" ];
then
    cd redis-benchmark
    ./redis-benchmark.sh
    cd ..
fi