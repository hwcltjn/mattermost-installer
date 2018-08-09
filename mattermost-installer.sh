#!/bin/bash

# Mattermost Server Installer 
# hwcltjn - info@hwclondon.com
# https://github.com/hwcltjn/mattermost-installer

############
# Settings #
############

# ---- Unattended-upgrades Settings ---- #
configure_uu="true"  # Set to false if you do not want this script to install and configure unattended-upgrades.

# ---- Firewall Settings ---- #
configure_fw="true"  # Set to false if you do not want this script to configure your firewall.
ssh_port="22"        # Change if you have setup a custom SSH port.

# ---- Fail2ban Settings ---- #
configure_f2b="true" # Set to false if you do not want to install and configure fail2ban.

# ---- Database Settings ---- #
db_engine="mariadb" # Set to "mariadb" or "mysql"
mm_dbname="mattermost"
mm_dbuser="mmuser"
mm_dbpass="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)" # Generate Random Password
# mm_dbpass="YourPassword"

##################################################
# End Settings - No need to edit below this line #
##################################################
# ---- Exit Code Checks ----#
exit_code_abort() {
  if [ "$?" != "0" ]; then
    echo "ERROR - $1"
    echo "Exiting"
    exit 1
  fi
}

# ---- Pre-Flight Checks ----#
# Check for root
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root. Exiting." 1>&2
   exit 1
fi

# Check for apt / Ubuntu / Debian
apt_check=$(command -v apt-get)
if [ -z "$apt_check" ]; then
  echo "ERROR: Only Debian based distro's are supported."
  echo "Exiting."
  exit 1
fi

# DB Engine
if [[ "$db_engine" != "mariadb" && "$db_engine" != "mysql" ]]; then
  echo "ERROR - db_engine can only be set to mariadb or mysql - please check and try again."
  echo "Exiting."
  exit 1
fi

# MySQL DB
if [ -z "$mm_dbname" ] || [ -z "$mm_dbpass" ] || [ -z "$mm_dbuser" ]; then
  echo "Error: MySQL database name, username, and/or password  missing. Exiting."
  exit 1
fi

# ---- Get Latest MM Version ---- ## 
mm_ver="$(wget -q -O - https://about.mattermost.com/download/|grep -m 1 'Latest Release: '|sed -r 's/^[^3-9]*([0-9.]*).*/\1/')"

# Mattermost
if [ -z "$mm_ver" ]; then
  echo "Error: Could not fetch latest version of Mattermost. Exiting."
  exit 1
fi

# ---- Get MatterMost domain ---- #
get_fqdn() {
  while [ -z "$mm_fqdn" ]; do
    echo ""
    echo "What is your Mattermost FQDN?"
    echo "This will be used to automatically configure NGINX and SSL. Example: mattermost.example.com"
    echo ""
    read mm_fqdn
    echo

    read -r -p "Mattermost domain will be set to: $mm_fqdn. Continue? [Y/N] " fqdnconfirm
    if [[ $fqdnconfirm =~ ^([nN][oO]|[nN])$ ]]
    then
      echo ""
      echo "Failed to set Mattermost domain"
      unset mm_fqdn
    fi
    echo ""
  done
}

# ---- Start Script ---- #
echo ""
echo "#######################################################################"
echo "   This script will install Mattermost Server"
echo "   This installer is intended to be run on a FRESH server"
echo ""
echo "   This script will:"
if [ "$db_engine" = "mariadb" ]; then
  echo "     * Install Mattermost with MariaDB"
elif [ "$db_engine" = "mysql" ]; then
  echo "     * Install Mattermost with MySQL"
fi
echo "     * Install NGINX as a reverse proxy"
echo "     * Configure an SSL certificate using Let's Encrypt"
if [ "$configure_fw" = "true" ]; then
  echo "     * Enable a firewall (UFW) and open ports SSH ($ssh_port), HTTP (80) and HTTPS (443)"
fi
if [ "$configure_f2b" = "true" ]; then
  echo "     * Install and configure fail2ban for SSHD, NGINX and MM"
fi
if [ "$configure_uu" = "true" ]; then
  echo "     * Install and configure Unattended Upgrades for Ubuntu"
fi
echo ""
echo ""
echo "   The latest version of Mattermost is: $mm_ver"
echo ""
echo "   Would you like to continue? [Y/N]"
echo "#######################################################################"
echo ""

read installconfirm
if [[ $installconfirm =~ ^([nN][oO]|[nN])$ ]]; then
  echo "Bye!"
  exit 0
fi

get_fqdn

echo "What e-mail address would you like associated with the Let's Encrypt SSL certiticate?"
echo "Example: mail@example.com. Press ENTER to NOT associate an e-mail address."
read le_email
echo ""

