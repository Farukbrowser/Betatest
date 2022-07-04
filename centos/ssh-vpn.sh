#!/bin/bash
# https://metanux.id/mengatasi-error-cannot-retrieve-metalink-for-repository-epel-please-verify-its-path-and-try-again/
# nano /etc/yum.repos.d/epel.repo

# initialisasi var
export CENTOS_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

#detail nama perusahaan
country=ID
state=Banten
locality=Serang
organization=www.portalssh.com
organizationalunit=www.portalssh.com
commonname=www.portalssh.com
email=admin@portalssh.com

# disable se linux
echo 0 > /selinux/enforce
sed -i 's/SELINUX=enforcing/SELINUX=disable/g'  /etc/sysconfig/selinux

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service sshd restart

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.d/rc.local

# install wget and curl
yum -y install wget curl

# setting repo centos 64bit
wget https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh epel-release-6-8.noarch.rpm

# setting rpmforge
wget http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

sed -i 's/enabled = 1/enabled = 0/g' /etc/yum.repos.d/rpmforge.repo
sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
rm -f *.rpm

# remove unused
yum -y remove sendmail;
yum -y remove httpd;
yum -y remove cyrus-sasl

# update
yum -y update

# install webserver
yum -y install nginx php-fpm php-cli
service nginx restart
service php-fpm restart
chkconfig nginx on
chkconfig php-fpm on

# install essential package
yum -y install rrdtool screen iftop htop nmap bc nethogs openvpn vnstat ngrep mtr git zsh mrtg unrar rsyslog rkhunter mrtg net-snmp net-snmp-utils expect nano bind-utils
yum -y groupinstall 'Development Tools'
yum -y install cmake
yum -y --enablerepo=rpmforge install axel sslh ptunnel unrar

