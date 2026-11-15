# syntax=docker/dockerfile:1.7

FROM php:8.4-fpm-bookworm

ARG APP_UID=1000
ARG APP_GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" bcmath gd intl opcache pdo_mysql zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && rm -rf /var/lib/apt/lists/*

COPY infra/docker/php/php.ini /usr/local/etc/php/conf.d/99-fadespace.ini

WORKDIR /var/www/html

COPY backend/composer.json backend/composer.lock ./
RUN composer install --no-interaction --prefer-dist --no-progress --no-scripts --no-autoloader

COPY backend/ ./
RUN composer dump-autoload --optimize --no-interaction \
    && mkdir -p storage/logs storage/framework/{cache,sessions,views} bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache

USER www-data
