# Joomla! Cypress
FROM cypress/browsers:latest
LABEL org.opencontainers.image.authors="Yves Hoppe <yves@compojoom.com>, Robert Deutz <rdeutz@googemail.com>, Harald Leithner <harald.leithner@community.joomla.org>"

# Set correct environment variables.
ENV HOME /root

# Update the package sources
RUN apt update
RUN DEBIAN_FRONTEND='noninteractive' apt install -y curl

# Add sury php repository
RUN curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ `. /etc/os-release ; echo $VERSION_CODENAME` main" > /etc/apt/sources.list.d/php.list

# Update the package sources
RUN apt update

# We use the environment variable to stop debconf from asking questions..
RUN DEBIAN_FRONTEND='noninteractive' apt install -y apache2 \
    php8.2  php8.2-cli php8.2-curl php8.2-gd php8.2-mysql php8.2-zip php8.2-xml php8.2-ldap php8.2-mbstring libapache2-mod-php8.2 php8.2-pgsql \
    curl wget unzip git netcat-openbsd rsync openssl

# Remove unneded library which leads to an error in cypress
# Error:
# [3957:0612/201109.017400:ERROR:sandbox_linux.cc(377)] InitializeSandbox() called with multiple threads in process gpu-process.
# [3957:0612/201109.030332:ERROR:gpu_memory_buffer_support_x11.cc(44)] dri3 extension not supported.
RUN DEBIAN_FRONTEND='noninteractive' apt autoremove -y libva-x11-2

# Package install is finished, clean up
RUN apt clean # && rm -rf /var/lib/apt/lists/*

# Create testing directory
RUN mkdir -p /tests/www

# Create certificates
RUN mkdir /tests/keys
RUN openssl req -new -newkey rsa:4096 -nodes -keyout /tests/keys/server.key -out /tests/keys/server.csr -subj "/CN=localhost"
RUN openssl x509 -req -days 365 -in /tests/keys/server.csr -signkey /tests/keys/server.key -out /tests/keys/server.crt

# Apache site conf
ADD config/000-default.conf /etc/apache2/sites-available/000-default.conf

# Enable Apache SSL module
RUN a2enmod ssl

# Clean up tmp files (we don't need them for the image)
RUN rm -rf /tmp/* /var/tmp/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=bin --filename=composer
RUN composer self-update
RUN git config --global http.postBuffer 524288000

RUN apt upgrade -y

# Start Apache
CMD apache2ctl -D FOREGROUND
