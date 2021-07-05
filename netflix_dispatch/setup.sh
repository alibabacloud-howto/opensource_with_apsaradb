#!/bin/sh

# Install docker & docker-compose
dnf install -y device-mapper-persistent-data lvm2
dnf config-manager --add-repo=https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
dnf list docker-ce
dnf install -y docker-ce --nobest
systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose -v

# Install Git client
dnf install -y git

# Checkout Dispatch
git clone https://github.com/Netflix/dispatch-docker.git
