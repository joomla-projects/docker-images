FROM ubuntu:18.04

LABEL authors="Yves Hoppe, Robert Deutz, Hannes Papenberg"

# Install
RUN apt-get update \
  && DEBIAN_FRONTEND='noninteractive' apt-get -y install software-properties-common apt-transport-https language-pack-en-base \
  && LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php \
  && apt-get update \
	&& DEBIAN_FRONTEND='noninteractive' apt-get install -y --allow-unauthenticated php7.3 php-memcache php-memcached php-redis php-xdebug wget \
	  curl composer php-gd php-gettext php-mbstring php-mysql php-phpseclib php-sqlite3 mysql-client postgresql-client php-pgsql \
		&& sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /etc/php/7.3/cli/php.ini \
    && apt-get clean \
    && apt-get -y install gcc make autoconf libc-dev pkg-config \
    && apt-get -y install php7.3-dev \
    && apt-get -y install libmcrypt-dev \
    && pecl install mcrypt-1.0.2 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && cd /usr/local/bin
