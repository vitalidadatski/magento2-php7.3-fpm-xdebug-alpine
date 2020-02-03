FROM php:7.3-fpm-alpine

LABEL mainteiner=vitali.dadatski@gmail.com

RUN set -xe \
    && apk add --no-cache --virtual .build-deps \
        mysql-client \
        libzip-dev \
        freetype-dev \
        icu-dev \
        libmcrypt-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libxslt-dev \
        curl \
        zip \
        bash \
        vim \
        git

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-install intl  -j$(nproc) xsl gd zip pdo_mysql opcache soap bcmath json iconv

RUN sed -i 's/pm.max_children = 5/pm.max_children = 6/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/pm.start_servers = 2/pm.start_servers = 4/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/pm.min_spare_servers = 1/pm.min_spare_servers = 2/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 5/' /usr/local/etc/php-fpm.d/www.conf \
    && touch /usr/local/etc/php/conf.d/magento.ini && echo 'memory_limit=4096M' >> /usr/local/etc/php/conf.d/magento.ini \
    && echo 'cgi.fix_pathinfo=0' >> /usr/local/etc/php/conf.d/magento.ini

# Get composer installed to /usr/local/bin/composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del .phpize-deps $PHPIZE_DEPS \
    && echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.remote_host="docker.for.mac.localhost"' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.remote_connect_back=0' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.remote_port=9000' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.remote_autostart = 1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.idekey="PHPSTORM"' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.max_nesting_level=1000' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

CMD ["php-fpm", "-R"]