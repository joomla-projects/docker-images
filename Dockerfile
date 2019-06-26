FROM phpdaily/php:7.4.0-dev-fpm-alpine

LABEL authors="Hannes Papenberg"

RUN apk --no-cache add zlib-dev libpng-dev postgresql-dev autoconf gcc

RUN docker-php-ext-install gd mysqli pdo_mysql pgsql pdo_pgsql
