FROM php:8.3-apache

LABEL authors="Hannes Papenberg, Harald Leithner"

# Build process supplies the current composer-setup.php signature
ARG COMPOSERSIG

RUN seq 1 8 | xargs -I{} mkdir -p /usr/share/man/man{}
RUN apt-get update
RUN apt-get install -y autoconf gcc git libbz2-dev libfreetype6-dev libmemcached-dev \
	libwebp-dev libjpeg-dev libpq-dev libldap2-dev libmcrypt-dev libonig-dev \
	libpng-dev libsodium-dev libsqlite3-dev libssl-dev libxpm-dev libzip-dev \
	mariadb-client patch postgresql-client unzip wget gpg

RUN docker-php-ext-configure gd \
	--with-freetype \
	--with-jpeg \
	--with-webp \
	--enable-gd

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install bz2 exif ftp gd ldap mbstring sodium mysqli opcache pdo_mysql pdo_pgsql pdo_sqlite pgsql zip

RUN pecl install memcached \
	&& docker-php-ext-enable memcached

RUN pecl install redis \
	&& docker-php-ext-enable redis

RUN pecl install apcu \
	&& docker-php-ext-enable apcu \
	&& echo "\napc.enable=1\napc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-production \
	&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /usr/local/etc/php/php.ini-development \
	&& cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

RUN wget -O phive.phar https://phar.io/releases/phive.phar \
    && wget -O phive.phar.asc https://phar.io/releases/phive.phar.asc \
    && gpg --keyserver hkps://keys.openpgp.org --recv-keys 0x9D8A98B29B2D5D79 \
    && gpg --verify phive.phar.asc phive.phar \
    && chmod +x phive.phar \
    && mv phive.phar /usr/local/bin/phive

RUN phive install --target /usr/local/bin --copy --trust-gpg-keys 95DE904AB800754A11D80B605E6DDE998AB73B8E phpcs \
    && phive install --target /usr/local/bin --copy --trust-gpg-keys 95DE904AB800754A11D80B605E6DDE998AB73B8E phpcbf \
	&& phive install --target /usr/local/bin --copy --trust-gpg-keys D8406D0D82947747293778314AA394086372C20A phpunit \
    && phive install --target /usr/local/bin --copy --trust-gpg-keys D8406D0D82947747293778314AA394086372C20A phpcpd \
    && phive install --target /usr/local/bin --copy --trust-gpg-keys D8406D0D82947747293778314AA394086372C20A phploc \
    && phive install --target /usr/local/bin --copy --trust-gpg-keys A618F385C2FC002969A89FBE8101FB57DD8130F0 phan \
    && phive install --target /usr/local/bin --copy --trust-gpg-keys BBAB5DF0A0D6672989CF1869E82B2FB314E9906E php-cs-fixer \
    && phive install --target /usr/local/bin --copy --trust-gpg-keys 161DFBE342889F01DDAC4E61CBB3D576F2A0946F composer \
	&& phive install --target /usr/local/bin --copy --trust-gpg-keys E7A745102ECC980F7338B3079093F8B32E4815AA phpmd
