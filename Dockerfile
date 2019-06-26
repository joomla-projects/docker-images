FROM debian:jessie

LABEL authors="Yves Hoppe, Robert Deutz"

# Install
RUN apt-get update \
	&& DEBIAN_FRONTEND='noninteractive' apt-get install -y php5 php5-cli php5-memcache php5-memcached php5-xdebug php5-redis wget curl \
		git curl php5-gd php5-mcrypt php5-pgsql php5-mysql php5-sqlite mysql-client postgresql-client \
	&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /etc/php5/cli/php.ini \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && cd /usr/local/bin \
	&& wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-4.8.35.phar \
  && chmod +x phpunit
