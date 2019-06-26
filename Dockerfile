FROM ubuntu:16.04

LABEL authors="Yves Hoppe, Robert Deutz"

# Install
RUN apt-get update \
	&& DEBIAN_FRONTEND='noninteractive' apt-get install -y php  php-memcache php-memcached php-redis php-xdebug php-dom wget \
	  curl composer php-gd php-gettext php-mbstring php-mcrypt php-mysql php-phpseclib php7.0-sqlite3 mysql-client postgresql-client php-pgsql \
	  && sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /etc/php/7.0/cli/php.ini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && cd /usr/local/bin \
    && wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-4.8.35.phar \
    && chmod +x phpunit
