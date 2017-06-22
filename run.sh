#!/bin/bash

# Make FS RW
rpi-rw

echo "#############################################################"
# Clear log file
cat /dev/null >  /home/pi/data/emoncustomizer.log
echo "Starting customizer"
# Date and time
date

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
cd /home/pi/emonpi
git remote set-url origin https://github.com/rexometer/emonpi.git
sudo git pull

echo "emonhub"
cd /home/pi/emonhub
git remote set-url origin https://github.com/rexometer/emonhub.git
sudo git pull

echo "RFM2PI"
cd /home/pi/RFM2Pi
git remote set-url origin https://github.com/rexometer/RFM2Pi.git
sudo git pull

echo "app"
cd /var/www/emoncms/Modules/app
git remote set-url origin https://github.com/rexometer/app.git
sudo git pull


$DB_USER = emoncms
$DB_PASSWD = emonpiemoncmsmysql2016
$DB_NAME = emoncms

echo "Insert Standard Dashboard"
mysql --user=$DB_USER --password=$DB_PASSWD $DB_NAME < dashboard.txt
echo "Insert Standard Input"
mysql --user=$DB_USER --password=$DB_PASSWD $DB_NAME < input.txt
echo "Insert Standard Feeds"
mysql --user=$DB_USER --password=$DB_PASSWD $DB_NAME < feed.txt
