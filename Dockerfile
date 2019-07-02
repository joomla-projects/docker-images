FROM php:5.5-fpm-alpine

LABEL authors="Hannes Papenberg"

RUN apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS
RUN apk --no-cache add zlib-dev libpng-dev postgresql-dev libmcrypt-dev pcre-dev libmemcached-dev

RUN docker-php-ext-install gd mysql mysqli pdo_mysql pgsql pdo_pgsql mcrypt

RUN pecl install xdebug-2.5.5
RUN pecl install memcached-2.2.0
RUN pecl install redis-2.2.8

RUN echo 'memory_limit=1G' > /usr/local/etc/php/conf.d/memory-limit.ini
