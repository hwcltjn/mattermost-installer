# Mattermost Installer

A bash script that automatically installs the latest version of Mattermost Server

## Features

* Installs the latest version of Mattermost server
* Installs either MariaDB (default) or Mysql and automatically creates a database 
* Installs and configures NGINX as a reverse proxy
* Configures a Let's Encrypt SSL certificate with an A+ SSL Labs rating (with automatic renewals!)
* Configures UFW as a firewall and opens ports for SSH, HTTP and HTTPS
* Installs and configures fail2ban for SSHD, NGINX and Mattermost
* Install and configures Unattended Upgrades for the OS

## Usage

This script is intended to be used on a _**FRESH**_ server with nothing else installed on it. It has been tested and confirmed to work with:
* Ubuntu 16 and 18
* Mattermost 5.1.0

Ensure to run the following commands as root:

    wget https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/mattermost-installer.sh && bash mattermost-installer.sh
or 

    curl -O https://raw.githubusercontent.com/hwcltjn/mattermost-installer/master/mattermost-installer.sh && bash mattermost-installer.sh

#### Settings

At the top of the script you can modify the following options:  
```configure_uu``` - to enable/disable configuration of Unattended Upgrades, default "true".  
```configure_fw``` - to enable/disable configuration of the firewall, default "true".  
```ssh_port``` - if you have setup a custom SSH port, the script will take this into consideration when setting up the firewall (it will not change your system's SSH port), default "true".  
```configure_f2b``` - to enable/disable installation and configuration of fail2ban, default "true".  
```db_engine``` - to select which database engine you'd like to use, options are "mariadb" (default) or "mysql".  

There are also options for you to manually set the database details you would like to use.

## Wish List/Coming Soon:

* Automatic updates for Matermost Server
* Muliplte instances of Mattermost per server
* Automatic backups of config file and database
* Database hardening
* Installation without SSL
* Automatic installation of giphy plugin
* Automatic installation of matterbridge
* Some sort of monitoring?

## Feedback / Commercial Support

Get in touch at info@hwclondon.com