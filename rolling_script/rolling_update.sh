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
    sed -i "s/^[[:space:]]*\(ENV = '.*'\)/# \1/i" ${JUPYTERHUBCONFIGPY}

    # 将# ENV = '${ENV}'的注释去掉
    sed -i "s/#[[:space:]]*\(ENV = '${ENV}'\)/\1/i" ${JUPYTERHUBCONFIGPY}
  sed -i "s/^[[:space:]]*\(ENV = '.*'\)/# \1/i" ${JUPYTERHUBCONFIGPY}

  # 将# ENV = '${ENV}'的注释去掉
    sed -i "s/#[[:space:]]*\(ENV = '${ENV}'\)/\1/i" ${JUPYTERHUBCONFIGPY}

    # 如果没有抓取到ENV = '${ENV}'
    if ! grep "ENV = '${ENV}'" ${JUPYTERHUBCONFIGPY} &>> /dev/null; then
            # 就报错并退出程序
            echo "can't find ENV = '${ENV}' in ${JUPYTERHUBCONFIGPY}"
            exit 2
    fi

    echo "modify result"
    echo "`cat ${JUPYTERHUBCONFIGPY} | grep -C 5 ${ENV}`"
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
  rm -rf /home/admin/www/mo_prod/frontend.bak1 /home/admin/www/mo_prod/frontend.bak2
  echo "delete frontend.bak1 frontend.bak2 over"
  echo "copy frontend"
  cp -r /home/admin/www/mo_prod/frontend /home/admin/www/mo_prod/frontend.bak
  echo "copy frontend over"
  echo "build前端"
  docker run --rm --name frontend -it -v /home/admin/www/mo_prod/frontend.bak:/opt/app-root/src/www/mo_prod/frontend --network host 192.168.31.11:5000/frontend:dev npm run build
  echo "build前端over"
  sudo chown -R admin.admin /home/admin/www/mo_prod/frontend.bak/dist
  mv frontend frontend.bak1
  mv frontend.bak frontend
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
  supervisorctl restart git
  supervisorctl restart crash
  supervisorctl restart email_sender
  supervisorctl restart job_service
  supervisorctl restart klaus
  supervisorctl restart kube_job_cleaner
  superviserctl restart live_celery
  superviserctl restart notebook_auto_test
  superviserctl restart pods_cleaner
  superviserctl restart schedule_snap_uaa
  superviserctl restart temp_user_creator
  echo "restart ok"
}

function install_python_packages(){
    echo "start install python packages..."
    # venvwrapper
    export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.6
    export WORKON_HOME=${HOME}/.virtualenvs
    source /usr/bin/virtualenvwrapper.sh
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
read -p "请输入数字来选择你要做的：1.部署前端 2.准备部署后端(拉代码之前) 3.部署后端(拉完代码之后执行) 4.抢救前端  5.重启脚本 " I
case $I in
 1)
        echo "部署前端"
        init
        tag
        modify_config_files
        build_frontend
        upload_files_to_oss
        restart_supervisor
        ;;
 2)
        echo "准备部署后端(拉代码之前)"
        change_nginx
        ;;
 3)
        echo "部署后端(拉完代码之后执行)"
        init
        modify_config_files
        install_python_packages
        restart_backend
        ;;
 4)
        echo "抢救build错了的前端"
        help_build
        ;;
esac

