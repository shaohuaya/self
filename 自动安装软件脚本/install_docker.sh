#!/usr/bin/env bash
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

sudo yum install -y docker-ce-18.06.1.ce
sudo systemctl enable docker && sudo systemctl start docker