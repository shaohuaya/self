#!/usr/bin/env bash
#1)关闭swap分区
swapoff -a
#注释掉/etc/fstab下面的swap 分区那一段

#3)k8s的yum源
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

#4)安装kubectl，kubelet，kubeadm
#Mater安装
read -p "此节点为:1.master节点 2.woker节点" $chose
case $chose in
1)
    yum install -y kubelet-1.15.3 kubeadm-1.15.3 kubectl-1.15.3
    ;;

2)
    yum install -y kubelet-1.15.3 kubeadm-1.15.3
    ;;

esac


