# Redis k8s operator deployment on Kind

By default, this set of scripts will set up a fully functioning Redis Active-Active database distributed over 2 Redis Enterprise clusters running on seperate vanilla k8s clusters.

## Getting started quickly

- Provision a single Linux host with enough resources (4 vCPU and 16GB of RAM should do).
- To run Kind, make sure you have Docker, kind and kubectl installed, and tune the OS if needed (see the prereqs folder for some helper scripts).
- Run the create-all.sh script.
- Wait 5 mins.
- Run the testlink.sh script to test connectivity (A/A) on the database level.

## Stopping quickly 

Run the delete-all.sh script.

## What it deploys

Basics:

- Multiple (2) k8s clusters in Kind
- Deploy Redis Enterprise in all clusters, including the admission controller.

In addition, for Active/Active (default), it further deploys:

- A loadbalancer (metallb) to let the clusters talk to each other through a "public" endpoint (in the Docker kind network).
- The remote cluster api & database fqdn in kube-dns (coredns) hosts file to resolve the cluster api and databases in remote clusters.
- An ingress controller (ngress-nginx) to facilitate RE A/A created Ingress resources.
- A/A artifacts (Remote cluster CRDs - the 'RERC')
- A CRDB (A/A database)
