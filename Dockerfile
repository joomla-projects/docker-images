# Joomla! Cypress
FROM cypress/browsers:node16.14.2-slim-chrome100-ff99-edge
LABEL org.opencontainers.image.authors="Yves Hoppe <yves@compojoom.com>, Robert Deutz <rdeutz@googemail.com>, Harald Leithner <harald.leithner@community.joomla.org>"

# Set correct environment variables.
ENV HOME /root

# Add sury php repository
RUN curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ `. /etc/os-release ; echo $VERSION_CODENAME` main" > /etc/apt/sources.list.d/php.list

# update the package sources
RUN apt-get update

# we use the enviroment variable to stop debconf from asking questions..
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y apache2 \
    php7.2  php7.2-cli php7.2-curl php7.2-gd php7.2-mysql php7.2-zip php7.2-xml php7.2-ldap php7.2-mbstring libapache2-mod-php7.2 php7.2-pgsql \
    curl wget unzip git netcat rsync

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

RUN apt-get upgrade -y

# Start Apache
CMD apache2ctl -D FOREGROUND
