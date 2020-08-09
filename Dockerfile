FROM php:5.6-fpm-alpine

LABEL authors="Hannes Papenberg"

RUN apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS
RUN apk --no-cache add zlib-dev libpng-dev postgresql-dev libmcrypt-dev pcre-dev libmemcached-dev curl

RUN apk add --no-cache \
        freetype \
        libpng \
        libjpeg-turbo \
        freetype-dev \
        libpng-dev \
        jpeg-dev \
        libjpeg \
        libjpeg-turbo-dev

RUN docker-php-ext-configure gd \
        --with-freetype-dir=/usr/lib/ \
        --with-png-dir=/usr/lib/ \
        --with-jpeg-dir=/usr/lib/ \
        --with-gd

RUN NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && docker-php-ext-install -j${NPROC} gd

RUN docker-php-ext-install mysql mysqli pdo_mysql pgsql pdo_pgsql mcrypt

RUN pecl install xdebug-2.5.5
RUN pecl install memcached-2.2.0
RUN pecl install redis-2.2.8

RUN echo 'memory_limit=1G' > /usr/local/etc/php/conf.d/memory-limit.ini

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
   && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e5325b19b381bfd88ce90a5ddb7823406b2a38cff6bb704b0acc289a09c8128d4a8ce2bbafcd1fcbdc38666422fe2806') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
   && php composer-setup.php \
   && php -r "unlink('composer-setup.php');" \
   && mv composer.phar /usr/local/bin/composer
RUN cd /usr/local/bin \
   && curl https://phar.phpunit.de/phpunit-4.8.35.phar --output phpunit --insecure \
   && chmod +x phpunit