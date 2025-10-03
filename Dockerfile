FROM php:8.5-rc-apache

LABEL authors="Hannes Papenberg, Harald Leithner"

# Build process supplies the current composer-setup.php signature
ARG COMPOSERSIG

RUN seq 1 8 | xargs -I{} mkdir -p /usr/share/man/man{}
RUN apt-get update
RUN apt-get install -y autoconf gcc git libbz2-dev libfreetype6-dev libmemcached-dev \
	libwebp-dev libjpeg-dev libpq-dev libldap2-dev libmcrypt-dev libonig-dev \
	libpng-dev libsodium-dev libsqlite3-dev libssl-dev libxpm-dev libzip-dev \
	mariadb-client patch postgresql-client unzip wget zstd

# Install PIE
COPY --from=ghcr.io/php/pie:bin /pie /usr/bin/pie

RUN docker-php-ext-configure gd \
	--with-freetype \
	--with-jpeg \
	--with-webp \
	--enable-gd

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install bz2
RUN docker-php-ext-install exif
RUN docker-php-ext-install ftp
RUN docker-php-ext-install ldap
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install sodium
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install pdo_pgsql
RUN docker-php-ext-install pdo_sqlite
RUN docker-php-ext-install pgsql
RUN docker-php-ext-install zip

RUN docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg \
    && docker-php-ext-install gd

# Use PIE to install extensions
RUN pie install phpredis/phpredis:@dev
RUN pie install php-memcached/php-memcached:@dev
RUN pie install apcu/apcu:@dev \
	&& echo "\napc.enable=1\napc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-production \
	&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-development \
	&& cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
	&& php -r "if (hash_file('sha384', 'composer-setup.php') === '$COMPOSERSIG') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" \
	&& mv composer.phar /usr/local/bin/composer
ENV COMPOSER_CACHE_DIR="/tmp/composer-cache"

RUN cd /usr/local/bin \
	&& wget -O phpunit-9 https://phar.phpunit.de/phpunit-9.phar \
	&& chmod +x phpunit-9 \
    && ln -s phpunit-9 phpunit

RUN cd /usr/local/bin \
	&& wget -O phpunit-10 https://phar.phpunit.de/phpunit-10.phar \
	&& chmod +x phpunit-10

RUN cd /usr/local/bin \
	&& wget -O phpunit-11 https://phar.phpunit.de/phpunit-11.phar \
	&& chmod +x phpunit-11

RUN cd /usr/local/bin \
	&& wget -O phpunit-12 https://phar.phpunit.de/phpunit-12.phar \
	&& chmod +x phpunit-12

RUN cd /usr/local/bin \
	&& wget -O phpcpd https://phar.phpunit.de/phpcpd.phar \
	&& chmod +x phpcpd

RUN cd /usr/local/bin \
	&& wget -O phploc https://phar.phpunit.de/phploc.phar \
	&& chmod +x phploc
