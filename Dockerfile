# Joomla! System tests
FROM ubuntu:focal
MAINTAINER Yves Hoppe <yves@compojoom.com>, Robert Deutz <rdeutz@googemail.com>, Harald Leithner <harald.leithner@community.joomla.org>

# Set correct environment variables.
ENV HOME /root

# update the package sources
RUN apt-get update

# we use the enviroment variable to stop debconf from asking questions..
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y mariadb-server mariadb-client apache2 \
    curl wget firefox unzip git fluxbox libxss1 libappindicator3-1 libindicator7 openjdk-8-jre xvfb \
    gconf-service fonts-liberation dbus xdg-utils libasound2 libpython2.7 \
    libaudio2 libgbm1 fontconfig netcat \
    lsb-release ca-certificates apt-transport-https software-properties-common

RUN add-apt-repository ppa:ondrej/php

# Install PHP 
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y \
    php8.1 php8.1-cli php8.1-curl php8.1-gd php8.1-mysql php8.1-zip \
    php8.1-xml php8.1-ldap php8.1-mbstring libapache2-mod-php8.1 php8.1-pgsql

# use newer NodeJS version
RUN curl -sL deb.nodesource.com/setup_12.x | bash -

# update the package sources
RUN apt-get update -qq && apt-get upgrade -qq

RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y nodejs 

# Install npx which is required to trigger our JS testsuite
RUN npm install -g --force npx

# package install is finished, clean up
RUN apt-get clean # && rm -rf /var/lib/apt/lists/*

# Create testing directory
RUN mkdir -p /tests/www

# Apache site conf
ADD config/000-default.conf /etc/apache2/sites-available/000-default.conf

# clean up tmp files (we don't need them for the image)
RUN rm -rf /tmp/* /var/tmp/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=bin --filename=composer
RUN composer self-update
RUN git config --global http.postBuffer 524288000

# Beta Version if needed
#RUN wget -nv https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb
RUN wget -nv https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# Fall back to old stable because current version (87.0.4280.66) fail to work with selenium (Status 2020-11-27)
#RUN wget -nv https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_85.0.4183.121-1_amd64.deb
RUN dpkg -i google-chrome*.deb

# Get the matching driver version for the installed google chrome
RUN wget "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_`dpkg --info google-chrome*.deb | grep Version | awk '{print $2}' | cut -d . -f 1`" -O chrome_driver_version
RUN echo -n \'`cat chrome_driver_version`\', > chrome_driver_version_tmp 

RUN apt-get upgrade -y

RUN npm install -g selenium-standalone

# Replace default version with required chrome version and delete unsed drivers (ie, firefox, edge)
RUN sed -i '/chrome: {/!b;n;c\      version: '`cat chrome_driver_version_tmp` /usr/lib/node_modules/selenium-standalone/lib/default-config.js && \
    sed -i '/ie: {/,/}/d' /usr/lib/node_modules/selenium-standalone/lib/default-config.js && \
    sed -i '/firefox: {/,/}/d' /usr/lib/node_modules/selenium-standalone/lib/default-config.js && \
    sed -i '/edge: {/,/}/d' /usr/lib/node_modules/selenium-standalone/lib/default-config.js && \
    sed -i '/config.drivers.chromiumedge/,/}/d' /usr/lib/node_modules/selenium-standalone/lib/default-config.js

# Only install Chrome at this time
RUN selenium-standalone install

# Start Apache and MySQL
CMD apache2ctl -D FOREGROUND
