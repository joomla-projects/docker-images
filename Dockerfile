FROM php:7.1-apache

LABEL authors="Hannes Papenberg"

RUN rm /etc/apt/preferences.d/no-debian-php
RUN apt-get update
RUN apt install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https
RUN wget https://packages.sury.org/php/apt.gpg && apt-key add apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php7.list
RUN apt-get update
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y git php7.1 php7.1-cli php7.1-memcache php7.1-memcached php7.1-xdebug \
	  curl php7.1-gd php7.1-mcrypt php7.1-mysql php7.1-pgsql php7.1-sqlite3 php7.1-zip ca-certificates wget gnupg2
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y mariadb-client postgresql-client zip
RUN sed -i 's/memory_limit\s*=.*/memory_limit=-1/g' /etc/php/7.1/cli/php.ini
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
   && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e5325b19b381bfd88ce90a5ddb7823406b2a38cff6bb704b0acc289a09c8128d4a8ce2bbafcd1fcbdc38666422fe2806') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
   && php composer-setup.php \
   && php -r "unlink('composer-setup.php');" \
   && mv composer.phar /usr/local/bin/composer
RUN cd /usr/local/bin \
   && wget -O phpunit --no-check-certificate https://phar.phpunit.de/phpunit-6.5.9.phar \
   && chmod +x phpunit