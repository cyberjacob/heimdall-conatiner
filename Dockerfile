FROM php:7.3-apache

#RUN apk add --no-cache --upgrade \
#	curl \
#	php7-ctype \
#	php7-curl \
#	php7-pdo_pgsql \
#	php7-pdo_sqlite \
#	php7-tokenizer \
#	php7-zip \
#	tar

RUN apt-get update && apt-get install -y \
#    libpng-dev \
#    libonig-dev \
#    libsqlite3-dev \
#    libonig-dev \
#    libxml2-dev \
    libzip-dev \
      && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install \
 #pdo_sqlite mbstring openssl filter tokenizer ctype xml json
 zip
 #exif pcntl bcmath gd

COPY --from=composer:1 /usr/bin/composer /usr/bin/composer

RUN mkdir -p /heimdall && \
        curl -o /heimdall/heimdall.tar.gz -L "https://github.com/linuxserver/Heimdall/archive/2.2.2.tar.gz"

WORKDIR /heimdall
RUN tar -zxf heimdall.tar.gz

WORKDIR /heimdall/Heimdall-2.2.2
RUN mkdir -p /config && \
    cp .env.example .env && \
    ln -s /heimdall/Heimdall-2.2.2/database/app.sqlite /config/app.sqlite && \

RUN composer install --prefer-dist --no-ansi --no-interaction --no-progress --no-scripts
RUN php artisan key:generate
RUN chmod 777 -R .

RUN sed -ri -e 's!/var/www/html!/heimdall/Heimdall-2.2.2/public!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!/var/www/!/heimdall/Heimdall-2.2.2/public!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf && \
    sed -ri -e 's!Listen 80!Listen 29398!g' /etc/apache2/ports.conf /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!80!29398!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!AllowOverride None!AllowOverride All!g' /etc/apache2/apache2.conf && \
    a2enmod rewrite && a2enmod negotiation
