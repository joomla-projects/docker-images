FROM ubuntu:14.04

LABEL authors="Yves Hoppe, Robert Deutz"

# Install
RUN apt-get update \
	&& DEBIAN_FRONTEND='noninteractive' apt-get install -y php5 php5-cli php5-memcache php5-memcached php5-redis php5-xdebug wget mysql-client postgresql-client \
		git curl php5-gd php5-mcrypt php5-pgsql php5-mysql php5-sqlite \
	&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /etc/php5/cli/php.ini \
	&& echo "extension=mcrypt.so" > /etc/php5/cli/conf.d/20-mcrypt.ini \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && cd /usr/local/bin \
  && wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-4.8.35.phar \
  && chmod +x phpunit
