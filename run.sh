#!/bin/bash

# Make FS RW
rpi-rw

echo "#############################################################"
# Clear log file
cat /dev/null >  /home/pi/data/emoncustomizer.log
echo "Starting customizer"
# Date and time
date

#Path
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# git error handling
git config --global user.email "root@emonpi.local"

# Install Homemenu module
echo "Install Homemenu module"
mkdir /home/pi/Modules
cd /home/pi/Modules
git clone -b pi https://github.com/rexometer/settings.git
ln -s /home/pi/Modules/settings /var/www/emoncms/Modules/settings
git clone https://github.com/rexometer/home.git
ln -s /home/pi/Modules/home /var/www/emoncms/Modules/home

echo "Change GIT URLs"
echo "emonpi"
cd /home/pi/
sudo rm -R emonpi/
git clone https://github.com/rexometer/emonpi.git

echo "emonhub"
cd /home/pi/
sudo rm -R emonhub/
git clone https://github.com/rexometer/emonhub.git

echo "RFM2PI"
cd /home/pi/
sudo rm -R RFM2Pi
git clone https://github.com/rexometer/RFM2Pi.git

echo "app"
cd /var/www/emoncms/Modules/
sudo rm -R app
git clone https://github.com/rexometer/app.git

echo "emoncms"
cd /var/www/emoncms
git remote set-url origin https://github.com/rexometer/emoncms.git
git pull

echo "change Theme"
sed -i -e 's/theme = "basic"/theme = "rexometer"/g' /var/www/emoncms/settings.php

DB_USER="emoncms"
DB_PASSWD="emonpiemoncmsmysql2016"
DB_NAME="emoncms"

echo "Insert Standard Dashboard"
mysql --user=$DB_USER --password=$DB_PASSWD $DB_NAME < $parent_path/dashboard.txt
echo "Insert Standard Input"
mysql --user=$DB_USER --password=$DB_PASSWD $DB_NAME < $parent_path/input.txt
echo "Insert Standard Feeds"
mysql --user=$DB_USER --password=$DB_PASSWD $DB_NAME < $parent_path/feeds.txt
echo "Insert Graph"
mysql --user=$DB_USER --password=$DB_PASSWD $DB_NAME < $parent_path/graph.txt

#change hostname if branding is desired
sudo sed -i -e 's/emonpi/rexometer/g' /etc/hosts
sudo sed -i -e 's/emonpi/rexometer/g' /etc/hostname

#remove updatelog
sudo rm /home/pi/data/emonpiupdate.log
