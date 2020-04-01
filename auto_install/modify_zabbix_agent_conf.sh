#!/usr/bin/env bash
sed -i "s/# HostMetadataItem=/HostMetadataItem=system.uname/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/Server=127.0.0.1/Server=192.168.1.27/" /etc/zabbix/zabbix_agentd.conf