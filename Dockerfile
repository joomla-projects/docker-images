FROM alpine:edge

LABEL authors="Sebastian Enns, Lukas Maximilian Kimpel, Hannes Papenberg, Harald Leithner"

RUN apk --no-cache add \
        libressl \
        lftp \
        bash \
        diffutils \
        git \
        openssh-client \
        zip \
        php \
        php-curl \
        php-openssl \
        php-json \
        php-phar \
        php-zip \
        php-xml \
        php-dom \
        php-iconv \
        php-gd \
        php-ldap \
        php-ctype \
        php-mbstring \
        php-tokenizer \
        php-xmlwriter \
        php-simplexml \
        wget \
        curl \
        npm

ENV CMP_ARCHIVE_NAME "build"
ENV CMP_MASTER_FOLDER "../joomla-original"
ENV CMP_SLAVE_FOLDER "../joomla-original2"
ENV BRANCH_NAME "4.0-dev"

ENV FTP_HOSTNAME "joomla-dev.lukaskimpel.com:21"
ENV FTP_USERNAME "joomla"
ENV FTP_PASSWORD "Jpwd123!"
ENV FTP_SECURE "true"
ENV FTP_VERIFY "false"

ADD composer_install.sh /bin
ADD compare.sh /bin

RUN chmod +x /bin/composer_install.sh
RUN /bin/composer_install.sh
RUN chmod +x /bin/compare.sh

RUN /bin/compare.sh
