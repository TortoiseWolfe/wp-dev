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

# Check for GamiPress BuddyPress integration
echo "Setting up GamiPress BuddyPress integration..."
if wp plugin is-installed gamipress-buddypress-integration --path=/var/www/html; then
    echo "GamiPress BuddyPress integration already installed, activating..."
    wp plugin activate gamipress-buddypress-integration --path=/var/www/html || echo "Warning: Failed to activate GamiPress-BuddyPress integration"
else
    echo "Installing GamiPress BuddyPress integration..."
    wp plugin install gamipress-buddypress-integration --activate --path=/var/www/html || echo "Warning: Could not install GamiPress-BuddyPress integration"
fi

# Install simple-gamification plugin
echo "Installing simple-gamification plugin..."
# Create plugins directory if it doesn't exist
if [ ! -d "/var/www/html/wp-content/plugins" ]; then
    mkdir -p /var/www/html/wp-content/plugins
    chown www-data:www-data /var/www/html/wp-content/plugins
fi

# Copy the simple-gamification.php to plugins directory
if [ -f "/usr/local/bin/devscripts/simple-gamification.php" ]; then
    cp /usr/local/bin/devscripts/simple-gamification.php /var/www/html/wp-content/plugins/simple-gamification.php
    chown www-data:www-data /var/www/html/wp-content/plugins/simple-gamification.php
    chmod 644 /var/www/html/wp-content/plugins/simple-gamification.php
    wp plugin activate simple-gamification --path=/var/www/html || echo "Warning: Failed to activate simple-gamification plugin"
    echo "Simple gamification plugin installed and activated"
else
    echo "Warning: simple-gamification.php not found in devscripts"
fi

# Verify GamiPress plugins activation status
echo "Verifying GamiPress plugins activation status:"
wp plugin list --path=/var/www/html | grep -E 'gamipress|simple-gamification'

# Install and activate BuddyX theme and recommended plugins
echo "Activating BuddyX theme and installing recommended plugins..."
wp theme activate buddyx --path=/var/www/html || handle_error $LINENO

# Install BuddyX recommended plugins with improved handling
echo "Installing and activating recommended plugins for BuddyX theme..."

# Check if plugins are already installed first, then activate them
echo "Checking for Classic Widgets plugin..."
if wp plugin is-installed classic-widgets --path=/var/www/html; then
    echo "Classic Widgets plugin already installed, activating..."
    wp plugin activate classic-widgets --path=/var/www/html || echo "Warning: Failed to activate Classic Widgets plugin"
else
    echo "Installing Classic Widgets plugin..."
    wp plugin install classic-widgets --activate --path=/var/www/html || echo "Warning: Failed to install Classic Widgets plugin"
fi

echo "Checking for Elementor plugin..."
if wp plugin is-installed elementor --path=/var/www/html; then
    echo "Elementor plugin already installed, activating..."
    wp plugin activate elementor --path=/var/www/html || echo "Warning: Failed to activate Elementor plugin"
else
    echo "Installing Elementor plugin..."
    wp plugin install elementor --activate --path=/var/www/html || echo "Warning: Failed to install Elementor plugin"
fi

echo "Checking for Kirki plugin..."
if wp plugin is-installed kirki --path=/var/www/html; then
    echo "Kirki plugin already installed, activating..."
    wp plugin activate kirki --path=/var/www/html || echo "Warning: Failed to activate Kirki plugin"
else
    echo "Installing Kirki plugin..."
    wp plugin install kirki --activate --path=/var/www/html || echo "Warning: Failed to install Kirki plugin"
fi

# Verify plugins are activated
echo "Verifying BuddyX recommended plugins activation status:"
wp plugin list --path=/var/www/html | grep -E 'classic-widgets|elementor|kirki'

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

