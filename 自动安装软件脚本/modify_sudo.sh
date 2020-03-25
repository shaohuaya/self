#!/usr/bin/env bash
# create admin user
adduser admin
#cp -a /root/.ssh /home/admin/
#chown -R admin:admin /home/admin/.ssh
echo 'admin    ALL=(ALL)       ALL' | sudo EDITOR='tee -a' visudo
echo 'admin        ALL=(ALL)       NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
su - admin



# docker conifg
sudo su -
cat <<EOF > /etc/docker/daemon.json
{
    "insecure-registries": ["10.200.11.139:5000"],
    "registry-mirrors": [
        "https://dockerhub.azk8s.cn",
        "https://reg-mirror.qiniu.com"
    ]
}
EOF
su - admin
sudo systemctl restart docker

# add groups
sudo su -
usermod -aG docker admin
groupadd dataset
groupmod -g 1111 dataset
usermod -aG dataset admin
su - admin