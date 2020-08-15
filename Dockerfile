FROM ubuntu:12.04
MAINTAINER Alexander Schenkel <alex@alexi.ch>

VOLUME ["/var/www/html"]

RUN apt-get update && \
	apt-get install -y \
		apache2 \
		git \
		php5 \
		php5-cli \
		libapache2-mod-php5 \
		php5-gd \
		php5-ldap \
		php5-mysql \
		php5-pgsql \
		unzip \
		wget

RUN echo 'memory_limit=-1' > /usr/local/lib/php.ini

# Unfortunately this ancient linux has issues with reaching getcomposer.org, so we keep our own/old composer version
COPY composer /usr/local/bin
RUN chmod +x /usr/local/bin/composer

RUN cd /usr/local/bin \
	&& wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-4.8.36.phar \
	&& chmod +x phpunit

COPY apache_default /etc/apache2/sites-available/default
COPY run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run
RUN a2enmod rewrite

WORKDIR /var/www/html

EXPOSE 80
CMD ["/usr/local/bin/run"]