# First, modify the MySQL mode to avoid STRICT_TRANS_TABLES errors with BuddyPress
echo "Modifying MySQL mode to be compatible with BuddyPress..."
mysql -h "${WORDPRESS_DB_HOST%:*}" -u"${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'STRICT_TRANS_TABLES',''));" || echo "Could not modify MySQL mode, some BuddyPress components might fail to activate."

# Deactivate any existing components to ensure clean activation
echo "Clearing existing component states for clean activation..."
wp bp component deactivate friends messages blogs --path=/var/www/html || true
sleep 1

# Explicitly activate each component needed for ScriptHammer
echo "Activating required BuddyPress components with improved error handling..."

# First activate core components that other components depend on
echo "Activating core BuddyPress components first..."
wp bp component activate xprofile --path=/var/www/html || true
wp bp component activate settings --path=/var/www/html || true
wp bp component activate members --path=/var/www/html || true
wp bp component activate groups --path=/var/www/html || true
wp bp component activate activity --path=/var/www/html || true
wp bp component activate notifications --path=/var/www/html || true

# Wait for these to take effect
sleep 3

# Individually activate each remaining component with proper error checking
echo "Activating friends component..."
if ! wp bp component activate friends --path=/var/www/html; then
    echo "Failed to activate friends component on first try, retrying with delay..."
    sleep 2
    wp bp component activate friends --path=/var/www/html || echo "ERROR: Friends component activation failed!"
fi

echo "Activating messages component..."
if ! wp bp component activate messages --path=/var/www/html; then
    echo "Failed to activate messages component on first try, retrying with delay..."
    sleep 2
    wp bp component activate messages --path=/var/www/html || echo "ERROR: Messages component activation failed!"
fi

echo "Activating blogs component..."
if ! wp bp component activate blogs --path=/var/www/html; then
    echo "Failed to activate blogs component on first try, retrying with delay..."
    sleep 2
    wp bp component activate blogs --path=/var/www/html || echo "ERROR: Blogs component activation failed!"
fi

# Verify all components are active
echo "Verifying BuddyPress components status..."
ALL_ACTIVE=true
for component in xprofile settings members groups activity notifications friends messages blogs; do
    if ! wp bp component list --path=/var/www/html | grep -q "$component.*active"; then
        echo "❌ ERROR: $component component is NOT active!"
        ALL_ACTIVE=false
    else
        echo "✅ $component component is active"
    fi
done

if [ "$ALL_ACTIVE" = false ]; then
    echo "WARNING: Not all BuddyPress components were activated successfully."
    echo "This may affect the functionality of the site."
else
    echo "SUCCESS: All BuddyPress components activated correctly."
fi

# Display final component state
echo "Final BuddyPress components status:"
wp bp component list --path=/var/www/html

# Check for demo content flag and run the script if not skipped
if [ "${SKIP_DEMO_CONTENT}" != "true" ]; then
  echo "Creating FULL demo content (users, posts, groups, tutorials)..."
  /usr/local/bin/devscripts/demo-content.sh
else
  echo "Skipping random demo content, but still creating tutorial content..."
  # Still create tutorial content even when skipping demo content
  /usr/local/bin/devscripts/demo-content.sh --skip-all
fi

# Run the ScriptHammer band setup script to create band members, group, and Ivory's posts
echo "Creating ScriptHammer band members and group..."
if [ -x /usr/local/bin/devscripts/scripthammer.sh ]; then
  # Ensure script is executable
  chmod +x /usr/local/bin/devscripts/scripthammer.sh
  # Run the script
  /usr/local/bin/devscripts/scripthammer.sh
  
  # Verify the group was created
  if wp bp group get scripthammer --path=/var/www/html > /dev/null 2>&1; then
    echo "✅ ScriptHammer band group created successfully!"
  else
    echo "❌ ERROR: ScriptHammer band group was not created properly!"
  fi
else
  echo "⚠️ WARNING: scripthammer.sh script not found or not executable"
fi

echo "Content creation process started in background - it may take a few minutes to complete."

echo "Setup completed successfully."
