FROM php:5.4-apache

LABEL authors="Hannes Papenberg"

# Install
RUN apt-get update 
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y git php5-cli php5-memcache php5-memcached php5-xdebug wget mysql-client postgresql-client \
	  curl php5-gd php5-mcrypt php5-mysql php5-pgsql php5-sqlite
RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /etc/php5/cli/php.ini \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && cd /usr/local/bin \
  && wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-4.8.35.phar \
  && chmod +x phpunit
