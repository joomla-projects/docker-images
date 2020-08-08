FROM php:5.5-apache

LABEL authors="Hannes Papenberg"

# Install
RUN apt-get update 
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y git php5-cli php5-memcache php5-memcached php5-xdebug wget mysql-client postgresql-client \
	  curl php5-gd php5-mcrypt php5-mysql php5-pgsql php5-sqlite phpunit
RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /etc/php5/cli/php.ini
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
   && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e5325b19b381bfd88ce90a5ddb7823406b2a38cff6bb704b0acc289a09c8128d4a8ce2bbafcd1fcbdc38666422fe2806') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
   && php composer-setup.php \
   && php -r "unlink('composer-setup.php');" \
   && mv composer.phar /usr/local/bin/composer
RUN cd /usr/local/bin \
   && wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-4.8.35.phar \
   && chmod +x phpunit