fqdn_ip=$(dig +short $mm_fqdn @8.8.8.8)
host_ip=$(curl -s https://checkip.amazonaws.com/)

if [ "$fqdn_ip" != "$host_ip" ]; then
  echo "Your host's public IP address does not resolve to your chosen FQDN's address"
  echo "FQDN IP: $fqdn_ip"
  echo "Host IP: $host_ip"
  echo "Exiting"
  exit 1
fi

# ---- Update OS and Install Stuff ---- #
apt-get update
  exit_code_abort "Could not update APT."

apt-get install software-properties-common -yy
  exit_code_abort "Could not install software-properties-common."

add-apt-repository ppa:certbot/certbot -yy
  exit_code_abort "Could not add Certbot repo."

apt-get update
  exit_code_abort "Could not update APT."

apt-get upgrade -yy
if [ "$?" != "0" ]; then
  echo "Error: Could not apt upgrade OS. Waiting 10 seconds."
  sleep 10
fi

if [ "$db_engine" = "mariadb" ]; then
  apt-get install mariadb-server nginx jq certbot -yy
    exit_code_abort "Could not install required packages."
elif [ "$db_engine" = "mysql" ]; then
  apt-get install mysql-server nginx jq certbot -yy
    exit_code_abort "Could not install required packages."
fi

# ---- Create MySQL Database and User ---- #
mysql -e "CREATE DATABASE ${mm_dbname};"
  exit_code_abort "Could not create MySQL database."
mysql -e "CREATE USER '${mm_dbuser}'@'localhost' IDENTIFIED BY '${mm_dbpass}';"
  exit_code_abort "Could not create MySQL user."
mysql -e "GRANT ALL PRIVILEGES ON ${mm_dbname}.* TO '${mm_dbuser}'@'localhost';"
  exit_code_abort "Could not grant privileges."

# ---- Download and Install Mattermost ---- #
wget -q https://releases.mattermost.com/$mm_ver/mattermost-$mm_ver-linux-amd64.tar.gz # Enterprise
tar -xzf mattermost-$mm_ver-linux-amd64.tar.gz # Enterprise
# wget -q https://releases.mattermost.com/$mm_ver/mattermost-team-$mm_ver-linux-amd64.tar.gz # Team
# tar -xzf mattermost-team-$mm_ver-linux-amd64.tar.gz # Team
  
  exit_code_abort "Could not extract Mattermost $mm_ver archive."

mv mattermost /opt
mkdir /opt/mattermost/data
useradd --system --user-group mattermost
wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/systemd/mattermost.service -O /lib/systemd/system/mattermost.service
systemctl daemon-reload
systemctl enable mattermost.service

mm_datasource="$mm_dbuser:$mm_dbpass@tcp(localhost:3306)/$mm_dbname?charset=utf8mb4,utf8&readTimeout=30s&writeTimeout=30s"
mm_siteurl="https://$mm_fqdn"

mv /opt/mattermost/config/config.json /opt/mattermost/config/config.json_example
cat /opt/mattermost/config/config.json_example | jq -r --arg dsource "$mm_datasource" --arg surl "$mm_siteurl" '.SqlSettings.DataSource=$dsource | .ServiceSettings.SiteURL=$surl | .LogSettings.EnableDiagnostics="false" | .SqlSettings.DriverName="mysql"' > /opt/mattermost/config/config.json

chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost

# ---- Configure NGINX + LE SSL ---- #
systemctl stop nginx
sleep 2

echo "Configuring Let's Encrypt SSL"

if [ -z "$le_email" ]; then
  /usr/bin/certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $mm_fqdn
else
  /usr/bin/certbot certonly --standalone --agree-tos --no-eff-email --email $le_email -d $mm_fqdn
fi

mkdir /etc/nginx/ssl/
openssl dhparam -dsaparam -out /etc/nginx/ssl/dhparam.pem 4096
sleep 2

wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/nginx/mattermost -O /etc/nginx/sites-available/mattermost

sed -i "s/mattermost.example.com/$mm_fqdn/" /etc/nginx/sites-available/mattermost

rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/mattermost /etc/nginx/sites-enabled/mattermost

# ---- Configure unattended-upgrades ---- #
if [ "$configure_uu" = "true" ]; then
  apt-get install unattended-upgrades -yy
  wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/unattended-upgrades/20auto-upgrades -O /etc/apt/apt.conf.d/20auto-upgrades -q
  wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/unattended-upgrades/50unattended-upgrades -O /etc/apt/apt.conf.d/50unattended-upgrades -q
fi

# ---- Configure fail2ban ---- #
if [ "$configure_f2b" = "true" ]; then
  apt-get install fail2ban -yy
  sleep 4
  systemctl stop fail2ban
  sleep 3
  wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/fail2ban/jail.local -O /etc/fail2ban/jail.local
  wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/fail2ban/filter_d/mattermost-passlockout.conf -O /etc/fail2ban/filter.d/mattermost-passlockout.conf
  wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/fail2ban/filter_d/nginx-dos.conf -O /etc/fail2ban/filter.d/nginx-dos.conf
  wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/fail2ban/filter_d/nginx-noscript.conf -O /etc/fail2ban/filter.d/nginx-noscript.conf
fi

# ---- Configure Firewall ---- #
if [ "$configure_fw" = "true" ]; then
  apt-get install ufw -yy
  ufw allow $ssh_port
  ufw allow http
  ufw allow https
  ufw --force enable
  sleep 2
fi

# ---- Start Services ---- #
systemctl start nginx
sleep 2
systemctl start mattermost
sleep 2

if [ "$configure_f2b" = "true" ]; then
  systemctl start fail2ban
  sleep 2
fi

# ---- Let's Encrypt Cron ---- #
touch /var/log/mattermost-ssl.log
wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/install/mattermost-ssl/mattermost-ssl.sh -O /usr/local/bin/mattermost-ssl.sh
chmod +x /usr/local/bin/mattermost-ssl.sh
sleep 2
(crontab -l ; echo "@monthly /usr/local/bin/mattermost-ssl.sh")| crontab -

# ---- Print Summary ---- #
echo ""
echo "-----------------------------------"
echo "  Installation complete!"
echo ""
echo "  Please go to https://$mm_fqdn to manage your Mattermost server"
echo ""
echo "-----------------------------------"
exit 0