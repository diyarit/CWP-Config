#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOSTNAME=$(hostname -f)
ver="$(rpm -E %{rhel})"

echo "########  #### ##    ##    ###    ########     #### ########"
echo "##     ##  ##   ##  ##    ## ##   ##     ##     ##     ##"    
echo "##     ##  ##    ####    ##   ##  ##     ##     ##     ##"   
echo "##     ##  ##     ##    ##     ## ########      ##     ##"   
echo "##     ##  ##     ##    ######### ##   ##       ##     ##"   
echo "##     ##  ##     ##    ##     ## ##    ##      ##     ##"   
echo "########  ####    ##    ##     ## ##     ##    ####    ##"   

echo ""
echo "       ####################### CentOS Web Panel Configurator #######################          "
echo ""
echo ""

if [ ! -f /etc/redhat-release ]; then
	echo "CentOS was not detected. Aborting"
	exit 0
fi

if [ $ver == 6 ]; then
	echo "CentOS installed is 6, it's not supported by CWP. Aborting"
	exit 0
fi

echo "This script installs and pre-configures CentOS Web Panel (CTRL + C to cancel)"
sleep 10

echo "####### CONFIGURING UP CENTOS #######"
if [ $ver == 7 ]; then
yum update yum -y
yum upgrade yum -y
yum update -y
yum upgrade -y
yum install firewalld wget net-tools ntpdate -y
echo "Setting server time..."
echo "Synchronizing date with pool.ntp.org..."
ntpdate 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org 0.south-america.pool.ntp.org
echo "Setting timezone to Asia/Baghdad..."
mv /etc/localtime /etc/localtime.old
ln -s /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
elif [ $ver == 8 ]; then
dnf makecache
dnf update -y
dnf upgrade -y
dnf install firewalld wget net-tools chrony -y
systemctl enable chronyd
fi
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=ntp
firewall-cmd --reload

wget https://raw.githubusercontent.com/diyarit/Centos-Config/master/configure_centos.sh -O "$CWD/configure_centos.sh" && bash "$CWD/configure_centos.sh"

echo "####### CWP PRE-CONFIGURATION ##########"
echo "Disabling yum-cron..."
yum erase yum-cron -y

echo "Removing Polkit..."
yum erase polkit -y

echo "######### CONFIGURING DNS AND NETWORK ########"
NETWORK=$(route -n | awk '$1 == "0.0.0.0" {print $8}')
ETHCFG="/etc/sysconfig/network-scripts/ifcfg-$NETWORK"

sed -i '/^NM_CONTROLLED=.*/d' $ETHCFG
sed -i '/^DNS1=.*/d' $ETHCFG
sed -i '/^DNS2=.*/d' $ETHCFG
	
echo "Configuring network..."
echo "PEERDNS=no" >> $ETHCFG
echo "DNS1=8.8.8.8" >> $ETHCFG
echo "DNS2=8.8.4.4" >> $ETHCFG

echo "Rewriting /etc/resolv.conf..."

echo "options timeout:5 attempts:2" > /etc/resolv.conf
echo "nameserver 208.67.222.222" >> /etc/resolv.conf # OpenDNS
echo "nameserver 8.20.247.20" >> /etc/resolv.conf # Comodo
echo "nameserver 8.8.8.8" >> /etc/resolv.conf # Google
echo "nameserver 199.85.126.10" >> /etc/resolv.conf # Norton
echo "nameserver 8.26.56.26" >> /etc/resolv.conf # Comodo
echo "nameserver 209.244.0.3" >> /etc/resolv.conf # Level3
echo "nameserver 8.8.4.4" >> /etc/resolv.conf # Google
echo "######### END CONFIGURING DNS AND NETWORK ########"

echo "####### INSTALLING CWP #######"
if [ -d /usr/local/cwpsrv/ ]; then
        echo "CWP already detected, it is not installed, it is only configured (CTRL + C to cancel)"
        sleep 10
else
	echo "CWP is going to be installed. At the end of the installation copy the access data that will show up to you. Then it will ask you to restart. After restarting, run this script again to finish the configuration."
	sleep 15
		cd /usr/local/src; wget http://centos-webpanel.com/cwp-el$ver-latest; sh cwp-el$ver-latest
