#!/bin/bash
#this will only work on debian-based systems
#made by Zachucks for linux web server deployment

#warning message that script has updated
echo "WARNING!!! This script has been updated, please pay attention to the prompts!" && read continueq

#ask if the user wants to update packages before continuing
echo "Would you like to check for package updates? (y/n):" && read packageUpdates
if [ $packageUpdates = "y" ]; then
	#update the system
	echo "Checking for latest updates..."
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt update -y
fi

#ask if the user wants to install commonly used programs
echo "Would you like to install commonly used packages (openssh-server mc tree lynx nmap)? (y/n):" && read installPackages
if [ $installPackages = "y" ]; then
	#install commonly used programs
	echo "Installing commonly used programs..."
	sudo apt install openssh-server mc tree lynx nmap -y
fi

#ask if the user wants to install xrdp for remote desktop
echo "Install XRDP for remote desktop? (y/n):" && read installXRDP
if [ $installXRDP = "y" ]; then
	sudo apt install xrdp -y
fi

#ask if the user wants to install the LAMP stack
echo "Install LAMP Stack? (y/n):" && read lampstack
if [ $lampstack = "y" ]; then
	echo "Username: " && read linuxUsername
	echo "Password: " && read -s linuxPassword
	#install lamp stack
	sudo apt install apache2 -y
	sudo chown -R $linuxUsername:www-data /var/www/html/
	sudo chmod -R 770 /var/www/html/
	sudo apt install php php-mbstring -y
	sudo rm /var/www/html/index.html
	sudo echo "<?php phpinfo ();?>" > /var/www/html/index.php
	sudo apt install mysql-server php-mysql -y
	echo "DROP USER 'root'@'localhost';" > lamptmp.sql
	echo "CREATE USER 'root'@'localhost' IDENTIFIED BY '"$linuxPassword"';" >> lamptmp.sql
	echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';" >> lamptmp.sql
	sudo mysql --user=root < lamptmp.sql
	rm lamptmp.sql
	sudo apt install phpmyadmin -y
	sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
fi

#ask if the user wants to install the wordpress instance manager
echo "Install the Wordpress Instance Manager on this web server?"
echo "!!!WARNING!!! THIS WILL OVERWRITE YOUR CURRENT WEB SERVER MAIN DIRECTORY !!!WARNING!!!"
echo "This requires that the previous step to this one has been completed (LAMP stack installation)"
echo "(y/n):" && read installWPIM
if [ $installWPIM = "y" ]; then
	cd /var/www/html
	rm -rf index.php
	wget http://aspintech.ca/wip/wpi_manager.tar.gz
	tar -xf wpi_manager.tar.gz
	rm -rf wpi_manager.tar.gz
	chmod 0777 wpis
	nano config.php
fi

#ask if the user wants to update motd and host information
echo "Update hostname & hosts file, remove default motd and update motd?" && read hoststuff
if [ $hoststuff = "y" ]; then
	sudo chmod -x /etc/update-motd.d/*
	sudo nano /etc/motd
	sudo nano /etc/hostname
	sudo nano /etc/hosts
fi

#ask if the user wants to join the server to active directory
echo "Join this server to Active Directory? (y/n):" && read adjoin
if [ $adjoin = "y" ]; then
	echo "Domain: " && read domain
	echo "Domain Admin Username: " && read domainadminusername
	#install lamp stack
	sudo systemctl disable systemd-resolved
	sudo systemctl stop systemd-resolved
	sudo unlink /etc/resolv.conf
	sudo nano /etc/resolv.conf
	sudo apt -y install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit
	sudo realm discover $domain
	sudo realm join -U $domainadminusername $domain
	realm list
	sudo nano /etc/sudoers.d/domain_admins
	sudo pam-auth-update
	sudo systemctl restart sssd
fi

#ask if the user wants to install and setup file shares with samba
echo "Setup SAMBA for network file sharing?" && read sambaq
if [ $sambaq = "y" ]; then
	echo "Username: " && read username
	sudo apt install samba -y
	sudo smbpasswd -a $username
	echo "Add the following info to the file you are about to edit (at the bottom):"
	echo "[FILESHARENAME]"
	echo "path = /path/to/share"
	echo "available = yes"
	echo "valid users = "$username
	echo "read only = no"
	echo "browsable = yes"
	echo "public = yes"
	echo "writable = yes"
	echo "Press [enter] to edit the file when ready..." && read readyq
	sudo nano /etc/samba/smb.conf
	sudo service smbd restart
fi

#ask if the user wants to reboot the server
echo "Reboot server?" && read rebootq
if [ $rebootq = "y" ]; then
	sudo reboot 0
fi

