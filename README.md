# Redis k8s operator deployment on Kind

By default, this set of scripts will set up a fully functioning Redis [Active-Active database](https://redis.io/active-active/) distributed over 2 Redis clusters running on seperate vanilla/community k8s clusters deployed in [kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker).

## Requirements

A single Linux - Debian 12 or Ubuntu 24 - x86 host with enough resources (see at the bottom for validated configurations).
Some tools and OS tuning is required. Run the prereqs/install-fresh script and Reboot.

## Getting started quickly

- Run the create-all.sh script.
- Wait 5-10 mins depending on the hardware.

## Stopping quickly 

Run the delete-all.sh script.

## What it deploys

Basics:

- A configurable number (default = 2) k8s clusters in Kind
- Deploy [Redis Enterprise (operator)](https://redis.io/docs/latest/operate/kubernetes/architecture/operator/) in all clusters.
- Create Redis clusters in all k8s clusters. 
- Create a Redis database (geo-replicated CRDB in case of Active/Active).

Optional: 
- Deploy the Redis Enterprise admission controller.
- Rack zone aware deployment.
- a loadbalancer ([metallb](https://metallb.universe.tf/)) to let the clusters talk to each other through a "public" endpoint (in the Docker kind network).
- an ingress controller ([ingress-nginx](https://github.com/kubernetes/ingress-nginx) / [haproxy-ingress](https://github.com/jcmoraisjr/haproxy-ingress)) to facilitate Redis Operator created Ingress resources.
- patch k8s DNS (coredns) to resolve the (remote) cluster api and database.
- monitoring through Prometheus + Grafana and [preconfigured Redis dashboards](https://github.com/redis-field-engineering/redis-enterprise-observability/tree/main/grafana).

## Good to know

- There are multiple haproxy ingresses. One from [HAProxy Inc.](https://github.com/haproxytech/kubernetes-ingress) and one from [jcmoraisjr](https://github.com/jcmoraisjr/haproxy-ingress). This is tested with the latter one.
- There are multiple nginx ingresses. So far this is tested with the [kubernetes 'ingress-nginx'](https://github.com/kubernetes/ingress-nginx). 
- There are more Ingresses that work, such as the [Nginx Inc. (F5) Ingress Nginx Controller](https://docs.nginx.com/nginx-ingress-controller/overview/design/) and [Contour](https://projectcontour.io/). However, they require (manual) creation of CRDs for SSL/TLS passthrough if regular Ingress Kubernetes resources are not supporting passthrough. E.g. [TransportServer](https://docs.nginx.com/nginx-ingress-controller/configuration/transportserver-resource/) for Nginx Inc. or [HTTPProxy](https://projectcontour.io/docs/1.30/config/api/) for Contour.

## Caveats / todos

- DNS patching is hardwired to api and a named 'db1' database. 
- This is a scripted deployment, so not all steps are idempotent. If you change the config, you may need to tear down and recreate to get consistent again.

### Minimum hardware requirements

The minimum proper setup with 2 participating Redis clusters (3 k8s worker nodes each) requires 16GB of RAM, a 30GB OS disk, and >4 *physical CPU cores*.

Some tested configs that work:
- physical i5-9600K (6 cores @ 4.5 GHz)
- GCP n2-standard-8 (8 vCPU - 4 cores @ 2.1-2.8 GHz)
- AWS t3.2xlarge (8 vCPU @ 2.5 GHz)

What won't work:
- GCP n2-standard-4 (4 vCPU - 2 cores @ 2.1-2.8 GHz)
- GCP c2-standard-4 (4 vCPU - 2 cores @ 3.1 GHz)
- AWS t3.xlarge (4 vCPU @ 2.5 GHz)