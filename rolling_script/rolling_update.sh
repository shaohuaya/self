#!/usr/bin/env bash


#需要先拉好代码
#加载环境变量
function init() {
    if [[ -f rolling.conf ]] ; then
     source  ./rolling.conf
    fi
}
# 打tag并修改版本号
function tag() {
  read -p "Enter version number:" VersionNum
  cd $MO_HOME
  git tag -a "$VersionNum" -m "更新版本"
  git push origin "$VersionNum"
#  修改版本号
  sed -i "s/betaVersion.*/betaVersion: \'$VersionNum\'/g" /home/admin/www/mo_prod/frontend/src/constants.js
  git push
}


#修改配置文件的环境变量
function modify_config_files(){
    # modify constants.py
    echo "modify constants.py"
    # 将其他没被注释的ENV注释起来
    sed -i "s/^[[:space:]]*\(ENV = '.*'\)/# \1/i" ${CONSTANTSPY}

    # 将# ENV = '${ENV}'的注释去掉
    sed -i "s/#[[:space:]]*\(ENV = '${ENV}'\)/\1/i" ${CONSTANTSPY}

    # 如果没有抓取到ENV = '${ENV}'
    if ! grep "ENV = '${ENV}'" ${CONSTANTSPY} &>> /dev/null; then
            # 就报错并退出程序
            echo "can't find ENV = '${ENV}' in ${CONSTANTSPY}"
            exit 2
    fi

    echo "modify result"
    echo "`cat ${CONSTANTSPY} | grep -C 5 '^ENV.*'`"


    # modify config.js
    echo "modify config.js"
    # 将其他没被注释的conf.*注释起来
    sed -i "s@^[[:space:]]*\(conf\..*\)@  // \1@i" ${CONFIGJS}

    # 将// conf.${ENV}的注释去掉
    sed -i "s@[[:space:]]*//[[:space:]]*\(conf\.${ENV}.*\)@  \1@i" ${CONFIGJS}

    # 如果没有抓取到conf.${ENV}
    if ! grep "conf\.${ENV}" ${CONFIGJS} &>> /dev/null; then
            # 就报错并退出程序
            echo "can't find conf.${ENV} in ${CONFIGJS}"
            exit 2
    fi

    echo "modify result"
    echo "`cat ${CONFIGJS} | grep -A 10 '^module\.exports'`"
    # modify __init__.py
    echo "modify __init__.py"
    # 将其他没被注释的ENV注释起来
    sed -i "s/^[[:space:]]*\(ENV = '.*'\)/# \1/i" ${INITPY}

    # 将# ENV = '${OS}'的注释去掉
    sed -i "s/#[[:space:]]*\(ENV = '${OS}'\)/\1/i" ${INITPY}

    # 如果没有抓取到ENV = '${OS}'
    if ! grep "ENV = '${OS}'" ${INITPY} &>> /dev/null; then
            # 就报错并退出程序
            echo "can't find ENV = '${OS}' in ${INITPY}"
            exit 2
    fi

    echo "modify result"
    echo "`cat ${INITPY} | grep -C 5 '^ENV.*'`"


    # modify jupyterhub_config.py
    echo "modify jupyterhub_config.py"

    # 将其他没被注释的ENV注释起来
#    sed -i "s/^[[:space:]]*\(ENV = '.*'\)/# \1/i" ${JUPYTERHUBCONFIGPY}
#
#    # 将# ENV = '${ENV}'的注释去掉
#    sed -i "s/#[[:space:]]*\(ENV = '${ENV}'\)/\1/i" ${JUPYTERHUBCONFIGPY}
#    sed -i "s/^[[:space:]]*\(ENV = '.*'\)/# \1/i" ${JUPYTERHUBCONFIGPY}
#
#  # 将# ENV = '${ENV}'的注释去掉
#    sed -i "s/#[[:space:]]*\(ENV = '${ENV}'\)/\1/i" ${JUPYTERHUBCONFIGPY}
#
#    # 如果没有抓取到ENV = '${ENV}'
#    if ! grep "ENV = '${ENV}'" ${JUPYTERHUBCONFIGPY} &>> /dev/null; then
#            # 就报错并退出程序
#            echo "can't find ENV = '${ENV}' in ${JUPYTERHUBCONFIGPY}"
#            exit 2
#    fi
#
#    echo "modify result"
#    echo "`cat ${JUPYTERHUBCONFIGPY} | grep -C 5 ${ENV}`"
    # modify request.ts
    echo "modify request.ts"
    # 将其他没被注释的ENV注释起来
    sed -i "s@^exports.conf@// exports.conf@i" ${REQUESTTS}
    # 打开注释
    sed -i "s/\/\/ exports.conf = basicConf.${ENV};/exports.conf = basicConf.${ENV};/g" ${REQUESTTS}
    sed -i "s/\/\/ export const conf = basicConf.${ENV};/exports.conf = basicConf.${ENV};/g" ${REQUESTTS}
    # 如果没有抓取到basicConf.'${ENV}'
    if ! grep "basicConf.${ENV}" ${REQUESTTS} &>> /dev/null; then
            # 就报错并退出程序
            echo "can't find basicConf.${ENV} in ${REQUESTTS}"
            exit 2
    fi
}

