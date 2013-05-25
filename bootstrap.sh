#!/usr/bin/env bash
# Update the box, and insall all the necessary packages to support Laravel
apt-get -qq update
DEBIAN_FRONTEND=noninteractive apt-get install -qq -y libapache2-mod-php5 mysql-server php5-cli php5-mysql php5-mcrypt php5-curl php-pear curl git sqlite php5-sqlite php5-memcache php5-memcache php5-gd php-apc


# Install PHPUnit
pear upgrade-all
pear config-set auto_discover 1
pear install -f --alldeps pear.phpunit.de/PHPUnit


# Setup hosts file
VHOST=$(cat <<EOF
ServerName localhost

<VirtualHost *> 
    DocumentRoot "/vagrant/public"
    ServerName pensum.dev
    <Directory /vagrant/public>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-enabled/000-default

# Enable mod_rewrite
sudo a2enmod rewrite

# Restart Apache
sudo service apache2 restart

# Remove the Apache default /var/www directory and symlink instead to /vendor
rm -fr /var/www
ln -s /vagrant /var/www


# Make some laravel directories writable
chmod --recursive a+rw /var/www/public/packages
chmod --recursive a+rw /var/www/app/config/packages
chmod --recursive a+rw /var/www/app/storage


# Install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer.phar

cd /var/www
composer.phar install --dev


# Set up a dataase for your project
echo "CREATE DATABASE IF NOT EXISTS pensum" | mysql
echo "GRANT ALL PRIVILEGES ON pensum.* TO 'root'@'localhost' IDENTIFIED BY 'm4kealist'" | mysql

# Run artisan migrate to setup the database and schema, then seed it
php artisan migrate --env=development
php artisan db:seed --env=development