fix exit

fi
echo "####### END INSTALLING CWP #######"

echo "####### CONFIGURING CSF #######"
if [ ! -d /etc/csf ]; then
        echo "csf not detected, downloading it now!"
	touch /etc/sysconfig/iptables
	touch /etc/sysconfig/iptables6
	systemctl start iptables
	systemctl start ip6tables
	systemctl enable iptables
	systemctl enable ip6tables
	cd /root && rm -f ./csf.tgz; wget https://download.configserver.com/csf.tgz && tar xvfz ./csf.tgz && cd ./csf && sh ./install.sh
fi

echo " CONFIGURING CSF..."
yum -y install iptables-services perl unzip perl-libwww-perl perl-LWP-Protocol-https perl-GDGraph

sed -i 's/^TESTING = .*/TESTING = "0"/g' /etc/csf/csf.conf
sed -i 's/^ICMP_IN = .*/ICMP_IN = "0"/g' /etc/csf/csf.conf
sed -i 's/^IPV6 = .*/IPV6 = "0"/g' /etc/csf/csf.conf
sed -i 's/^DENY_IP_LIMIT = .*/DENY_IP_LIMIT = "400"/g' /etc/csf/csf.conf
sed -i 's/^SAFECHAINUPDATE = .*/SAFECHAINUPDATE = "1"/g' /etc/csf/csf.conf
sed -i 's/^CC_DENY = .*/CC_DENY = ""/g' /etc/csf/csf.conf
sed -i 's/^CC_IGNORE = .*/CC_IGNORE = ""/g' /etc/csf/csf.conf
sed -i 's/^SMTP_BLOCK = .*/SMTP_BLOCK = "1"/g' /etc/csf/csf.conf # DIFFICULT BACK CONFIGURATION
sed -i 's/^SMTP_ALLOWGROUP = .*/SMTP_ALLOWGROUP = "mail,mailman,postfix"/g' /etc/csf/csf.conf

sed -i 's/^LF_FTPD = .*/LF_FTPD = "30"/g' /etc/csf/csf.conf
sed -i 's/^LF_SMTPAUTH = .*/LF_SMTPAUTH = "90"/g' /etc/csf/csf.conf
sed -i 's/^LF_EXIMSYNTAX = .*/LF_EXIMSYNTAX = "0"/g' /etc/csf/csf.conf
sed -i 's/^LF_POP3D = .*/LF_POP3D = "100"/g' /etc/csf/csf.conf
sed -i 's/^LF_IMAPD = .*/LF_IMAPD = "100"/g' /etc/csf/csf.conf
sed -i 's/^LF_HTACCESS = .*/LF_HTACCESS = "40"/g' /etc/csf/csf.conf
sed -i 's/^LF_CPANEL = .*/LF_CPANEL = "40"/g' /etc/csf/csf.conf
sed -i 's/^LF_MODSEC = .*/LF_MODSEC = "100"/g' /etc/csf/csf.conf
sed -i 's/^LF_CXS = .*/LF_CXS = "10"/g' /etc/csf/csf.conf
sed -i 's/^LT_POP3D =  .*/LT_POP3D = "180"/g' /etc/csf/csf.conf
sed -i 's/^CT_SKIP_TIME_WAIT = .*/CT_SKIP_TIME_WAIT = "1"/g' /etc/csf/csf.conf
sed -i 's/^PT_LIMIT = .*/PT_LIMIT = "0"/g' /etc/csf/csf.conf
sed -i 's/^ST_MYSQL = .*/ST_MYSQL = "1"/g' /etc/csf/csf.conf
sed -i 's/^ST_APACHE = .*/ST_APACHE = "1"/g' /etc/csf/csf.conf
sed -i 's/^CONNLIMIT = .*/CONNLIMIT = "80;70,110;50,993;50,143;50,25;30"/g' /etc/csf/csf.conf
sed -i 's/^LF_PERMBLOCK_INTERVAL = .*/LF_PERMBLOCK_INTERVAL = "14400"/g' /etc/csf/csf.conf
sed -i 's/^LF_INTERVAL = .*/LF_INTERVAL = "900"/g' /etc/csf/csf.conf
sed -i 's/^PS_INTERVAL = .*/PS_INTERVAL = "60"/g' /etc/csf/csf.conf
sed -i 's/^PS_LIMIT = .*/PS_LIMIT = "20"/g' /etc/csf/csf.conf