#修改数据库的地址指向（需要加一个判断防止误改）
#function mongo() {
#    sed -i '/[MO]/{n;s/127.0.0.1/192.168.1.73/;}' /home/admin/www/mo_prod/pyserver/server3/repository/config.ini
#}

#build前端
function build_frontend() {
  echo "delete frontend.bak1 frontend.bak2"
  sudo rm -rf /home/admin/www/mo_prod/frontend.bak1 /home/admin/www/mo_prod/frontend.bak2
  echo "delete frontend.bak1 frontend.bak2 over"
  echo "copy frontend"
  sudo cp -r /home/admin/www/mo_prod/frontend /home/admin/www/mo_prod/frontend.bak
  echo "copy frontend over"
  echo "build前端"
  docker run --rm --name frontend -it -v /home/admin/www/mo_prod/frontend.bak:/opt/app-root/src/www/mo_prod/frontend --network host magicalion/pyserver:frontend-mo-box npm i
  docker run --rm --name frontend -it -v /home/admin/www/mo_prod/frontend.bak:/opt/app-root/src/www/mo_prod/frontend --network host magicalion/pyserver:frontend-mo-box npm run build
  echo "build前端over"
  sudo chown -R admin.admin /home/admin/www/mo_prod/frontend.bak
  mv /home/admin/www/mo_prod/frontend /home/admin/www/mo_prod/frontend.bak1
  mv /home/admin/www/mo_prod/frontend.bak /home/admin/www/mo_prod/frontend
}
#抢救build错了的前端
function help_build() {
    mv /home/admin/www/mo_prod/frontend /home/admin/www/mo_prod/frontend.bak2
    mv /home/admin/www/mo_prod/frontend.bak1 /home/admin/www/mo_prod/frontend
}
#上传到七牛云
function upload_files_to_oss(){
    /home/admin/.virtualenvs/moenv/bin/python ${SCRIPT_DIR}/oss_business.py
    echo "upload files to oss complete ok"
}


#然后重启supervisor里的所有服务除了hub
function restart_supervisor() {
  sudo supervisorctl restart git
  sudo supervisorctl restart crash
  sudo supervisorctl restart email_sender
  sudo supervisorctl restart job_service
  sudo supervisorctl restart klaus
  sudo supervisorctl restart kube_job_cleaner
  sudo superviserctl restart live_celery
  sudo superviserctl restart notebook_auto_test
  sudo superviserctl restart pods_cleaner
  sudo superviserctl restart schedule_snap_uaa
  sudo superviserctl restart temp_user_creator
  echo "restart ok"
}

function install_python_packages(){
    echo "start install python packages..."
    # venvwrapper
    export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.6
    export WORKON_HOME=${HOME}/.virtualenvs
    source /usr/local/bin/virtualenvwrapper.sh
    workon moenv
    if ! pip install -r ${REQUIREMENTSTXT} 2> ${PIPERRORLOG} > /dev/null; then
    cat ${PIPERRORLOG}
    fi
    deactivate
    echo "install complete..."
}

function change_nginx(){
    VAR="eth0"
    HOST_IP=$(ifconfig eth0|grep netmask|awk '{print $2}')
    ssh production "sudo sed -i 's/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4 down/' /etc/nginx/conf.d/default.conf"
    ssh production "sudo nginx -s reload"
}

function change_nginx_back(){
    VAR="eth0"
    HOST_IP=$(ifconfig eth0|grep netmask|awk '{print $2}')
    ssh production "sudo sed -i 's/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4 down/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4/' /etc/nginx/conf.d/default.conf"
    ssh production "sudo nginx -s reload"
}
function restart_backend() {
    pm2 restart run
}


