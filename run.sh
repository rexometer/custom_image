#!/bin/bash

# just for formating (bold/normal)
bold=$(tput bold) #for formating (make text bold)
normal=$(tput sgr0)

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

echo "Stop emonhub"
sudo /etc/init.d/emonhub stop

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

# Copy Standard-Template
sudo rm /home/pi/data/emonhub.conf
sudo cp /home/pi/emonhub/conf/emonpi.default.emonhub.conf /home/pi/data/emonhub.conf
sudo chown pi:www-data /home/pi/data/emonhub.conf
sudo chmod ugo+w /home/pi/data/emonhub.conf

# make socket for usb serial adapter consistant
echo '#Assign fixed symlink to USB-serial adapter' | sudo tee /etc/udev/rules.d/75-CP2102.rules
echo 'SUBSYSTEM=="tty", ENV{ID_SERIAL}=="Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001",SYMLINK+="ttyREXOMETER"'  | sudo tee -a /etc/udev/rules.d/75-CP2102.rules

# Add APIKEY of emoncms remote server
echo "${bold}Optional: Enter emoncms API-Key for sending to remote server${normal}"
read APIKEY
sed -i -e "s/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/$APIKEY/g" /home/pi/data/emonhub.conf
sed -i -e 's/emoncms.org/data.rexometer.com/g' /home/pi/data/emonhub.conf

echo "RFM2PI"
cd /home/pi/
sudo rm -R RFM2Pi
git clone https://github.com/rexometer/RFM2Pi.git

echo "Update RFM2Pi fimrware (use LowPowerLab)"
sh /home/pi/emonpi/rfm69piupdate.sh

echo "app"
cd /var/www/emoncms/Modules/
sudo rm -R app
git clone https://github.com/rexometer/app.git

echo "emoncms"

cd /var/www/emoncms
# git error handling
git config --local user.email "root@emonpi.local"
git config --local user.name "emonpi"
git remote set-url origin https://github.com/rexometer/emoncms.git
git pull

echo "copy new settigs"
sudo cp default.emonpi.settings.php settings.php

#echo "change Theme"
#sed -i -e 's/theme = "basic"/theme = "rexometer"/g' /var/www/emoncms/settings.php

echo "move Standard feed files to correct location"
sudo cp $parent_path/feeds/phpfina/* /home/pi/data/phpfina/
sudo chown -R www-data:www-data /home/pi/data/phpfina/

echo "${bold}Optional: Enter Nodename for emonTH (for example emonth6, press enter for default (emonth5))${normal}"
read NODENAMETH
# default name
NODENAMETH=${NODENAMETH:=emonth5}
# search and replace
sed -i -e "s/emonth5/$NODENAMETH/g" $parent_path/input.txt
sed -i -e "s/emonth5/$NODENAMETH/g" $parent_path/feeds.txt

echo "${bold}Optional: Enter Nodename for emonTX (for example 3phase2 for NodeID 12 or 3phase3 for NodeID 13, press enter for default (3phase = NodeID 11))${normal}"
read NODENAMETX
# default name
NODENAMETX=${NODENAMETX:=3phase}
# search and replace
sed -i -e "s/3phase/$NODENAMETX/g" $parent_path/input.txt
sed -i -e "s/3phase/$NODENAMETX/g" $parent_path/feeds.txt

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
echo "Insert app-config"
mysql --user=$DB_USER --password=$DB_PASSWD $DB_NAME < $parent_path/app_config.txt

echo "Update Emoncms database"
php /home/pi/emonpi/emoncmsdbupdate.php

echo "Start emonhub"
sudo /etc/init.d/emonhub start

# Configure and activate watchdog
sudo apt-get install watchdog
sudo cp /lib/systemd/system/watchdog.service /etc/systemd/system/
echo 'WantedBy=multi-user.target'  | sudo tee -a /etc/systemd/system/watchdog.service

echo 'max-load-1 = 24'  | sudo tee -a /etc/watchdog.conf
echo 'min-memory = 1'  | sudo tee -a /etc/watchdog.conf
echo 'watchdog-device = /dev/watchdog'  | sudo tee -a /etc/watchdog.conf
echo 'watchdog-timeout = 15'  | sudo tee -a /etc/watchdog.conf

sudo systemctl daemon-reload
sudo systemctl enable watchdog
sudo systemctl start watchdog

#change hostname if branding is desired
sudo sed -i -e 's/emonpi/rexometer/g' /etc/hosts
sudo sed -i -e 's/emonpi/rexometer/g' /etc/hostname

#remove updatelog
sudo rm /home/pi/data/emonpiupdate.log

#ask for remote access installation
read -p "Add remote access via reverse SSH (y/n)? " answer
case ${answer:0:1} in
    y|Y )
        git clone https://github.com/rexometer/remote_access.git && cd remote_access && sudo chmod +x autossh.sh && ./autossh.sh
    ;;
    * )
        echo No
    ;;
esac