echo "Disabling alerts..."

sed -i 's/^LF_PERMBLOCK_ALERT = .*/LF_PERMBLOCK_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^LF_NETBLOCK_ALERT = .*/LF_NETBLOCK_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^LF_EMAIL_ALERT = .*/LF_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^LF_CPANEL_ALERT = .*/LF_CPANEL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^LF_QUEUE_ALERT = .*/LF_QUEUE_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^LF_DISTFTP_ALERT = .*/LF_DISTFTP_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^LF_DISTSMTP_ALERT = .*/LF_DISTSMTP_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^LT_EMAIL_ALERT = .*/LT_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^RT_RELAY_ALERT = .*/RT_RELAY_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^RT_AUTHRELAY_ALERT = .*/RT_AUTHRELAY_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^RT_POPRELAY_ALERT = .*/RT_POPRELAY_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^RT_LOCALRELAY_ALERT = .*/RT_LOCALRELAY_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^RT_LOCALHOSTRELAY_ALERT = .*/RT_LOCALHOSTRELAY_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^CT_EMAIL_ALERT = .*/CT_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^PT_USERKILL_ALERT = .*/PT_USERKILL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^PS_EMAIL_ALERT = .*/PS_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/^PT_USERMEM = .*/PT_USERMEM = "0"/g' /etc/csf/csf.conf
sed -i 's/^PT_USERTIME = .*/PT_USERTIME = "0"/g' /etc/csf/csf.conf
sed -i 's/^PT_USERPROC = .*/PT_USERPROC = "0"/g' /etc/csf/csf.conf
sed -i 's/^PT_USERRSS = .*/PT_USERRSS = "0"/g' /etc/csf/csf.conf

echo "Enabling blacklists..."
sed -i '/^#SPAMDROP/s/^#//' /etc/csf/csf.blocklists
sed -i '/^#SPAMEDROP/s/^#//' /etc/csf/csf.blocklists
sed -i '/^#DSHIELD/s/^#//' /etc/csf/csf.blocklists
sed -i '/^#HONEYPOT/s/^#//' /etc/csf/csf.blocklists
#sed -i '/^#MAXMIND/s/^#//' /etc/csf/csf.blocklists #FALSE POSITIVES
sed -i '/^#BDE|/s/^#//' /etc/csf/csf.blocklists

sed -i '/^SPAMDROP/s/|0|/|300|/' /etc/csf/csf.blocklists
sed -i '/^SPAMEDROP/s/|0|/|300|/' /etc/csf/csf.blocklists
sed -i '/^DSHIELD/s/|0|/|300|/' /etc/csf/csf.blocklists
sed -i '/^HONEYPOT/s/|0|/|300|/' /etc/csf/csf.blocklists
#sed -i '/^MAXMIND/s/|0|/|300|/' /etc/csf/csf.blocklists #FALSE POSITIVES
sed -i '/^BDE|/s/|0|/|300|/' /etc/csf/csf.blocklists

sed -i '/^TOR/s/^TOR/#TOR/' /etc/csf/csf.blocklists
sed -i '/^ALTTOR/s/^ALTTOR/#ALTTOR/' /etc/csf/csf.blocklists
sed -i '/^CIARMY/s/^CIARMY/#CIARMY/' /etc/csf/csf.blocklists
sed -i '/^BFB/s/^BFB/#BFB/' /etc/csf/csf.blocklists
sed -i '/^OPENBL/s/^OPENBL/#OPENBL/' /etc/csf/csf.blocklists
sed -i '/^BDEALL/s/^BDEALL/#BDEALL/' /etc/csf/csf.blocklists
	
