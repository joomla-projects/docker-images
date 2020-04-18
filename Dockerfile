FROM alpine:edge

LABEL authors="Sebastian Enns, Lukas Maximilian Kimpel, Hannes Papenberg, Harald Leithner Roland Dalmulder"

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
        php-gmp \
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

ADD composer_install.sh /bin
ADD compare.sh /bin

RUN chmod +x /bin/composer_install.sh
RUN /bin/composer_install.sh
RUN chmod +x /bin/compare.sh
