FROM php:7.1-apache

LABEL authors="Hannes Papenberg"

RUN apt-get update
RUN apt-get install -y autoconf gcc wget zlib1g-dev unzip libpng-dev libfreetype6-dev \
	libmemcached-dev libwebp-dev libjpeg-dev libxpm-dev libpq-dev libldap2-dev

RUN docker-php-ext-configure gd \
	--with-freetype-dir=/usr/lib/ \
	--with-png-dir=/usr/lib/ \
	--with-jpeg-dir=/usr/lib/ \
	--with-gd

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install gd mysqli pdo_mysql pgsql pdo_pgsql zip ldap

RUN pecl install memcached \
	&& docker-php-ext-enable memcached

RUN pecl install redis \
	&& docker-php-ext-enable redis

RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-production \
	&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-development

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
# We would love to check the signature of the installer, but since the signature changes very frequently, we can't really commit it to the repository
#	&& php -r "if (hash_file('sha384', 'composer-setup.php') === 'e5325b19b381bfd88ce90a5ddb7823406b2a38cff6bb704b0acc289a09c8128d4a8ce2bbafcd1fcbdc38666422fe2806') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" \
	&& mv composer.phar /usr/local/bin/composer

RUN cd /usr/local/bin \
	&& wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-7.5.20.phar \
	&& chmod +x phpunit
