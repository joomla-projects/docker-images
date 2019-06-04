FROM phpdaily/php:8.0-dev
RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
		libpq-dev

# RUN pecl install memcached 
RUN docker-php-ext-install -j$(nproc) iconv 
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ 
RUN docker-php-ext-install -j$(nproc) gd 
# RUN docker-php-ext-enable memcached 
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql
RUN docker-php-ext-install pdo pdo_mysql mysqli pdo_pgsql pgsql
RUN echo 'memory_limit = 2G' > "/usr/local/etc/php/conf.d/docker-env.ini"