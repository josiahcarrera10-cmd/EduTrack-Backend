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

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Install Node and build assets if package.json exists
RUN if [ -f package.json ]; then \
      apt-get install -y nodejs npm && \
      npm install && npm run build; \
    fi

# Set permissions
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

EXPOSE 8000

# Start the app (Render will set PORT env variable)
CMD php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=${PORT:-8000}