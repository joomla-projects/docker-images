FROM php:5.6-apache

LABEL authors="Hannes Papenberg"

RUN seq 1 8 | xargs -I{} mkdir -p /usr/share/man/man{}
RUN apt-get update
RUN apt-get install -y autoconf gcc git libbz2-dev libfreetype6-dev libmemcached-dev \
	libwebp-dev libjpeg-dev libpq-dev libldap2-dev libmcrypt-dev libpng-dev \
	libsqlite3-dev libssl-dev libxpm-dev mysql-client patch postgresql-client \
	unzip wget

RUN docker-php-ext-configure gd \
	--with-freetype-dir=/usr/lib/ \
	--with-png-dir=/usr/lib/ \
	--with-jpeg-dir=/usr/lib/ \
	--with-webp-dir=/usr/lib/ \
	--with-gd

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install bz2 exif ftp gd ldap mbstring mcrypt mysql mysqli opcache pdo_mysql pdo_pgsql pdo_sqlite pgsql zip

RUN pecl install memcached-2.2.0 \
	&& docker-php-ext-enable memcached

RUN pecl install redis-4.3.0 \
	&& docker-php-ext-enable redis

RUN pecl install apcu-4.0.11 \
	&& docker-php-ext-enable apcu \
	&& echo "\napc.enable=1\napc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-production \
	&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-development \
	&& cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
# We would love to check the signature of the installer, but since the signature changes very frequently, we can't really commit it to the repository
#	&& php -r "if (hash_file('sha384', 'composer-setup.php') === 'e5325b19b381bfd88ce90a5ddb7823406b2a38cff6bb704b0acc289a09c8128d4a8ce2bbafcd1fcbdc38666422fe2806') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" \
	&& mv composer.phar /usr/local/bin/composer
ENV COMPOSER_CACHE_DIR="/tmp/composer-cache"

RUN cd /usr/local/bin \
	&& wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-5.7.27.phar \
	&& chmod +x phpunit

RUN pecl install -n xdebug-2.5.5 \
	&& echo 'zend_extension='`find /usr -name xdebug.so`'\nxdebug.coverage_enable=on\n' > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
