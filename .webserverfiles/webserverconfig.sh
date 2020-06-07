#!/usr/bin/env bash

sudo add-apt-repository ppa:ondrej/php
sudo apt-get update

###Parameters for MySQL installation
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password vagrant"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password vagrant"

###Parameters for PHPMyAdmin installation
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"  
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"  
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-user string root"  
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password vagrant"  
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password vagrant"  
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password vagrant"

###Installing packages 
sudo apt-get -y -qq install apache2 mysql-server php7.3 php7.3-mysql php7.3-gd php7.3-xml php7.3-mbstring zip unzip php7.3-zip php7.3-curl php7.3-bcmath openssl phpmyadmin
sudo apt-get -y -qq install php-xdebug

###Setting PHP cli version to selected version
sudo update-alternatives --set php /usr/bin/php7.3

###generate SSL certificate for server
openssl req -x509 -out /etc/ssl/certs/localhost.crt -keyout /etc/ssl/private/localhost.key \
  -newkey rsa:2048 -nodes -sha256 \
  -subj '/CN=webserver.intranet' -extensions EXT -config <( \
   printf "[dn]\nCN=webserver.intranet\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:webserver.intranet\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

###Setting up webserver
sudo apt-get -y install apache2 mysql-server php7.3 php7.3-mysql php7.3-gd php7.3-xml php7.3-mcrypt php7.3-mbstring zip unzip php7.3-zip php7.3-curl
sudo cp /vagrant/.webserverfiles/000-default.conf /etc/apache2/sites-available/000-default.conf
sudo cp /vagrant/.webserverfiles/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
sudo cp /vagrant/.webserverfiles/php.ini /etc/php/7.3/apache2/php.ini
sudo cp /vagrant/.webserverfiles/xdebug.ini /etc/php/7.3/mods-available/xdebug.ini
sudo a2enmod rewrite
sudo a2enmod ssl
sudo a2ensite default-ssl

sudo apachectl restart


##Composer installation
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

###PHP Dependency installation
cd /vagrant
sudo composer --global config process-timeout 2000
sudo composer install
echo "alias drush='/vagrant/vendor/drush/drush/drush'" >> /home/vagrant/.bashrc
echo "alias drupal='/vagrant/vendor/drupal/console/bin/drupal'" >> /home/vagrant/.bashrc

#Append config directory to default settings
echo "\$settings['config_sync_directory'] = '../config';" >> /vagrant/web/sites/default/default.settings.php

#Set *.intranet as trusted host
echo "\$settings['trusted_host_patterns'] = ['^.+\.intranet$'];" >> /vagrant/web/sites/default/default.settings.php

###Install drupal and import configuration
./vendor/drush/drush/drush -y si minimal --db-url=mysql://root:vagrant@localhost/drupal --config-dir=/vagrant/config --account-pass=admin
./vendor/drush/drush/drush -y cr

###Run cron
./vendor/drush/drush/drush -y cron

###Info for using the server
echo "###Installation complete###"
echo "The server has been created and drupal has been installed"
echo "if you had config files in de config directory those have been imported"
echo "To open the site go to http://webserver.intranet or http://192.168.33.10"
echo "PhpMyAdmin is available on /phpmyadmin"
echo "HTTPS connection is also available but the server is using a self-signed certificate so you will get warnings"
echo "to log into the server use the 'vagrant ssh' command"