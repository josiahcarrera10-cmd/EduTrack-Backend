FROM php:8.2-fpm

# Install system packages & PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    curl \
    libzip-dev \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ---------------------------------------------------------------------
# 1. Copy entire project FIRST so artisan exists for composer scripts
# ---------------------------------------------------------------------
COPY . .

# ---------------------------------------------------------------------
# 2. Install PHP dependencies (composer)
# ---------------------------------------------------------------------
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# ---------------------------------------------------------------------
# 3. Install Node.js for building Vite assets
# ---------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# ---------------------------------------------------------------------
# 4. Install and build frontend assets
# ---------------------------------------------------------------------
RUN if [ -f package.json ]; then \
      npm install --legacy-peer-deps && npm run build; \
    fi

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 8000

CMD php artisan migrate --force && \
    php artisan serve --host=0.0.0.0 --port=${PORT:-8000}