# install webserver
cd
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/nginx.conf"
sed -i 's/www-data/nginx/g' /etc/nginx/nginx.conf
mkdir -p /home/vps/public_html
echo "<pre>admin@white-vps</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
rm /etc/nginx/conf.d/*
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/vps.conf"
sed -i 's/apache/nginx/g' /etc/php-fpm.d/www.conf
chmod -R +rx /home/vps
service php-fpm restart
service nginx restart

# install mrtg
cd /etc/snmp/
wget -O /etc/snmp/snmpd.conf "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/snmpd.conf"
wget -O /root/mrtg-mem.sh "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
service snmpd restart
chkconfig snmpd on
snmpwalk -v 1 -c public localhost | tail
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg/mrtg.cfg public@localhost
curl "https://raw.githubusercontent.com/whitevps2/portalssh/master/conf/mrtg.conf" >> /etc/mrtg/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg/mrtg.cfg
echo "0-59/5 * * * * root env LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg" > /etc/cron.d/mrtg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg

# setting port ssh
cd
wget -O /etc/bannerssh.txt "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/banner.conf"
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port  22/g' /etc/ssh/sshd_config

# set sshd banner
wget -O /etc/ssh/sshd_config "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/sshd.conf"
service sshd restart
chkconfig sshd on

# install dropbear
yum -y install dropbear
echo "OPTIONS=\"-b /etc/bannerssh.txt -p 109 -p 110 -p 456\"" > /etc/sysconfig/dropbear
echo "/bin/false" >> /etc/shells

# limite login dropbear 
service dropbear restart
chkconfig dropbear on
service iptables save
service iptables restart
chkconfig iptables on

# install vnstat gui
cd /home/vps/public_html/
wget https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php

# install fail2ban
cd
yum -y install fail2ban
service fail2ban restart
chkconfig fail2ban on

# install webmin
cd
wget --no-check-certificate http://prdownloads.sourceforge.net/webadmin/webmin-1.831-1.noarch.rpm
yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty
rpm -U webmin*
rm -f webmin*
sed -i -e 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart
chkconfig webmin on

# pasang bmon
wget -O /usr/bin/bmon "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/bmon64"
chmod +x /usr/bin/bmon

# Install stunnel centos6
yum -y install stunnel

cat > /etc/stunnel/stunnel.conf <<-END
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[dropbear]
connect = 127.0.0.1:22
accept = 443
END

cd

# membuat sertifikat
cd /usr/bin
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem
cd

# Pasang Config Stunnel centos
cd /usr/bin
wget -O /etc/rc.d/init.d/stunnel "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/ssl.conf"
chmod +x /etc/rc.d/init.d/stunnel
service stunnel start
chkconfig stunnel on
cd

# install badvpn centos
yum -y install update
yum -y install wget
yum -y install unzip
yum -y install git
yum -y install make
yum -y install cmake
yum -y install gcc
yum -y install screen

# buat directory badvpn
mkdir badvpn-build
cd badvpn-build
wget https://github.com/idtunnel/sshtunnel/raw/master/centos/openvpn/badvpn-update.zip
unzip badvpn-update
cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
rm badvpn-update.zip

# aut start badvpn
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/null &' /etc/rc.local
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/null &
cd
cd badvpn-build

sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 > /dev/null &' /etc/rc.local
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 > /dev/null &
cd

# Sett iptables badvpn
iptables -A INPUT -i eth0 -m state --state NEW -p tcp --dport 7300 -j ACCEPT
iptables -A INPUT -i eth0 -m state --state NEW -p tcp --dport 7200 -j ACCEPT
service iptables save

# Save & restore IPTABLES Centos 6 64bit
wget -O /etc/iptables.up.rules "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.d/rc.local
MYIP=`curl icanhazip.com`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
sed -i $MYIP2 /etc/iptables.up.rules;
sed -i 's/venet0/eth0/g' /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
sysctl -w net.ipv4.ip_forward=1
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
cp /etc/sysconfig/iptables /etc/iptables.up.rules
chmod +x /etc/iptables.up.rules
chkconfig openvpn on
service iptables restart
service openvpn restart
cd

# permition rc local
chmod +x /etc/rc.local
chmod +x /etc/rc.d/rc.local


# Akun SSH dan VPN Lifetime
PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1`;
useradd -M -s /bin/false dayatdacung
echo "dayatdacung:$PASS" | chpasswd
echo "dayatdacung" > pass.txt
echo "$PASS" >> pass.txt

##security limite login 
#wget -O /etc/security/limits.conf "https://github.com/idtunnel/sshtunnel/master/centos/limits.conf"
#chmod +x /etc/security/limits.conf

## limite login
#iptables -A INPUT -p tcp --syn --dport 22 -m connlimit --connlimit-above 2 -j REJECT
#iptables -A INPUT -p tcp --syn --dport 143 -m connlimit --connlimit-above 2 -j REJECT
#iptables -A INPUT -p tcp --syn --dport 109 -m connlimit --connlimit-above 2 -j REJECT
#iptables -A INPUT -p tcp --syn --dport 110 -m connlimit --connlimit-above 2 -j REJECT
#iptables -A INPUT -p tcp --syn --dport 456 -m connlimit --connlimit-above 2 -j REJECT
#iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 2 -j REJECT
#service iptables save
#service iptables restart
#chkconfig iptables on

# downlaod script
cd /usr/bin
wget -O speedtest "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/speedtest_cli.py"
wget -O bench "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/bench-network.sh"
wget -O mem "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/ps_mem.py"
wget -O loginuser "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/login.sh"
wget -O userlogin "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/user-login.sh"
wget -O userexpire "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/autoexpire.sh"
wget -O usernew "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/openvpn/create-user.sh"
wget -O renew "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/user-renew.sh"
wget -O userlist "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/user-list.sh" 
wget -O trial "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/openvpn/user-trial.sh"
wget -O jurus69 "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/restart.sh"
wget -O delete "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/centos/expired.sh"
echo "cat log-install.txt" | tee info

# sett permission
chmod +x userlogin
chmod +x loginuser
chmod +x userexpire
chmod +x usernew
chmod +x renew
chmod +x userlist
chmod +x trial
chmod +x jurus69
chmod +x info
chmod +x speedtest
chmod +x bench
chmod +x mem
chmod +x delete

# cron
cd
service crond start
chkconfig crond on
service crond stop

# crontab command option
# export VISUAL=nano; crontab -e
cat > /etc/crontab <<-END
0 */6 * * * root /usr/bin/userexpire
0 */6 * * * root /usr/bin/jurus69
0 */6 * * * root /usr/bin/delete
END
cd 
chmod +x /etc/crontab
crontab -l

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# finalisasi
chown -R nginx:nginx /home/vps/public_html
/etc/init.d/nginx restart
/etc/init.d/php-fpm restart
/etc/init.d/vnstat restart
/etc/init.d/snmpd restart
/etc/init.d/sshd restart
/etc/init.d/dropbear restart
/etc/init.d/stunnel restart
/etc/init.d/squid restart
/etc/init.d/webmin restart
/etc/init.d/fail2ban restart
/etc/init.d/crond restart
chkconfig crond on

