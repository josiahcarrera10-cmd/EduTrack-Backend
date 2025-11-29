# Dockerfile for Laravel on Render (Optimized Caching)
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
# 1. Copy composer files only (enables caching)
# ---------------------------------------------------------------------
COPY composer.json composer.lock ./

# Install PHP deps (cached unless composer files change)
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# ---------------------------------------------------------------------
# 2. Install Node.js (cached unless Dockerfile changes)
# ---------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# ---------------------------------------------------------------------
# 3. Copy package files only (cached npm install)
# ---------------------------------------------------------------------
COPY package.json package-lock.json* ./

# Install JS deps & build assets only if package.json exists
RUN if [ -f package.json ]; then \
      npm install --legacy-peer-deps && npm run build; \
    fi

# ---------------------------------------------------------------------
# 4. Now copy the entire project (does NOT break dependency cache)
# ---------------------------------------------------------------------
COPY . .

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 8000

# Auto-run migrations then start the server
CMD php artisan migrate --force && \
    php artisan serve --host=0.0.0.0 --port=${PORT:-8000}