function zju_change_nginx() {
    #更前端1和后端1,更新前跑一下避免影响正常运行
    VAR="eth0"
    HOST_IP1=$(ifconfig eth0|grep netmask|awk '{print $2}')
    #修改反向代理nginx
    ssh root@frontend "sudo sed -i 's/server $HOST_IP1:8899;/server $HOST_IP1:8899 down;/' /etc/nginx/conf.d/default.conf"
    ssh root@frontend "sudo nginx -s reload"
    #修改前端2只指向一个后端2
    HOSTNAME=`hostname`
    if [[ $HOSTNAME == "k8s-master1" ]]; then
        ssh root@k8s-master2 "sudo sed -i 's/server 10.200.11.133:5005 max_fails=3 fail_timeout=10s weight=4/& down/' /etc/nginx/conf.d/default.conf"
        ssh root@k8s-master2 "nginx -s reload"
        else
            ssh root@k8s-master1 "sudo sed -i 's/server 10.200.11.134:5005 max_fails=3 fail_timeout=10s weight=4/& down/' /etc/nginx/conf.d/default.conf"
            ssh root@k8s-master1 "nginx -s reload"
    fi
}

function zju_change_nginx_back() {
    VAR="eth0"
    HOST_IP1=$(ifconfig eth0|grep netmask|awk '{print $2}')
    #修改反向代理nginx
    ssh root@frontend "sudo sed -i 's/server $HOST_IP1:8899 down;/server $HOST_IP1:8899;/' /etc/nginx/conf.d/default.conf"
    ssh root@frontend "sudo nginx -s reload"
    HOSTNAME=`hostname`
    if [[ $HOSTNAME == "k8s-master1" ]]; then
        ssh root@k8s-master2 "sudo sed -i 's/server 10.200.11.133:5005 max_fails=3 fail_timeout=10s weight=4 down;/sudo sed -i 's/server 10.200.11.133:5005 max_fails=3 fail_timeout=10s weight=4;/' /etc/nginx/conf.d/default.conf"
        ssh root@k8s-master2 "nginx -s reload"
        else
            ssh root@k8s-master1 "sudo sed -i 's/server 10.200.11.134:5005 max_fails=3 fail_timeout=10s weight=4 down;/server 10.200.11.134:5005 max_fails=3 fail_timeout=10s weight=4;/' /etc/nginx/conf.d/default.conf"
            ssh root@k8s-master1 "nginx -s reload"
    fi
}

function zju_change_nginx_backend() {
    VAR="eth0"
    HOST_IP=$(ifconfig eth0|grep netmask|awk '{print $2}')
    ssh k8s-master1 "sudo sed -i 's/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4 down/' /etc/nginx/conf.d/default.conf"
    ssh k8s-master1 "sudo nginx -s reload"
    ssh k8s-master2 "sudo sed -i 's/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4 down/' /etc/nginx/conf.d/default.conf"
    ssh k8s-master2 "sudo nginx -s reload"
}
function zju_change_nginx_backend_back() {
    VAR="eth0"
    HOST_IP=$(ifconfig eth0|grep netmask|awk '{print $2}')
    ssh k8s-master1 "sudo sed -i 's/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4 down/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4/' /etc/nginx/conf.d/default.conf"
    ssh k8s-master1 "sudo nginx -s reload"
    ssh k8s-master2 "sudo sed -i 's/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4 down/server $HOST_IP:5005 max_fails=3 fail_timeout=10s weight=4/' /etc/nginx/conf.d/default.conf"
    ssh k8s-master2 "sudo nginx -s reload"
}



read -p "请输入数字来选择:1.ZJU 部署前端 2.ZJU部署后端拉代码前更改nginx 3.部署后端并安装包 4.ZJU拉完后端之后更改nginx 5.restart supervisor的脚本 6.改配置文件 " I
case $I in


 1)     echo "部署ZJU前端"
        init
        modify_config_files
        build_frontend
        ;;
 2)     echo "ZJU更改nginx配置"
        zju_change_nginx_backend
        ;;
 3)     echo "安装python包"
        init
        modify_config_files
        install_python_packages
        restart_backend
        echo "完毕"
        ;;
 4)     echo "ZJU恢复nginx配置"
        zju_change_nginx_backend_back
        echo "完毕"
        ;;
 5)     echo "重启supervisor的脚本"
        restart_supervisor
        echo "重启完成"
        ;;
 6)     echo "改配置文件"
        init
        modify_config_files
        echo "完成"
        ;;
esac

