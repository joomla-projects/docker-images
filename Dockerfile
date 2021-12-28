FROM php:8.1-apache

LABEL authors="Hannes Papenberg, Harald Leithner"

# Build process supplies the current composer-setup.php signature
ARG COMPOSERSIG

RUN seq 1 8 | xargs -I{} mkdir -p /usr/share/man/man{}
RUN apt-get update
RUN apt-get install -y autoconf gcc git libbz2-dev libfreetype6-dev libmemcached-dev \
	libonig-dev libwebp-dev libjpeg-dev libpq-dev libldap2-dev libmcrypt-dev \
	libpng-dev libsodium-dev libsqlite3-dev libssl-dev libxpm-dev libzip-dev mariadb-client \
	patch postgresql-client unzip wget

RUN docker-php-ext-configure gd \
	--with-freetype \
	--with-jpeg \
	--with-webp \
	--enable-gd

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install bz2 exif ftp gd ldap mysqli pdo_mysql pdo_pgsql pdo_sqlite pgsql sodium zip # mbstring opcache

RUN pecl install memcached \
	&& docker-php-ext-enable memcached

# Unfortunately redis doesn't work yet in PHP8.0
# RUN pecl install redis \
#	&& docker-php-ext-enable redis

RUN pecl install apcu \
	&& docker-php-ext-enable apcu \
	&& echo "\napc.enable=1\napc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-production \
	&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-development

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
	&& php -r "if (hash_file('sha384', 'composer-setup.php') === '$COMPOSERSIG') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" \
	&& mv composer.phar /usr/local/bin/composer
ENV COMPOSER_CACHE_DIR="/tmp/composer-cache"

# We currently have issues with PHPUnit and PHP8 in our setup, so not adding this here.
# RUN composer global require phpunit/phpunit
ENV PATH="/root/.composer/vendor/bin:$PATH"
