#!/bin/bash

OTUS_USER_PUB_KEY=$(cat ~/.ssh/otus-user-key.pub)

cat > metadata.yml << EOM

#cloud-config
users:
  - name: otus-user
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
    - $OTUS_USER_PUB_KEY
disable_root: true
timezone: Europe/Moscow
repo_update: true
repo_upgrade: true
yum:
  preserve_sources_list: true
packages:
  - epel-release
runcmd:
  - yum install -y tinyproxy wget unzip git ansible lsof tcpdump jq vim
  - systemctl enable tinyproxy.service
  - sed -i 's/Allow 127.0.0.1/Allow 10.128.10.0\/24/' /etc/tinyproxy/tinyproxy.conf
  - systemctl start tinyproxy.service
  - wget -q https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
  - unzip terraform_0.11.13_linux_amd64.zip
  - mv ./terraform /usr/sbin && chmod a+x /usr/sbin/terraform
  - mkdir -p /home/otus-user/.ssh
  - ssh-keygen -t rsa -b 4096 -f /home/otus-user/.ssh/otus-user -q -N ""
  - chown -R otus-user:otus-user /home/otus-user/.ssh
  - chmod 0700 /home/otus-user/.ssh && chmod 0644 /home/otus-user/.ssh/otus-user.pub && chmod 0600  /home/otus-user/.ssh/otus-user
  - mkdir -p /home/otus-user/otus-infra
  - git clone https://github.com/kakoka/otus-infra.git /home/otus-user/otus-infra
  - git clone --depth=1 https://github.com/amix/vimrc.git /opt/vim_runtime
  # - sh ~/.vim_runtime/install_awesome_parameterized.sh /opt/vim_runtime --all
  - chown -R otus-user:otus-user /home/otus-user
EOM

NAME="bastion"
IMAGE_FAMILY="centos-7"

CLOUD_ZONE=$(yc config get compute-default-zone)
CLOUD_NETWORK_NAME="my-network"
CLOUD_SUBNET_NAME="my-subnet"

CENTOS7_IMAGE_ID=`yc compute image list --folder-id standard-images --format json  | jq -r "map(select(.family==\"$IMAGE_FAMILY\"))|sort_by(.created_at)|last|.id"`
if [ -z "$CENTOS7_IMAGE_ID" ]; then
  echo "Failed to find latest image in family $IMAGE_FAMILY"
  exit 1
fi
echo CENTOS7_IMAGE_ID=$CENTOS7_IMAGE_ID

# Create network
yc vpc network create \
  --name $CLOUD_NETWORK_NAME

# Create subnet
yc vpc subnet create \
  --network-name $CLOUD_NETWORK_NAME \
  --name $CLOUD_SUBNET_NAME \
  --zone $CLOUD_ZONE \
  --range 10.128.10.0/24

# Create host
yc compute instance create \
  --name $NAME \
  --hostname $NAME \
  --zone $CLOUD_ZONE \
  --network-interface subnet-name=$CLOUD_SUBNET_NAME,nat-ip-version=ipv4 \
  --create-boot-disk name=$NAME-boot,type=network-hdd,size=10,image-id=$CENTOS7_IMAGE_ID,auto-delete=true \
  --platform-id standard-v1 \
  --cores 1 \
  --memory 1 \
  --core-fraction 100 \
  --metadata-from-file user-data=./metadata.yml \
  --description "Bastion host"

if [ $? -ne 0 ]; then
  echo "Failed to create instance $NAME"
  exit 1
fi
echo "Done"

rm -f metadata.yml