FROM phpdaily/php:8.0.0-dev-apache-buster

LABEL authors="Hannes Papenberg"

RUN apt-get update
RUN apt-get install -y autoconf gcc git wget libbz2-dev unzip libpng-dev libfreetype6-dev libonig-dev\
	libmemcached-dev libwebp-dev libjpeg-dev libxpm-dev libpq-dev libldap2-dev libsqlite3-dev \
	libssl-dev libzip-dev mysql-client postgresql-client patch

RUN docker-php-ext-configure gd \
	--with-freetype \
	--with-jpeg \
	--with-webp \
	--enable-gd

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install bz2 ftp gd exif mysqli pdo_mysql pgsql pdo_pgsql pdo_sqlite zip ldap mbstring ftp opcache

RUN pecl install memcached \
	&& docker-php-ext-enable memcached

# Unfortunately redis doesn't work yet in PHP8.0
# RUN pecl install redis \
#	&& docker-php-ext-enable redis

RUN pecl install apcu \
	&& docker-php-ext-enable apcu

RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-production \
	&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-development

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
# We would love to check the signature of the installer, but since the signature changes very frequently, we can't really commit it to the repository
#	&& php -r "if (hash_file('sha384', 'composer-setup.php') === 'e5325b19b381bfd88ce90a5ddb7823406b2a38cff6bb704b0acc289a09c8128d4a8ce2bbafcd1fcbdc38666422fe2806') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" \
	&& mv composer.phar /usr/local/bin/composer
ENV COMPOSER_CACHE_DIR="/tmp/composer-cache"

# We currently have issues with PHPUnit and PHP8 in our setup, so not adding this here.
# RUN composer global require phpunit/phpunit
ENV PATH="/root/.composer/vendor/bin:$PATH"
