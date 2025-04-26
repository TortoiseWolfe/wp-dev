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

echo "Activating BuddyPress plugin and initializing database tables..."
# First deactivate if already active to ensure clean initialization
wp plugin deactivate buddypress --path=/var/www/html || true
# Activate with proper initialization
wp plugin activate buddypress --path=/var/www/html || handle_error $LINENO
# Verify database tables exist by checking for critical BP tables
if ! wp db query "SHOW TABLES LIKE 'wp_bp_groups'" --path=/var/www/html | grep -q "wp_bp_groups"; then
    echo "BuddyPress database tables not properly created. Forcing database setup..."
    wp eval 'bp_core_install( bp_get_active_components() );' --path=/var/www/html || echo "⚠️ Warning: Couldn't run BuddyPress database setup"
fi

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

# Simple gamification has been removed
echo "Simple gamification plugin has been removed from this installation."

# Verify GamiPress plugins activation status
echo "Verifying GamiPress plugins activation status:"
wp plugin list --path=/var/www/html | grep -E 'gamipress|simple-gamification'

# Install BuddyX theme WITHOUT ACTIVATING - we'll activate the child theme later
echo "Installing BuddyX theme and recommended plugins..."
# Make sure BuddyX is available but don't activate it
if ! wp theme is-installed buddyx --path=/var/www/html; then
    echo "BuddyX theme not installed. Installing without activation..."
    wp theme install buddyx --path=/var/www/html || handle_error $LINENO
else
    echo "BuddyX theme already installed."
fi

# Install the Metronome app plugin
echo "Installing Metronome app plugin..."
if [ -f "/usr/local/bin/devscripts/metronome-app.php" ]; then
  METRONOME_FILE="/usr/local/bin/devscripts/metronome-app.php"
  echo "✅ Found metronome-app.php"
else
  echo "❌ Metronome app plugin not found in devscripts"
  exit 1
fi

# Create the mu-plugins directory if it doesn't exist
if [ ! -d "/var/www/html/wp-content/mu-plugins" ]; then
  mkdir -p /var/www/html/wp-content/mu-plugins
  chown www-data:www-data /var/www/html/wp-content/mu-plugins
fi

# Copy the metronome app to mu-plugins for automatic loading
cp "$METRONOME_FILE" /var/www/html/wp-content/mu-plugins/metronome-app.php
chown www-data:www-data /var/www/html/wp-content/mu-plugins/metronome-app.php
chmod 644 /var/www/html/wp-content/mu-plugins/metronome-app.php

# Force WordPress to recognize the mu-plugin by touching the file
touch /var/www/html/wp-content/mu-plugins/metronome-app.php

# Verify the shortcode is registered
if grep -q "add_shortcode.*scripthammer_react_app" /var/www/html/wp-content/mu-plugins/metronome-app.php; then
  echo "✅ Metronome app shortcode [scripthammer_react_app] registered"
else
  echo "❌ Metronome app shortcode not found in the plugin file"
fi

echo "✅ Metronome app plugin installed to mu-plugins"

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

# Activate Akismet Anti-Spam and delete Hello Dolly
echo "Managing required and unwanted plugins..."
# Activate Akismet Anti-Spam if installed
if wp plugin is-installed akismet --path=/var/www/html; then
    echo "Akismet Anti-Spam plugin already installed, activating..."
    wp plugin activate akismet --path=/var/www/html || echo "Warning: Failed to activate Akismet Anti-Spam plugin"
else
    echo "Installing Akismet Anti-Spam plugin..."
    wp plugin install akismet --activate --path=/var/www/html || echo "Warning: Failed to install Akismet Anti-Spam plugin"
fi

# Delete Hello Dolly plugin if it exists
if wp plugin is-installed hello --path=/var/www/html; then
    echo "Deleting Hello Dolly plugin..."
    wp plugin deactivate hello --path=/var/www/html
    wp plugin delete hello --path=/var/www/html || echo "Warning: Failed to delete Hello Dolly plugin"
fi

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

# Instead of modifying MySQL global settings (which requires SUPER privilege),
# use WordPress options to force BuddyPress components activation
echo "Setting up BuddyPress components using direct database options..."

# Create a persistent flag file to indicate this container has set up components
SETUP_FLAG="/var/www/html/.buddypress_components_configured"

# Check if we've already configured the components
if [ -f "$SETUP_FLAG" ]; then
    echo "BuddyPress components were previously configured, ensuring they're still active..."
