#!/bin/bash

# Let's Encrypt Renewal Script for Mattermost Server Installer
# hwcltjn - info@hwclondon.com
# https://github.com/hwcltjn/mattermost-installer

log="/var/log/mattermost-ssl.log"
nginx_status="$(systemctl is-active nginx)"

timestamp() {
	date '+%Y-%m-%d %H:%M:%S'
}

if [ "$nginx_status" == "active" ]; then
	service nginx stop	
	if [ "$?" = "0" ]; then
  		echo "$(timestamp) - Info: NGINX service has been stopped." >> "$log"
  		echo "$(timestamp) - Info: NGINX service has been stopped."
	else
		echo "$(timestamp) - Error: Could not stop NGINX. Exiting." >> "$log"
  		exit 1
	fi
	
	sleep 3
fi
	
/usr/bin/certbot renew --dry-run
sleep 3

service nginx start

if [ "$?" = "0" ]; then
	echo "$(timestamp) - Info: NGINX service has been started." >> "$log"
else
	echo "$(timestamp) - Error: Could not start NGINX. Exiting." >> "$log"
	exit 1
fi

exit 0