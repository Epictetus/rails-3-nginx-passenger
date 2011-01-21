#!/bin/bash
# created by TJ Stein | thomasjstein@gmail.com

shopt -s extglob
set -e
IP=`ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`

##
## are you root?
##
if [ "$(whoami)" != "root" ]; then
echo "You need to be root to run this!"
  exit 2
fi

##
## Is this Ubuntu 10.04 (Lucid)?
##
lsboutput="DISTRIB_RELEASE=10.04"
if [[ `cat /etc/lsb-release | grep 'DISTRIB_RELEASE'` != "$lsboutput" ]]; then
echo "You need Ubuntu 10.04 Lucid Lynx to run this!"
  exit 0
fi

##
## Fix /tmp issues when compiling pcre and nginx
##
mkdir ~/tmp
mount --bind ~/tmp /tmp

##
## Fix locales
##
echo "Configuring locales..."
echo "en_US.UTF-8 UTF-8" > /var/lib/locales/supported.d/local
dpkg-reconfigure locales
echo "done..."

##
## Set up install.log
##
touch ~/install.log

##
## Update and install dependencies
##
echo "Updating system..."
aptitude -y update >> ~/install.log && aptitude -y safe-upgrade >> ~/install.log
aptitude -y install wget curl git-core build-essential zlib1g-dev libssl-dev libreadline5-dev libc6 libpcre3 libssl0.9.8 zlib1g libcurl4-openssl-dev libxslt1.1 libxslt1-dev libxml2 libffi-dev libyaml-dev libreadline6-dev >> ~/install.log
echo "done..."

##
## Install imagemagick
##
echo "Installing imagemagick (this may take awhile)..."
aptitude -y install imagemagick libmagick9-dev >> ~/install.log
echo "done..."

##
## Install sql libs
##
echo "Installing libs needed for sqlite and mysql..."
aptitude -y install sqlite3 libsqlite3-dev libmysqlclient16-dev libmysqlclient16 >> ~/install.log
echo "done..."

##
## Install rvm
##
echo "Installing RVM..."
bash < <( curl -L http://bit.ly/rvm-install-system-wide ) >> ~/install.log
echo "[[ -s '/usr/local/lib/rvm' ]] && source '/usr/local/lib/rvm'" >> ~/.bashrc
source /root/.bashrc && source /usr/local/lib/rvm
echo "done..."

##
## RVM sanity check
##
rvmoutput="rvm is a function"
if [[ `type rvm | head -n1` != "$rvmoutput" ]]; then
echo "Something went wrong. RVM must be a function!"
  exit 0
fi

##
## Install ruby 1.9.2 and make it the default
##
echo "Installing Ruby 1.9.2 (this may take awhile)..."
rvm install 1.9.2 >> ~/install.log
rvm --default ruby-1.9.2 >> ~/install.log
echo "done..."

##
## Create sane .gemrc
##
touch ~/.gemrc
cat <<EOF > ~/.gemrc
---
:verbose: true
:sources:
- http://gems.rubyforge.org/
- http://gems.github.com/
:update_sources: true
:backtrace: false
:bulk_threshold: 1000
:benchmark: false
gem: --no-ri --no-rdoc

EOF

##
## Install rails gem
##
echo "Installing rails gem..."
gem install rails >> ~/install.log
echo "done..."

##
## Install passenger and grab gem
##
echo "Installing Phusion Passenger gem..."
rvm 1.9.2 --passenger >> ~/install.log
gem install passenger >> ~/install.log
echo "done..."

##
## Set up nginx
##
echo "Installing Nginx + Phusion Passenger..."
cd /root && wget -O nginx-0.8.54.tar.gz http://sysoev.ru/nginx/nginx-0.8.54.tar.gz >> ~/install.log
tar xzvf nginx-0.8.54.tar.gz >> ~/install.log
rvmsudo passenger-install-nginx-module --nginx-source-dir=/root/nginx-0.8.54
cd /etc/init.d
wget -O nginx http://bit.ly/8XU8Vl >> ~/install.log
chmod +x nginx
/usr/sbin/update-rc.d -f nginx defaults >> ~/install.log
echo "done..."

##
## Create rails testapp & start Nginx
##
echo "Creating testapp..."
cd /opt/nginx/html
rails new testapp >> ~/install.log
echo "done..."

##
## Edit nginx.conf to use new document root
##
echo "Configuring Nginx..."
sed -i".bak" '47d' /opt/nginx/conf/nginx.conf
sed -i '47 a\
            root   /opt/nginx/html/testapp/public/;' /opt/nginx/conf/nginx.conf
/etc/init.d/nginx start >> ~/install.log
echo "done..."

##
## Finishing message
##
echo ""
echo "Enjoy: http://$IP"
echo ""