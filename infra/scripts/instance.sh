#!/bin/bash

################
# PREREQ 


echo "$(date) - PREPARING machine node" >> /home/ubuntu/install.log

apt-get -y update
apt-get -y install vim
apt-get -y install iotop
apt-get -y install iputils-ping

apt-get install -y netcat
apt-get install -y dnsutils
export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"
apt-get install -y tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# cloud instance have no swap anyway
#swapoff -a
#sed -i.bak '/ swap / s/^(.*)$/#1/g' /etc/fstab
echo 'DNSStubListener=no' | tee -a /etc/systemd/resolved.conf
mv /etc/resolv.conf /etc/resolv.conf.orig
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
service systemd-resolved restart
sysctl -w net.ipv4.ip_local_port_range="40000 65535"
echo "net.ipv4.ip_local_port_range = 40000 65535" >> /etc/sysctl.conf

echo "$(date) - PREPARE done" >> /home/ubuntu/install.log

################
# kind k8s
echo "$(date) - INSTALLING docker" >> /home/ubuntu/install.log

# Install docker
apt-get install -y software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable edge"
apt-cache policy docker-ce >> /home/ubuntu/install.log
apt-get install -y docker-ce

# Install kind
echo "$(date) - INSTALLING kind" >> /home/ubuntu/install.log

curl -Lo ./kind "${kind_release}"
chmod +x ./kind
mv ./kind /usr/local/bin/kind

echo "$(date) - Creating cluster" >> /home/ubuntu/install.log
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

echo "$(date) - Install kubectl" >> /home/ubuntu/install.log
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --short
kubectl cluster-info --context kind-kind >> /home/ubuntu/install.log
cp -r .kube /home/ubuntu/.kube
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Install RE operator
echo "$(date) - INSTALLING Redis Enterprise - with operator" >> /home/ubuntu/install.log
git clone https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
cd redis-enterprise-k8s-docs/
kubectl create namespace redis
kubectl config set-context --current --namespace=redis
kubectl apply -f bundle.yaml
while ! kubectl wait --for condition=established --timeout=10s crd/redisenterpriseclusters.app.redislabs.com ; do sleep 1 ; done

# Create a RE cluster
kubectl apply -f examples/v1/rec.yaml
kubectl port-forward svc/rec-ui 8443:8443
kubectl port-forward --address localhost,0.0.0.0  svc/rec-ui 8443:8443
pw=$(kubectl get secret rec -o jsonpath="{.data.password}" | base64 --decode) 
user=$(kubectl get secret rec -o jsonpath="{.data.username}" | base64 --decode) 
echo "$(date) - RE credentials user: $user - password: $pw" >> /home/ubuntu/install.log

echo "$(date) - INSTALL done" >> /home/ubuntu/install.log
