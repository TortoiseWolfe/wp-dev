#!/bin/bash
set -e

echo "Waiting for database connection..."
until wp db check --path=/var/www/html; do
  sleep 5
done

# Create wp-config.php if it doesn't exist
if [ ! -f /var/www/html/wp-config.php ]; then
  echo "wp-config.php not found. Creating configuration..."
  wp config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --path=/var/www/html
fi

# Install WordPress if not already installed
if ! wp core is-installed --path=/var/www/html; then
  echo "WordPress not installed. Installing..."
  wp core install \
    --url="${WP_SITE_URL}" \
    --title="${WP_SITE_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --path=/var/www/html
else
  echo "WordPress is already installed."
fi

echo "Activating BuddyPress plugin..."
wp plugin activate buddypress --path=/var/www/html

echo "Setup completed. Exiting."
