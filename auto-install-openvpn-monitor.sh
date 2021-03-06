#!/bin/bash

echo "===============================================";
echo " "
echo " "

# Checkout OpenVPN-Monitor
cd /var/www/html
git clone https://github.com/farukbrowser/openvpn-monitor.git

# Install dependencies and configure apache
apt-get -y install python-geoip python-ipaddr python-humanize python-bottle python-semantic-version apache2 libapache2-mod-wsgi git wget geoip-database-extra

# Edit Port Apache2
cd
sed -i 's/80/99/g' /etc/apache2/ports.conf
/etc/init.d/apache2 restart

# Install dependencies and configure apache
echo "WSGIScriptAlias /openvpn-monitor /var/www/html/openvpn-monitor/openvpn-monitor.py" > /etc/apache2/conf-available/openvpn-monitor.conf
a2enconf openvpn-monitor
systemctl restart apache2
a2enconf openvpn-monitor
/etc/init.d/apache2 restart

# copy
cd /var/www/html/openvpn-monitor
cp openvpn-monitor.conf.example openvpn-monitor.conf

# test

cd /var/www/html/openvpn-monitor
python openvpn-monitor.py


# testbro

cd /var/www/html/openvpn-monitor
python openvpn-monitor.py -d



echo " "
echo " "
echo "===============================================";
