#!/bin/bash

# Exit on error, but don't use set -e so we can handle errors more gracefully
handle_error() {
    echo "Error on line $1"
    exit 1
}

echo "Waiting for database connection..."
ATTEMPTS=0
MAX_ATTEMPTS=30
until wp db check --path=/var/www/html || [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; do
  sleep 5
  ATTEMPTS=$((ATTEMPTS+1))
  echo "Waiting for database... Attempt $ATTEMPTS of $MAX_ATTEMPTS"
done

if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
  echo "Database connection timed out. Exiting."
  exit 1
fi

# Create wp-config.php if it doesn't exist
if [ ! -f /var/www/html/wp-config.php ]; then
  echo "wp-config.php not found. Creating configuration..."
  wp config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --path=/var/www/html || handle_error $LINENO
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
    --path=/var/www/html || handle_error $LINENO
else
  echo "WordPress is already installed."
fi

echo "Activating BuddyPress plugin..."
wp plugin activate buddypress --path=/var/www/html || handle_error $LINENO

echo "Activating BuddyX theme..."
wp theme activate buddyx --path=/var/www/html || handle_error $LINENO

# Enable BuddyPress components one by one with error handling
echo "Enabling BuddyPress components..."
# This activates all components in a safer way
wp bp component list --format=json --path=/var/www/html | grep -o '"component_id":"[^"]*"' | sed 's/"component_id":"//;s/"//' | while read -r component; do
    echo "Activating component: $component"
    wp bp component activate "$component" --path=/var/www/html || echo "Failed to activate $component, continuing..."
done

echo "Setup completed successfully."
