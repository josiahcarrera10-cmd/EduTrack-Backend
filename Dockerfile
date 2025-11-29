# Dockerfile for Laravel on Render
FROM php:8.2-fpm

# Install system utilities & dependencies
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

# Copy all project files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Install modern Node.js (required for Vite)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Build assets only if package.json exists
RUN if [ -f package.json ]; then \
      npm install && npm run build; \
    fi

# File permissions
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

EXPOSE 8000

# Run migrations automatically, then start Laravel server
CMD php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=${PORT:-8000}    