# info
echo "SSH Usage Information" | tee log-install.txt
echo "===============================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Activated Services"  | tee -a log-install.txt
echo "--------------------------------------"  | tee -a log-install.txt
echo "Client Config  : http://$MYIP:81/1194-client.ovpn)"  | tee -a log-install.txt
echo "Port OpenSSH   : 22, 143"  | tee -a log-install.txt
echo "Port Dropbear  : 109, 110, 80"  | tee -a log-install.txt
echo "Squid          : 8080, 3128 (limit to IP SSH)"  | tee -a log-install.txt
echo "badvpn         : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "Webmin         : http://$MYIP:10000/"  | tee -a log-install.txt
echo "vnstat         : http://$MYIP:81/vnstat/"  | tee -a log-install.txt
echo "MRTG           : http://$MYIP:81/mrtg/"  | tee -a log-install.txt
echo "Timezone       : Asia/Jakarta"  | tee -a log-install.txt
echo "Fail2Ban       : [on]"  | tee -a log-install.txt
echo "IPv6           : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt

echo "Tools"  | tee -a log-install.txt
echo "-----"  | tee -a log-install.txt
echo "axel"  | tee -a log-install.txt
echo "bmon"  | tee -a log-install.txt
echo "htop"  | tee -a log-install.txt
echo "iftop"  | tee -a log-install.txt
echo "mtr"  | tee -a log-install.txt
echo "nethogs"  | tee -a log-install.txt
echo "" | tee -a log-install.txt

echo "Default Account (For SSH and VPN)"  | tee -a log-install.txt
echo "---------------"  | tee -a log-install.txt
echo "User     : white-vps"  | tee -a log-install.txt
echo "Password : $PASS"  | tee -a log-install.txt
echo "" | tee -a log-install.txt

echo "Script"  | tee -a log-install.txt
echo "------"  | tee -a log-install.txt
echo "speedtest : to check vps speed" | tee -a log-install.txt
echo "mem : to see ram usage" | tee -a log-install.txt
echo "bench : to see vps performance" | tee -a log-install.txt
echo "userlogin : to see currently logged in users" | tee -a log-install.txt
echo "loginuser : to see currently logged in user" | tee -a log-install.txt
echo "trial : to create a trial account for 1 day" | tee -a log-install.txt
echo "usernew : to create a new account" | tee -a log-install.txt
echo "userexpire : to check user expired" | tee -a log-install.txt
echo "renew : to extend the active period of the account" | tee -a log-install.txt
echo "userlist : to see a list of accounts and their active period" | tee -a log-install.txt
echo "jurus69 : to reboot the vps service" | tee -a log-install.txt
echo "delete : to Delete All Expired Users" | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt


echo ""  | tee -a log-install.txt
echo "==============================================="  | tee -a log-install.txt

# installasi openvpn centos 6 64bit
wget https://github.com/idtunnel/sshtunnel/raw/master/centos/openvpn/centos.sh && chmod +x centos.sh && ./centos.sh

# delete bash script installer
rm -f /root/ssh-vpn.sh
rm -f /root/centos.sh

# finihsing
clear
neofetch
netstat -ntlp
