FROM php:8.1-cli-bullseye

LABEL authors="Harald Leithner"

# Build process supplies the current composer-setup.php signature
ARG COMPOSERSIG

RUN seq 1 8 | xargs -I{} mkdir -p /usr/share/man/man{}
RUN apt-get update
RUN apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update
RUN apt-get install -y git unzip zstd zip nodejs tar diffutils lftp wget rclone

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '$COMPOSERSIG') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

ENV COMPOSER_CACHE_DIR="/tmp/composer-cache"

ADD drone_prepare_package.sh /bin
ADD add_github_status.sh /bin
ADD notify /bin

ADD templates /build_templates

RUN php -v

RUN chmod +x /bin/drone_prepare_package.sh
RUN chmod +x /bin/add_github_status.sh
RUN chmod +x /bin/notify
