#!/usr/bin/env bash
yum install nodejs
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
echo export NVM_DIR="$HOME/.nvm" >> /home/admin/.bash_profile
echo [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" >> /home/admin/.bash_profile
source ~/.bash_profile
npm config set registry https://registry.npm.taobao.org
npm i configurable-http-proxy -g
npm install -g pm2