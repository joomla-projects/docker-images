FROM alpine:edge

LABEL authors="Harald Leithner"

RUN apk --no-cache add \
        libressl \
        lftp \
        bash \
        diffutils \
        git \
        openssh-client \
        zip \
        zstd \
        tar \
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

ADD composer_install.sh /bin
ADD drone_build.sh /bin

RUN chmod +x /bin/composer_install.sh /bin/drone_build.sh
RUN /bin/composer_install.sh