else
    # First ensure the plugin is fully activated
    wp plugin activate buddypress --path=/var/www/html || true
    
    # Reset component state for a clean setup
    echo "Preparing for clean component activation..."
    wp cache flush --path=/var/www/html || true
    sleep 1
fi

# Force activate all required components by directly setting options in the database
# This approach avoids SQL mode issues and persists through container restarts
echo "Directly activating and persisting BuddyPress components..."

# Get the current active components
ACTIVE_COMPONENTS=$(wp option get bp-active-components --format=json --path=/var/www/html)

# Create a new components array with all required components activated
# This uses a secure, direct approach without modifying MySQL settings
wp eval '
// Define all the components we need to activate
$required_components = array(
    "xprofile"      => 1,
    "settings"      => 1,
    "members"       => 1,
    "groups"        => 1,
    "activity"      => 1,
    "notifications" => 1,
    "friends"       => 1,
    "messages"      => 1,
    "blogs"         => 1
);

// Get current components
$current = get_option("bp-active-components", array());

// Merge with our required components, ensuring they are all active
$updated = array_merge($current, $required_components);

// Save back to the database
update_option("bp-active-components", $updated);

// Additionally, ensure these settings are saved with autoload=yes for better performance
update_option("bp-active-components", $updated, "yes");

// For extra security, directly activate specific components in case the merge approach fails
bp_update_option("bp-active-components", $updated);

// Set additional BuddyPress options for better security
update_option("_bp_theme_package_id", "nouveau");
update_option("bp-disable-account-deletion", 0);
update_option("bp-disable-avatar-uploads", 0);
update_option("bp-disable-cover-image-uploads", 0);
update_option("bp-disable-group-avatar-uploads", 0);
update_option("bp-disable-group-cover-image-uploads", 0);

// Force refresh of BuddyPress cache
wp_cache_delete("bp_active_components", "bp");
' --path=/var/www/html || echo "⚠️  Warning: Could not execute direct component activation"

# Explicitly activate each component through WP-CLI as a backup method
echo "Ensuring activation through WP-CLI..."
for component in xprofile settings members groups activity notifications friends messages blogs; do
    wp bp component activate $component --path=/var/www/html || true
    sleep 1
done

# Create the setup flag file to avoid redoing this on every container start
if [ ! -f "$SETUP_FLAG" ]; then
    echo "BuddyPress components successfully configured at $(date)" > "$SETUP_FLAG"
    chmod 644 "$SETUP_FLAG"
    chown www-data:www-data "$SETUP_FLAG"
fi

# Force refresh BuddyPress cache
wp cache flush --path=/var/www/html || true

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

# Always create ScriptHammer band content first (the important part)
echo "Creating ScriptHammer band content (members, group, metronome)..."
if [ -x /usr/local/bin/devscripts/scripthammer.sh ]; then
  # Ensure script is executable
  chmod +x /usr/local/bin/devscripts/scripthammer.sh
  
  # Ensure exports directory exists and is accessible
  mkdir -p /var/www/html/wp-content/exports
  
  # Check if export files need to be copied from devscripts
  if [ ! -f "/var/www/html/wp-content/exports/all-band-content-000.xml" ] && [ -f "/usr/local/bin/devscripts/exports/all-band-content-000.xml" ]; then
    echo "Copying export files from devscripts directory..."
    cp /usr/local/bin/devscripts/exports/*.xml /var/www/html/wp-content/exports/ 2>/dev/null || true
  fi
  
  # Run the script with metronome flag if enabled
  if [[ "${CREATE_BAND_METRONOME:-true}" == "true" ]]; then
    /usr/local/bin/devscripts/scripthammer.sh --with-metronome
  else
    /usr/local/bin/devscripts/scripthammer.sh
  fi
  
  # Verify the group was created
  if wp bp group get scripthammer --path=/var/www/html > /dev/null 2>&1; then
    echo "✅ ScriptHammer band group created successfully!"
  else
    echo "❌ ERROR: ScriptHammer band group was not created properly!"
  fi
else
  echo "⚠️ WARNING: scripthammer.sh script not found or not executable"
fi

# Check for demo content flag and run the script if not skipped
# This is separate from the band content that is always created
if [ "${SKIP_DEMO_CONTENT}" != "true" ]; then
  echo "Creating additional demo content (users, posts, groups, tutorials)..."
  /usr/local/bin/devscripts/demo-content.sh
else
  echo "Skipping additional demo content, but still creating tutorial content..."
  # Still create tutorial content even when skipping demo content
  /usr/local/bin/devscripts/demo-content.sh --skip-all
fi

echo "Content creation process started in background - it may take a few minutes to complete."

echo "Setup completed successfully."
