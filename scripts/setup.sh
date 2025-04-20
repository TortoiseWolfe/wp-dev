#!/bin/bash

# Exit on error, but don't use set -e so we can handle errors more gracefully
handle_error() {
    echo "Error on line $1"
    exit 1
}

# Log setup start with timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting WordPress setup with WP_SITE_URL=${WP_SITE_URL}"

echo "Waiting for database connection..."
ATTEMPTS=0
MAX_ATTEMPTS=30
until wp core version --path=/var/www/html --allow-root || [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; do
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

# Install GamiPress plugins (always)
echo "Installing GamiPress plugins..."
wp plugin install gamipress --activate --path=/var/www/html || handle_error $LINENO
# Install additional GamiPress add-ons
wp plugin install gamipress-buddypress-integration --activate --path=/var/www/html || echo "Warning: Could not install GamiPress-BuddyPress integration"

echo "Activating BuddyX theme..."
wp theme activate buddyx --path=/var/www/html || handle_error $LINENO

# Set permalink structure and ensure site URL is correct
echo "Setting permalink structure and ensuring site URLs are correct..."
wp option update permalink_structure '/%postname%/' --path=/var/www/html
wp option update siteurl "${WP_SITE_URL}" --path=/var/www/html
wp option update home "${WP_SITE_URL}" --path=/var/www/html
wp rewrite flush --path=/var/www/html
wp rewrite structure '/%postname%/' --path=/var/www/html

# Create .htaccess if it doesn't exist
if [ ! -f /var/www/html/.htaccess ]; then
  echo "Creating .htaccess file for permalinks..."
  cat > /var/www/html/.htaccess << 'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
  # Set proper permissions
  chown www-data:www-data /var/www/html/.htaccess
  chmod 644 /var/www/html/.htaccess
fi

# Enable BuddyPress components one by one with error handling
echo "Enabling BuddyPress components..."
# This activates all components in a safer way
wp bp component list --format=json --path=/var/www/html | grep -o '"component_id":"[^"]*"' | sed 's/"component_id":"//;s/"//' | while read -r component; do
    echo "Activating component: $component"
    wp bp component activate "$component" --path=/var/www/html || echo "Failed to activate $component, continuing..."
done

# Check for demo content flag and run the script if not skipped
if [ "${SKIP_DEMO_CONTENT}" != "true" ]; then
  echo "Creating FULL demo content (users, posts, groups, tutorials)..."
  /usr/local/bin/devscripts/demo-content.sh
else
  echo "Skipping random demo content, but still creating tutorial content..."
  # Still create tutorial content even when skipping demo content
  /usr/local/bin/devscripts/demo-content.sh --skip-all
fi

echo "Content creation process started in background - it may take a few minutes to complete."

echo "Setup completed successfully."
