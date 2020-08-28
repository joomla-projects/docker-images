FROM ubuntu:12.04
MAINTAINER "Hannes Papenberg, adapted from Alexander Schenkel <alex@alexi.ch>"

VOLUME ["/var/www/html"]

RUN apt-get update && \
	apt-get install -y \
		apache2 \
		git \
		libapache2-mod-php5 \
		mysql-client \
		php-apc \
		php-pear \
		php5 \
		php5-cli \
		php5-curl \
		php5-dev \
		php5-gd \
		php5-ldap \
		php5-memcached \
		php5-mysql \
		php5-pgsql \
		pkg-config \
		postgresql-client \
		make \
		patch \
		unzip \
		wget

RUN echo 'memory_limit=-1' > /usr/local/lib/php.ini

# Unfortunately this ancient linux has issues with reaching getcomposer.org, so we keep our own/old composer version
COPY composer /usr/local/bin
RUN chmod +x /usr/local/bin/composer
ENV COMPOSER_CACHE_DIR="/tmp/composer-cache"

RUN cd /usr/local/bin \
	&& wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-4.8.36.phar \
	&& chmod +x phpunit

RUN pecl channel-update pecl.php.net && pecl install redis-4.3.0
RUN echo extension=redis.so > /etc/php5/conf.d/redis.ini

COPY apache_default /etc/apache2/sites-available/default
COPY run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run
RUN a2enmod rewrite

WORKDIR /var/www/html

EXPOSE 80
CMD ["/usr/local/bin/run"]
