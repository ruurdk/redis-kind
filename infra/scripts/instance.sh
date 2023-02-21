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
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable edge"
apt-cache policy docker-ce
apt-get install -y docker-ce

echo "$(date) - INSTALLING kind" >> /home/ubuntu/install.log

mkdir /home/ubuntu/install
wget "${kind_release}"
chmod +x "{kind_release}"

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

#tar xvf /home/ubuntu/install/redislabs*.tar -C /home/ubuntu/install

#echo "$(date) - INSTALLING Redis Enterprise - silent installation" >> /home/ubuntu/install.log

#cd /home/ubuntu/install
#sudo /home/ubuntu/install/install.sh -y 2>&1 >> /home/ubuntu/install_rs.log
#sudo adduser ubuntu redislabs

echo "$(date) - INSTALL done" >> /home/ubuntu/install.log

################
# NODE external_addr - it runs at each reboot to update it
echo "${node_id}" > /home/ubuntu/node_index.terraform
cat <<EOF > /home/ubuntu/node_externaladdr.sh
#!/bin/bash
node_external_addr=\$(curl -s ifconfig.me/ip)
/opt/redislabs/bin/rladmin node ${node_id} external_addr set \$node_external_addr
EOF
chown ubuntu /home/ubuntu/node_externaladdr.sh
chmod u+x /home/ubuntu/node_externaladdr.sh
/home/ubuntu/node_externaladdr.sh

echo "$(date) - DONE updating RS external_addr" >> /home/ubuntu/install.log
