FROM php:7.4-cli-bullseye

LABEL authors="Harald Leithner"

# Build process supplies the current composer-setup.php signature
ARG COMPOSERSIG

RUN seq 1 8 | xargs -I{} mkdir -p /usr/share/man/man{}
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get update
RUN apt-get install -y git unzip zstd zip nodejs tar diffutils lftp wget rclone

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '$COMPOSERSIG') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

ENV COMPOSER_CACHE_DIR="/tmp/composer-cache"

ADD drone_build.sh /bin
ADD notify /bin

ADD templates /build_templates

RUN php -v

RUN chmod +x /bin/drone_build.sh
RUN chmod +x /bin/notify