cat > /etc/csf/csf.rignore << EOF
.cpanel.net
.googlebot.com
.crawl.yahoo.net
.search.msn.com
EOF

echo "Activating DYNDNS..."
sed -i 's/^DYNDNS = .*/DYNDNS = "300"/' /etc/csf/csf.conf
sed -i 's/^DYNDNS_IGNORE = .*/DYNDNS_IGNORE = "1"/' /etc/csf/csf.conf

echo "Adding csf.dyndns..."
sed -i '/gmail.com/d' /etc/csf/csf.dyndns
sed -i '/public.pyzor.org/d' /etc/csf/csf.dyndns
echo "tcp|out|d=25|d=smtp.gmail.com" >> /etc/csf/csf.dyndns
echo "tcp|out|d=465|d=smtp.gmail.com" >> /etc/csf/csf.dyndns
echo "tcp|out|d=587|d=smtp.gmail.com" >> /etc/csf/csf.dyndns
echo "tcp|out|d=995|d=imap.gmail.com" >> /etc/csf/csf.dyndns
echo "tcp|out|d=993|d=imap.gmail.com" >> /etc/csf/csf.dyndns
echo "tcp|out|d=143|d=imap.gmail.com" >> /etc/csf/csf.dyndns
echo "udp|out|d=24441|d=public.pyzor.org" >> /etc/csf/csf.dyndns

echo "Activating IPV6 support..."
sed -i 's/^IPV6 = .*/IPV6 = "1"/' /etc/csf/csf.conf
TCP_IN=$(grep "^TCP_IN = " /etc/csf/csf.conf | awk '{ print $3 }')
TCP_OUT=$(grep "^TCP_OUT = " /etc/csf/csf.conf | awk '{ print $3 }')
UDP_IN=$(grep "^UDP_IN = " /etc/csf/csf.conf | awk '{ print $3 }')
UDP_OUT=$(grep "^UDP_OUT = " /etc/csf/csf.conf | awk '{ print $3 }')

sed -i "s/^TCP6_IN = .*/TCP6_IN = $TCP_IN/" /etc/csf/csf.conf
sed -i "s/^TCP6_OUT = .*/TCP6_OUT = $TCP_OUT/" /etc/csf/csf.conf
sed -i "s/^UDP6_IN = .*/UDP6_IN = $UDP_IN/" /etc/csf/csf.conf
sed -i "s/^UDP6_OUT = .*/UDP6_OUT = $UDP_OUT/" /etc/csf/csf.conf

echo "Configuring additional ports..."
ADDITIONAL_PORTS="25,465,587"
# IPv4
CURR_CSF_IN=$(grep "^TCP_IN" /etc/csf/csf.conf | cut -d'=' -f2 | sed 's/\ //g' | sed 's/\"//g' | sed "s/,$ADDITIONAL_PORTS,/,/g" | sed "s/,$ADDITIONAL_PORTS//g" | sed "s/$ADDITIONAL_PORTS,//g" | sed "s/,,//g")
sed -i "s/^TCP_IN.*/TCP_IN = \"$CURR_CSF_IN,$ADDITIONAL_PORTS\"/" /etc/csf/csf.conf

CURR_CSF_OUT=$(grep "^TCP_OUT" /etc/csf/csf.conf | cut -d'=' -f2 | sed 's/\ //g' | sed 's/\"//g' | sed "s/,$ADDITIONAL_PORTS,/,/g" | sed "s/,$ADDITIONAL_PORTS//g" | sed "s/$ADDITIONAL_PORTS,//g" | sed "s/,,//g")
sed -i "s/^TCP_OUT.*/TCP_OUT = \"$CURR_CSF_OUT,$ADDITIONAL_PORTS\"/" /etc/csf/csf.conf

# IPv6
CURR_CSF_IN6=$(grep "^TCP6_IN" /etc/csf/csf.conf | cut -d'=' -f2 | sed 's/\ //g' | sed 's/\"//g' | sed "s/,$ADDITIONAL_PORTS,/,/g" | sed "s/,$ADDITIONAL_PORTS//g" | sed "s/$ADDITIONAL_PORTS,//g" | sed "s/,,//g")
sed -i "s/^TCP6_IN.*/TCP6_IN = \"$CURR_CSF_IN6,$ADDITIONAL_PORTS\"/" /etc/csf/csf.conf

