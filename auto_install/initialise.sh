#!/usr/bin/env bash
#!/usr/bin/env bash

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
echo "firewalld stop"

#关闭selinux
sed -i 's#SELIUX=.*#SELINUX=disabled#' /etc/selinux/config
setenforce 0
echo "selinux stop"
#修改yum源，并安装一些常用
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum makecache fast
yum install -y vim ntpdate wget

#同步时间
#cp -f /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
#ntpdate  time3.aliyun.com && hwclock  -w
yum install -y chrony
cat > /etc/chrony.conf<<EOF
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
server 192.168.31.130 iburst
# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC).
rtcsync

# Enable hardware timestamping on all interfaces that support it.
#hwtimestamp *

# Increase the minimum number of selectable sources required to adjust
# the system clock.
#minsources 2

# Allow NTP client access from local network.
#allow 192.168.0.0/16

# Serve time even if not synchronized to a time source.
#local stratum 10

# Specify file containing keys for NTP authentication.
#keyfile /etc/chrony.keys

# Specify directory for log files.
logdir /var/log/chrony

# Select which information is logged.
##log measurements statistics tracking

EOF
systemctl enable chronyd.service
systemctl start chronyd.service
chronyc sources

#修改用户名
#hostnamectl set-hostname $1


