# Mattermost Installer

A bash script that automatically installs Mattermost Server

## Features
Proper README coming soon - in the meantime:

* Installs latest version of Mattermost server using MySQL
* Installs NGINX as a reverse proxy
* Configures a Let's Encrypt SSL certificate with an A+ SSL labs rating in NGINX
* Configures UFW as a firewall and opens ports for SSH, HTTP and HTTPS
* Installs and configures fail2ban for SSHD, NGINX and Mattermost


## Installation

Run as root - Tested on Ubuntu 16.04

    wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/mattermost-installer.sh && bash mattermost-installer.sh
or 

    curl -O https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/mattermost-installer.sh && bash mattermost-installer.sh

## Coming soon:

* Automatic updates for Matermost Server
* Backup of config file and database
* Basic MySQL hardening
* Installation without SSL
* Unatend updates for Ubuntu
* Automatic installation of giphy plugin
* Automatic installation of matterbridge
* Maybe some sort of monitoring?