CURR_CSF_OUT6=$(grep "^TCP6_OUT" /etc/csf/csf.conf | cut -d'=' -f2 | sed 's/\ //g' | sed 's/\"//g' | sed "s/,$ADDITIONAL_PORTS,/,/g" | sed "s/,$ADDITIONAL_PORTS//g" | sed "s/$ADDITIONAL_PORTS,//g" | sed "s/,,//g")
sed -i "s/^TCP6_OUT.*/TCP6_OUT = \"$CURR_CSF_OUT6,$ADDITIONAL_PORTS\"/" /etc/csf/csf.conf


echo "Disabling backups by default..."
mysql --defaults-file=/root/.my.cnf root_cwp -e "UPDATE backups SET backup_enable = 'off' WHERE id='1'"

# Activate CSF
/usr/sbin/csf -e
/usr/sbin/csf -r
service lfd restart
chkconfig csf on
chkconfig lfd on

echo "####### END CONFIGURING CSF #######"

echo "Setting PHP..."
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^memory_limit.*/memory_limit = 1024M/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^enable_dl.*/enable_dl = Off/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^expose_php.*/expose_php = Off/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^disable_functions.*/disable_functions = apache_get_modules,apache_get_version,apache_getenv,apache_note,apache_setenv,disk_free_space,diskfreespace,dl,highlight_file,ini_alter,ini_restore,openlog,show_source,symlink,eval,debug_zval_dump/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^upload_max_filesize.*/upload_max_filesize = 16M/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^post_max_size.*/post_max_size = 16M/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^date.timezone.*/date.timezone = "America\/Argentina\/Buenos_Aires"/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^allow_url_fopen.*/allow_url_fopen = On/g'

find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^max_execution_time.*/max_execution_time = 120/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^max_input_time.*/max_input_time = 120/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^max_input_vars.*/max_input_vars = 2000/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^;default_charset = "UTF-8"/default_charset = "UTF-8"/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^default_charset.*/default_charset = "UTF-8"/g'

find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^display_errors.*/display_errors = On/g'
find /usr/local/php/ -name "php.ini" | xargs sed -i 's/^error_reporting.*/error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT/g'

echo "Setting MySQL..."
sed -i '/^local-infile.*/d' /etc/my.cnf
sed -i '/^query_cache_type.*/d' /etc/my.cnf
sed -i '/^query_cache_size.*/d' /etc/my.cnf
sed -i '/^join_buffer_size.*/d' /etc/my.cnf
sed -i '/^tmp_table_size.*/d' /etc/my.cnf
sed -i '/^max_heap_table_size.*/d' /etc/my.cnf
sed -i '/^# WNPower pre-configured values.*/d' /etc/my.cnf

sed  -i '/\[mysqld\]/a\ ' /etc/my.cnf
sed  -i '/\[mysqld\]/a local-infile=0' /etc/my.cnf
sed  -i '/\[mysqld\]/a query_cache_type=1' /etc/my.cnf
sed  -i '/\[mysqld\]/a query_cache_size=12M' /etc/my.cnf
sed  -i '/\[mysqld\]/a join_buffer_size=12M' /etc/my.cnf
sed  -i '/\[mysqld\]/a tmp_table_size=192M' /etc/my.cnf
sed  -i '/\[mysqld\]/a max_heap_table_size=256M' /etc/my.cnf
sed  -i '/\[mysqld\]/a # WNPower pre-configured values' /etc/my.cnf

service mysql restart

echo "Setting up Postfix..."
sed -i '/^inet_protocols.*/d' /etc/postfix/main.cf
echo "inet_protocols = all" >> /etc/postfix/main.cf
service postfix restart

echo "Uninstalling ClamAV..."
service clamd stop && systemctl disable clamd
yum remove clamav* -y

history -c
echo "" > /root/.bash_history

echo "Finished!"
