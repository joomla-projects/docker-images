# Joomla! System tests
FROM ubuntu:noble

# Set correct environment variables.
ENV HOME /root

# Update the package sources
RUN apt-get update

# We use the enviroment variable to stop debconf from asking questions..
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y mariadb-server mariadb-client apache2 \
    curl wget unzip git libxss1 libappindicator3-1 libindicator7 \
    fonts-liberation dbus xdg-utils \
    libaudio2 libgbm1 fontconfig \
    lsb-release ca-certificates apt-transport-https software-properties-common rsync

RUN add-apt-repository ppa:ondrej/php

# Install PHP
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y \
    php8.3 php8.3-cli php8.3-curl php8.3-gd php8.3-mysql php8.3-zip \
    php8.3-xml php8.3-ldap php8.3-mbstring libapache2-mod-php8.3 php8.3-pgsql

# Use newer NodeJS version
RUN curl -sL deb.nodesource.com/setup_23.x | bash -

# Update the package sources
RUN apt-get update -qq && apt-get upgrade -qq

RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y nodejs

# Install npx which is required to trigger our JS testsuite
RUN npm install -g --force npx

# Package install is finished, clean up
RUN apt-get clean # && rm -rf /var/lib/apt/lists/*

# Create testing directory
RUN mkdir -p /tests/www

# Apache site conf
ADD config/000-default.conf /etc/apache2/sites-available/000-default.conf

# Clean up tmp files (we don't need them for the image)
RUN rm -rf /tmp/* /var/tmp/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=bin --filename=composer
RUN composer self-update
RUN git config --global http.postBuffer 524288000

RUN apt-get upgrade -y

# Start Apache and MySQL
CMD apache2ctl -D FOREGROUND
