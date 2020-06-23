#!/bin/bash
#Script by OrbitWeb
#Set default parameters

#has to be interective 
domain=dev.orbitweb.ca 
shortname=dev
rootDir="/var/www/html"
apacheUser=$(ps -ef | egrep '(httpd|apache2|apache)' | grep -v root | head -n1 | awk '{print $1}')
email='dev@orbitweb.ca'
sitesEnabled='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
userDir='/var/www/'
sitesAvailabledomain=$sitesAvailable$domain.conf
home_dir=$('pwd')
#kiosk_dir='/opt/kiosk'
php_ini=/etc/php/7.2/apache2/php.ini

#Update
echo "Updating APT"
apt update
apt upgrade -y

#Tools

#Glances
echo "Setting Up Server Monitoring - Glances"
apt install glances -y

#lnav
apt install lnav -y

#Apache
echo "Installing Apache"
apt install apache2 apache2-utils -y
systemctl enable apache2
systemctl start apache2

echo "installing Apache Modules"
apt install libapache2-mod.php -y
apt install php7.2-mysqlnd -y
cd /etc/php/7.2/apache2
apt install php7.2 -y
apt-get install php-soap -y
apt-get install php7.2-zip -y
apt-get install php-dom -y
apt-get install php7.2-mbstring -y
apt install php-curl -y
apt install php7.2-gmp -y
apt-get install php-gd -y
apt-get install php7.2-mysql -y
phpenmod pdo_mysql
a2enmod rewrite
service apache2 reload
service apache2 restart
cd $home_dir

echo "Customizing Apache Web Server"

#Create virtual host
echo "Creating Apache Virtual Host"
if ! echo "
<VirtualHost *:80>
	ServerAdmin $email
	DocumentRoot $rootDir
	ServerName $domain
	ErrorLog /var/log/apache2/error.log
        CustomLog /var/log/apache2/access.log combined
	#WordPress Permalinks - requires modrewrite  
	RewriteEngine on
        RewriteCond %{SERVER_NAME} =$shortname [OR]
        RewriteCond %{SERVER_NAME} =$shortname
        RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
<Directory />
        Options FollowSymLinks
        AllowOverride None
</Directory>

<Directory $rootDir>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all 
</Directory>
" > $sitesAvailabledomain
then
	echo -e $"There is an ERROR creating $domain file"
	exit;
else
	echo -e $"\nNew Virtual Host $domain Created\n"
fi

#Add domain in /etc/hosts
#echo "127.0.1.1 $domain" >> /etc/hosts

#PHP Tweaks
sed -i "s/max_execution_time = 30/max_execution_time = 1500/g" $php_ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 1024M/g" $php_ini
sed -i "s/post_max_size = 8M/post_max_size = 1024M/g" $php_ini
sed -i "s/memory_limit = 128M/memory_limit = 2048M/g" $php_ini

#WordPress
cd /var/www/
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
mv wordpress $shortname
#chown -R $apacheuser:$apacheuser $rootDir
#chmod -R 755 $rootDir
cd $home_dir

#Enable website
a2ensite $domain

#Disable default site
a2dissite 000-default.conf

#File Permissions
echo "Setting up file permissions"
chmod -R 755 $rootDir
chown -R www-data:www-data $rootDir


##########################Database########################
echo "Creating Database"
apt-get install mysql-client mysql-server -y

#run database script
#mysql --user=root --password -s < $kiosk_dir/assets/kiosk_database.sql > kioskdb.log

#echo 'cat kioskdb.log'

#apt install awscli -y
#cat $kiosk_dir/assets/credentials.txt
#aws configure

#$kiosk_dir/scripts/kiosk_webapp.sh

function pause() {
		    read -p "$*"
	    }
	echo Server will be restart
	pause 'Press [Enter] to continue...'

#Bounce
init 6

