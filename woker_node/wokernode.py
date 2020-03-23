#!/usr/bin/env python
#coding=utf-8

import commands
import subprocess
import os
import time,datetime
import schedule
import math
from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkecs.request.v20140526.CreateInstanceRequest import CreateInstanceRequest
from aliyunsdkecs.request.v20140526.DeleteInstanceRequest import DeleteInstanceRequest
from server3.entity.user import User
from server3.service.logger_service import send_ping
from createinstance import AliyunRunInstancesExample


#判断pod数量,以及node数量
podnum = commands.getoutput('kubectl get pods -l app=jupyterhub|grep Running|wc -l')
nodenum = commands.getoutput('kubectl get nodes|grep Ready|wc -l') - 1

# 获取总人数
print(time.ctime())
users = User.objects
users.update(pong=False)
print('User num: ', len(users), flush=True)
allusernum = len(users)
send_ping()
time.sleep(2 * 60)
# 获取离线人数
users = User.objects
offline_users = [user for user in users if not user.pong] + list(User.objects(username='luxu99'))
print('Offline user num: ', len(offline_users), flush=True)
offline_usernum = len(offline_users)
# 在线人数
online_usernum = allusernum - offline_usernum



def deletePod():
    os.system("kubectl delete pods -l app=jupyterhub")
def deleteNode():
    os.system("kubectl get node | grep NotReady | awk '{print $1}' | xargs kubectl delete node")

def createInstance():
    AliyunRunInstancesExample()


#判断是否开启新的node
if (math.ceil(nodenum*16 - online_usernum /60) < 2) :
    createInstance

# 在中午12点,下午6点,晚上12点清理掉pod和node节点
schedule.every().day.at("12:00").do(deletePod)
schedule.every().day.at("18:00").do(deletePod)
schedule.every().day.at("23:45").do(deletePod)
schedule.every().day.at("12:05").do(deleteNode)
schedule.every().day.at("18:05").do(deleteNode)
schedule.every().day.at("23:50").do(deleteNode)

while True:
    schedule.run_pending()
    time.sleep(1)