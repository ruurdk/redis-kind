Date: 12/04/2021  
Kind version: 0.11

{{TOC}}

# Kind Playground/Sandbox For Kubernetes

[kind](https://kind.sigs.k8s.io/) is a tool for running local Kubernetes clusters using Docker container "nodes".
I use it as a playground/sandbox on an linux google instance to experiment with different settings

Good for
* Test with different version of Kubernetes
* quickly install and verify RL
* test ingress and load balancer
* test external image repository
* check RBAC settings
* Test different deployment settings
* test zone awareness
* test upgrades

Not good for
* performance testing
* production environment


## Quick Setup

Install [docker](https://docs.docker.com/engine/install/) and [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) on the host machine. Download [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) binary and install.

e.g as of this writing for kind 0.11 on linux

```
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
```

### Create Cluster
```yaml
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF
```

### Delete Cluster
```bash
kind delete cluster
```
### Install Redis Enterprise
Creating the cluster automatically configures kubectl and you can deploy RS in normal way by cloning the [repo](https://github.com/RedisLabs/redis-enterprise-k8s-docs). No special changes are required

```yaml
kubectl create namespace redis
kubectl config set-context --current --namespace=redis
kubectl apply -f bundle.yaml
kubectl apply -f examples/v1/rec.yaml
kubectl port-forward svc/rec-ui 8443:8443
kubectl port-forward --address localhost,0.0.0.0  svc/rec-ui 8443:8443
pw=$(kubectl get secret rec -o jsonpath="{.data.password}" | base64 --decode); user=$(kubectl get secret rec -o jsonpath="{.data.username}" | base64 --decode); echo "user: $user"; echo "password: $pw"
```



#### Normal DB

```yaml
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: redb1
spec:
  memorySize: 200MB
EOF
```

#### DB With Encryption

```yaml
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: redis-enterprise-database
spec:
  memorySize: 100MB
  tlsMode: enabled
  enforceClientAuthentication: false
EOF
```

#### DB With Module

```yaml
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: ts1
spec:
  memorySize: 100MB
  modulesList:
    - name: timeseries
      version: 1.6.9
EOF
```
```bash
service_names=$(kubectl get secret redb-ts1 -o jsonpath="{.data.service_names}" | base64 --decode); pw=$(kubectl get secret redb-ts1 -o jsonpath="{.data.password}" | base64 --decode); port=$(kubectl get secret redb-ts1 -o jsonpath="{.data.port}" | base64 --decode); echo "service_name: $service_names"; echo "password: $pw"; echo "port: $port"
```

#### DB with password and port

```bash
kubectl create secret generic redisdb --from-literal=password='23V9T2GCZ4EWqy1'
```

```bash
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: redisdb
spec:
  memorySize: 100MB
  databaseSecretName: redisdb
  databasePort: 13000
  replication: true
EOF
```

```bash
kubectl get secret redisdb -o jsonpath="{.data.service_name}" | base64 --decode
kubectl get secret redisdb -o jsonpath="{.data.service_names}" | base64 --decode
kubectl get secret redisdb -o jsonpath="{.data.port}" | base64 --decode
kubectl get secret redisdb -o jsonpath="{.data.password}" | base64 --decode
```



### Use a Different Version of K8S
List of images is available [here](https://github.com/kubernetes-sigs/kind/releases).
Example to start a 1.24 cluster

```yaml
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.24.6@sha256:97e8d00bc37a7598a0b32d1fabd155a96355c49fa0d4d4790aab0f161bf31be1
- role: worker
  image: kindest/node:v1.24.6@sha256:97e8d00bc37a7598a0b32d1fabd155a96355c49fa0d4d4790aab0f161bf31be1
- role: worker
  image: kindest/node:v1.24.6@sha256:97e8d00bc37a7598a0b32d1fabd155a96355c49fa0d4d4790aab0f161bf31be1
- role: worker
  image: kindest/node:v1.24.6@sha256:97e8d00bc37a7598a0b32d1fabd155a96355c49fa0d4d4790aab0f161bf31be1
EOF
```

### Get module version

```
kubectl get rec rec -o jsonpath="{.status.modules[?(@.displayName =='RediSearch 2')].name}"
kubectl get rec rec -o jsonpath="{.status.modules[?(@.displayName =='RediSearch 2')].versions[0]}"
```
## Appendix

### Active/Active using 2 Namespaces

[link to gist](https://gist.github.com/kamran-redis/28c2115c248762301cdc470cf4459d08)
### Add Load Balancer to Kind Cluster
Metallb works with kind. See [here](https://mauilion.dev/posts/kind-metallb/) and [here](https://mauilion.dev/posts/kind-metallb/)

#### Add metallb

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

kubectl get pods -n metallb-system --watch

docker network inspect -f '{{.IPAM.Config}}' kind

```
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.100-172.18.255.250
EOF
``





### Add metrics for kubectl top

```bash
git clone https://github.com/kodekloudhub/kubernetes-metrics-server.git
kubectl create -f kubernetes-metrics-server/
```

### Taint/label Nodes

Create a 5 node cluster and label and taint some nodes

```yaml
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
- role: worker
- role: worker
EOF
```

#### Label the nodes

```bash
kubectl label nodes kind-worker  zone=A 
kubectl label nodes kind-worker2  zone=A
kubectl label nodes kind-worker3  zone=B
kubectl label nodes kind-worker4  zone=B
kubectl label nodes kind-worker5  zone=C
kubectl label nodes kind-control-plane zone=E


kubectl label nodes kind-worker  topology.kubernetes.io/zone=A 
kubectl label nodes kind-worker2  topology.kubernetes.io/zone=A
kubectl label nodes kind-worker3  topology.kubernetes.io/zone=B
kubectl label nodes kind-worker4  topology.kubernetes.io/zone=B
kubectl label nodes kind-worker5  topology.kubernetes.io/zone=C
kubectl label nodes kind-control-plane topology.kubernetes.io/zone=E
```

#### Taint the nodes

```bash
kubectl taint nodes kind-worker db=rec:NoSchedule
kubectl taint nodes kind-worker3 db=rec:NoSchedule
kubectl taint nodes kind-worker5 db=rec:NoSchedule
```

```
cat rack_aware_cluster_role_binding.yaml |sed  's/NAMESPACE_OF_SERVICE_ACCOUNT/redis/g'

```
### Add K8S Dashboard

```yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

#### Get the token  
```bash
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

#### Start the proxy
`kubectl proxy`  

And you can access the process using this url. and login using the above token. In case you need a GUI on GCP instance I use [Google Chrome Desktop](https://cloud.google.com/solutions/chrome-desktop-remote-on-compute-engine)  
```http
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Local Registry

```bash
#!/bin/sh
set -o errexit

# create registry container unless it already exists
reg_name='kind-registry'
reg_port='5000'
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:${reg_port}"]
EOF

# connect the registry to the cluster network
docker network connect "kind" "${reg_name}"

# tell https://tilt.dev to use the registry
# https://docs.tilt.dev/choosing_clusters.html#discovering-the-registry
for node in $(kind get nodes); do
  kubectl annotate node "${node}" "kind.x-k8s.io/registry=localhost:${reg_port}";
done
```

#### pull images

```bash
docker pull redislabs/redis:6.0.8-28
docker tag redislabs/redis:6.0.8-28 localhost:5000/redislabs/redis:6.0.8-28
docker push localhost:5000/redislabs/redis:6.0.8-28
docker image remove redislabs/redis:6.0.8-28 localhost:5000/redislabs/redis:6.0.8-28

docker pull redislabs/operator:6.0.8-1
docker tag redislabs/operator:6.0.8-1 localhost:5000/redislabs/operator:6.0.8-1
docker push localhost:5000/redislabs/operator:6.0.8-1
docker image remove redislabs/operator:6.0.8-1 localhost:5000/redislabs/operator:6.0.8-1

docker pull redislabs/k8s-controller:6.0.8-1
docker tag redislabs/k8s-controller:6.0.8-1 localhost:5000/redislabs/k8s-controller:6.0.8-1
docker push localhost:5000/redislabs/k8s-controller:6.0.8-1
docker image remove redislabs/k8s-controller:6.0.8-1 localhost:5000/redislabs/k8s-controller:6.0.8-1
```

#### Explore repo

```
curl  http://127.0.0.1:5000/v2/_catalog
http://localhost:5000/v2/redislabs/redis/tags/list

```

### Add ingress

#### HA Proxy jcmoraisjr
```
kubectl apply -f https://raw.githubusercontent.com/jcmoraisjr/haproxy-ingress/master/docs/haproxy-ingress.yaml
```


```
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    run: haproxy-ingress
  name: haproxy-ingress
  namespace: ingress-controller
spec:
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: 443
  selector:
    run: haproxy-ingress
  sessionAffinity: None
  type: LoadBalancer
EOF
```

create PSP

```yaml
kubectl apply -f - <<EOF
# psp.haproxy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    # Assumes apparmor available
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'docker/default'
  name: ingress-controller
spec:
  allowedCapabilities:
  - NET_BIND_SERVICE
  allowPrivilegeEscalation: true
  fsGroup:
    rule: 'MustRunAs'
    ranges:
    - min: 1
      max: 65535
  hostIPC: false
  hostNetwork: true
  hostPID: false
  hostPorts:
  - min: 80
    max: 65535
  privileged: false
  readOnlyRootFilesystem: false
  runAsUser:
    rule: 'RunAsAny'  # haproxy can't run as non-root
    ranges:
    - min: 33
      max: 65535
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
    # Forbid adding the root group.
    - min: 1
      max: 65535
  volumes:
  - 'configMap'
  - 'downwardAPI'
  - 'emptyDir'
  - 'projected'
  - 'secret'

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ingress-controller-psp
  namespace: ingress-controller
rules:
- apiGroups:
  - policy
  resourceNames:
  - ingress-controller
  resources:
  - podsecuritypolicies
  verbs:
  - use

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ingress-controller-psp
  namespace: ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-controller-psp
subjects:
# Lets cover default and ingress-controller service accounts
- kind: ServiceAccount
  name: default
- kind: ServiceAccount
  name: ingress-controller
EOF
```

```bash
kubectl label node --all role=ingress-controller
```

Create the ingress service

```yaml
kubectl apply -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    ingress.kubernetes.io/ssl-passthrough: "true"
    kubernetes.io/ingress.class: haproxy
  name: redis-enterpriseha1
  namespace: demo
spec:
  rules:
  - host: api.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise
          servicePort: api
        path: /
  - host: ui.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise-ui
          servicePort: ui
        path: /
  - host: db.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise-database
          servicePort: redis
        path: /
EOF
```


##### test

```bash
EX_IP=$(kubectl get svc -n ingress-controller haproxy-ingress -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo $EX_IP
DB_PASSWORD=$(kubectl get secret redb-redis-enterprise-database -o jsonpath="{.data.password}" | base64 --decode)
echo $DB_PASSWORD
RL_USER=$(kubectl get secret redis-enterprise -o jsonpath="{.data.username}" | base64 --decode)
echo $RL_USER
RL_PASSWORD=$(kubectl get secret redis-enterprise -o jsonpath="{.data.password}" | base64 --decode)
echo $RL_PASSWORD
```

##### ui

```bash
curl  -k --resolve ui.redis.com:443:$EX_IP  https://ui.redis.com:443
```

##### db

```bash
openssl s_client -servername db.redis.com  -connect ${EX_IP}:443
curl -s -k --resolve api.redis.com:443:${EX_IP}  https://api.redis.com/v1/cluster -u "${RL_USER}:${RL_PASSWORD}"|jq -r .proxy_certificate|awk '{gsub(/\\n/,"\n")}1' > proxy.crt
redis-cli --tls --cacert ./proxy.crt --sni db.redis.com -h $EX_IP  -p 443 -a $DB_PASSWORD
```

#### Nginx

For api as the service is headless, it does not work with Nginx. I had to create a separate service

```
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: redis-enterprise
    redis.io/cluster: redis-enterprise
  name: redis-enterprise-api 
  namespace: demo
spec:
  ports:
  - name: api
    port: 9443
    protocol: TCP
    targetPort: 9443
  selector:
    app: redis-enterprise
    redis.io/cluster: redis-enterprise
    redis.io/role: node
    redis.io/role-master: "1"
  sessionAffinity: None
  type: ClusterIP
EOF
```

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.40.1/deploy/static/provider/cloud/deploy.yaml
```


##### Add startup parameter

```
kubectl edit  deployments.apps -n ingress-nginx

--enable-ssl-passthrough
```

```yaml
kubectl apply -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
      kubernetes.io/ingress.class: "nginx"
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  name: redis-enterprisenginx
  namespace: demo
spec:
  rules:
  - host: api.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise-api  #Note using manually created service with Cluster IP
          servicePort: api
        path: /
  - host: ui.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise-ui
          servicePort: ui
        path: /
  - host: db.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise-database
          servicePort: redis
        path: /
EOF
```

```
EX_IP=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo $EX_IP
```

##### Nginx tcp expose

[Exposing TCP and UDP services](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/)

```bash
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: testrdb
spec:
  redisEnterpriseCluster:
    name: redis-enterprise
  memorySize: 100MB
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-services
  namespace: ingress-nginx
data:
  6379: "demo/testrdb:redis"
EOF
```

```
kubectl edit  deployments.apps -n ingress-nginx

--tcp-services-configmap=$(POD_NAMESPACE)/tcp-services


kubectl edit  svc ingress-nginx-controller  -n ingress-nginx

    - name: proxied-tcp-6379
      port: 6379
      targetPort: 6379
      protocol: TCP
```

#### HA Proxy Official

```
kubectl apply -f https://raw.githubusercontent.com/haproxytech/kubernetes-ingress/master/deploy/haproxy-ingress.yaml
# patch to change from NodePort to LoadBalancer
kubectl patch svc haproxy-ingress -n haproxy-controller -p '{"spec":{"type":"LoadBalancer"}}'
```

Create the ingress service
```yaml
kubectl apply -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    haproxy.org/ssl-passthrough: "true"
    #haproxy.org/ingress.class: "haproxy"
  name: redis-enterpriseha2
  namespace: demo
spec:
  rules:
  - host: api.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise
          servicePort: api
        path: /
  - host: ui.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise-ui
          servicePort: ui
        path: /
  - host: db.redis.com
    http:
      paths:
      - backend:
          serviceName: redis-enterprise-database
          servicePort: redis
        path: /
EOF
```

```bash
EX_IP=$(kubectl get svc haproxy-ingress -n haproxy-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo $EX_IP
```


### kitchensink Example
```yaml
apiVersion: app.redislabs.com/v1
kind: RedisEnterpriseCluster
metadata:
  name: "redis-enterprise-learning"
spec:
  nodes: 3
  serviceAccountName: redis-enterprise-sa
  createServiceAccount: false
  #nodeSelector:
  #  cloud.google.com/gke-nodepool: pool-1
  extraLabels:
    example1: "some-value"
    example2: "some-value"
  podAnnotations:
    anno1: "anno1-value"
    anno2: "anno2-value"
  persistentSpec:
    enabled: true
    storageClassName: "standard"
    volumeSize: 10Gi
  redisEnterpriseNodeResources:
    limits:
      cpu: "3"
      memory: 4Gi
    requests:
      cpu: "3"
      memory: 4Gi
  username: admin@redislabs.com
  sideContainersSpec:
    - image: ubuntu
      name: ubuntu
      command: [ "sleep" ]
      args: [ "infinity" ]
      volumeMounts:
        - mountPath: /opt/persistent
          name: redis-enterprise-storage
        - mountPath: /var/opt/redislabs/log
          name: redis-enterprise-storage
          subPath: logs
```

-------------------------------------------------------
## NOT  WORKING
### With custom volume

```yaml
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1
kind: RedisEnterpriseCluster
metadata:
  name: rec
spec:
  # Add fields here
  nodes: 3
  redisEnterpriseVolumeMounts:
  - mountPath: /backup
    name: backup-volume
  volumes:
  - name: backup-volume
    persistentVolumeClaim:
      claimName: redis-enterprise-backup
EOF
```

### 2
```yaml
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1
kind: RedisEnterpriseCluster
metadata:
  name: rec
spec:
  # Add fields here
  nodes: 3
  volumes:
  - name: backup-volume
    persistentVolumeClaim:
      claimName: redis-enterprise-backup
  sideContainersSpec:
    - image: ubuntu
      name: ubuntu
      command: [ "sleep" ]
      args: [ "infinity" ]
      volumeMounts:
        - mountPath: /opt/persistent
          name: redis-enterprise-storage
        - mountPath: /var/opt/redislabs/log
          name: redis-enterprise-storage
          subPath: logs
        - mountPath: /backup
          name: backup-volume
EOF
```
------------------------------------------------
# 3 Not working Invalid Spec request: volume mount name redis-enterprise-storage is reserved"
```yaml
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1
kind: RedisEnterpriseCluster
metadata:
  name: rec
spec:
  # Add fields here
  nodes: 3
  redisEnterpriseVolumeMounts:
  - mountPath: /opt/backup
    name: redis-enterprise-storage
    subPath: backup
EOF
```

# 4 
```yaml
kubectl apply -f - <<EOF
apiVersion: app.redislabs.com/v1
kind: RedisEnterpriseCluster
metadata:
  name: rec
spec:
  # Add fields here
  nodes: 3
  sideContainersSpec:
    - image: ubuntu
      name: ubuntu
      command: [ "sleep" ]
      args: [ "infinity" ]
      volumeMounts:
        - mountPath: /opt/persistent
          name: redis-enterprise-storage
        - mountPath: /var/opt/redislabs/log
          name: redis-enterprise-storage
          subPath: logs
        - mountPath: /opt/backup
          name: redis-enterprise-storage
          subpath: backup
EOF
```

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-enterprise-backup
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
```
