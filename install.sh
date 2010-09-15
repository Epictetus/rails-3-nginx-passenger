#!/bin/bash

##
## are you root?
##
if [ "$(whoami)" != "root" ]; then
echo "You need to be root to run this!"
  exit 2
fi

##
## is this Ubuntu 10.04 (Lucid)?
##
lsboutput="DISTRIB_RELEASE=10.04"
if [[ `cat /etc/lsb-release | grep 'DISTRIB_RELEASE'` != "$lsboutput" ]]; then exit 0; else echo "win"; fi

##
## fix /tmp issues when compiling pcre and nginx
##
mkdir ~/tmp
mount --bind ~/tmp /tmp

##
## update and install dependencies
##
aptitude -y update && aptitude -y safe-upgrade
aptitude -y install curl git-core build-essential zlib1g-dev libssl-dev libreadline5-dev libc6 libpcre3 libssl0.9.8 zlib1g

##
## install rvm
##
bash < <( curl -L http://bit.ly/rvm-install-system-wide )
echo "[[ -s '/usr/local/lib/rvm' ]] && source '/usr/local/lib/rvm'" >> ~/.bashrc
source /root/.bashrc && source /usr/local/lib/rvm 

##
## sanity check
##
rvmoutput="rvm is a function"
if [[ `type rvm | head -n1` != "$rvmoutput" ]]; then exit 0; else echo "win"; fi

##
## install ruby 1.9.2 and make it the default
##
rvm install 1.9.2
rvm --default ruby-1.9.2

##
## install rails gem
##
gem install rails

##
## set passenger and grab gem
##
rvm 1.9.2 --passenger
gem install passenger

##
## set up nginx
##
cd /root && wget -O nginx-0.7.67.tar.gz http://sysoev.ru/nginx/nginx-0.7.67.tar.gz
tar xzvf nginx-0.7.67.tar.gz
rvmsudo passenger-install-nginx-module --nginx-source-dir=/root/nginx-0.7.67
cd /etc/init.d
wget -O nginx http://bit.ly/8XU8Vl
chmod +x nginx
/usr/sbin/update-rc.d -f nginx defaults

##
## create rails testapp
##
cd /opt/nginx/html
rails new testapp

##
## edit nginx.conf to use new document root
##
sed -i".bak" '47d' /opt/nginx/conf/nginx.conf
sed -i '47 a\
            root   /opt/nginx/html/testapp/public/;' /opt/nginx/conf/nginx.conf
/etc/init.d/nginx start

##
## umount ~/tmp
##
umount /tmp

exit 0