# FROM debian:stretch
FROM php:5.6-apache

LABEL authors="Hannes Papenberg"

# Install
RUN rm /etc/apt/preferences.d/no-debian-php
RUN apt-get update
RUN DEBIAN_FRONTEND='noninteractive' apt install -y ca-certificates apt-transport-https wget gnupg2 \
   && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
   && echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list
RUN apt-get update
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y git php5.6 php5.6-cli php5.6-memcache php5.6-memcached php5.6-xdebug \
	  curl php5.6-gd php5.6-mcrypt php5.6-mysql php5.6-pgsql php5.6-sqlite
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y mysql-client postgresql-client
RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /etc/php/5.6/cli/php.ini
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
   && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e5325b19b381bfd88ce90a5ddb7823406b2a38cff6bb704b0acc289a09c8128d4a8ce2bbafcd1fcbdc38666422fe2806') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
   && php composer-setup.php \
   && php -r "unlink('composer-setup.php');" \
   && mv composer.phar /usr/local/bin/composer
RUN cd /usr/local/bin \
   && wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-4.8.35.phar \
   && chmod +x phpunit