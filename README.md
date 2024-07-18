# Redis k8s operator deployment on Kind

By default, this set of scripts will set up a fully functioning Redis [Active-Active database](https://redis.io/active-active/) distributed over 2 Redis clusters running on seperate vanilla/community k8s clusters deployed in [kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker).

## Getting started quickly

- Provision a single Linux host with enough resources (4 vCPU and 16GB of RAM should do) - tested on Debian and Ubuntu.
- As prereqs, make sure you have Docker, kind and kubectl installed, and tune the OS if needed (see the prereqs folder for some helper scripts).
- Run the create-all.sh script.
- Wait ~5 mins.
- Run the testlink.sh script to test connectivity (A/A) at the database level. Note: if some tests fail, allow some minutes for the deployments to fully stabilize.

## Stopping quickly 

Run the delete-all.sh script.

## What it deploys

Basics:

- Multiple (2) k8s clusters in Kind.
- Deploy [Redis Enterprise (operator)](https://redis.io/docs/latest/operate/kubernetes/architecture/operator/) in all clusters, including the admission controller.
- Optional: a loadbalancer ([metallb](https://metallb.universe.tf/)) to let the clusters talk to each other through a "public" endpoint (in the Docker kind network).
- Optional: an ingress controller ([ingress-nginx](https://github.com/kubernetes/ingress-nginx) / [haproxy-ingress](https://github.com/jcmoraisjr/haproxy-ingress)) to facilitate Redis Operator created Ingress resources.
- Optional: patch k8s DNS (coredns) to resolve the (remote) cluster api and database.

In addition, when Active/Active is enabled, it further deploys:
- A/A artifacts (Remote cluster CRDs - the 'RERC')
- A CRDB (A/A database)

## Good to know

- There are multiple haproxy ingresses. One from [HAProxy Inc.](https://github.com/haproxytech/kubernetes-ingress) and one from [jcmoraisjr](https://github.com/jcmoraisjr/haproxy-ingress). This is tested with the latter one.
- There are multiple nginx ingresses. So far this is tested with the [kubernetes 'ingress-nginx'](https://github.com/kubernetes/ingress-nginx).

## Caveats / todos

- DNS patching is hardwired to api and a named 'db1' database. 
- See the TODOs in the source.
- Currently untested (and probably not working) for >2 clusters in A/A.
- This is a scripted deployment, so not all steps are idempotent. If you change the config, you may need to tear down and recreate to get consistent again.