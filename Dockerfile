FROM phpdaily/php:7.4.0-dev-fpm-alpine

LABEL authors="Hannes Papenberg"

COPY docker-php-ext-get /usr/local/bin/

ENV MEMCACHED_VERSION 3.1.3
ENV REDIS_VERSION 5.0.2

RUN set -xe \
    && apk --no-cache add zlib-dev libpng-dev postgresql-dev autoconf gcc \
    freetype libpng libjpeg-turbo freetype-dev jpeg-dev libjpeg \
    libjpeg-turbo-dev gcc make libc-dev libmemcached-libs zlib \
    $PHPIZE_DEPS libmemcached-dev cyrus-sasl-dev

RUN docker-php-source extract \
    && docker-php-ext-configure gd --with-gd --with-jpeg --with-png \
    --with-zlib --with-freetype --enable-gd-native-ttf \
    && docker-php-ext-get memcached $MEMCACHED_VERSION \
    && docker-php-ext-get redis $REDIS_VERSION \
    && docker-php-ext-install gd mysqli pdo_mysql pgsql pdo_pgsql memcached redis
