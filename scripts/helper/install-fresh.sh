#!/bin/bash

# load vars
source ../config.sh

# needed these lines to make >1 cluster come up
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_user_instances=512

./install-docker-ubuntu.sh
./install-kind.sh
