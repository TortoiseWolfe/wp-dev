#!/bin/bash
# Installation script for Steampunk BuddyX child theme

set -e
echo "Installing Steampunk BuddyX child theme..."

# Create the child theme directory and subdirectories
mkdir -p /var/www/html/wp-content/themes/steampunk-buddyx/template-parts/content
mkdir -p /var/www/html/wp-content/themes/steampunk-buddyx/template-parts/layout

# Ensure template directories exist
mkdir -p /var/www/html/wp-content/themes/steampunk-buddyx/template-parts
mkdir -p /var/www/html/wp-content/themes/steampunk-buddyx/template-parts/content

# Copy the child theme files
cp -r /usr/local/bin/devscripts/theme-patches/steampunk-buddyx/* /var/www/html/wp-content/themes/steampunk-buddyx/

# Ensure template folders are properly created
if [ -d "/usr/local/bin/devscripts/theme-patches/steampunk-buddyx/template-parts/content" ]; then
    cp -r /usr/local/bin/devscripts/theme-patches/steampunk-buddyx/template-parts/content/* /var/www/html/wp-content/themes/steampunk-buddyx/template-parts/content/
fi

if [ -d "/usr/local/bin/devscripts/theme-patches/steampunk-buddyx/template-parts/layout" ]; then
    cp -r /usr/local/bin/devscripts/theme-patches/steampunk-buddyx/template-parts/layout/* /var/www/html/wp-content/themes/steampunk-buddyx/template-parts/layout/
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/wp-content/themes/steampunk-buddyx
chmod -R 755 /var/www/html/wp-content/themes/steampunk-buddyx
find /var/www/html/wp-content/themes/steampunk-buddyx -type f -name "*.php" -exec chmod 644 {} \;

# Don't activate the theme here - this will be handled by the main install.sh script
# to ensure proper sequencing with WordPress initialization
# (Removed wp theme activate command to prevent redundant activation)

# Make sure Classic Widgets plugin is active
wp plugin activate --allow-root classic-widgets --path=/var/www/html || true

# FAIL-SAFE: Save BuddyPress component state before theme activation
# Note: This is a backup in case theme activation affects component settings
echo "Saving BuddyPress component state as a safety measure..."
if wp plugin is-active --allow-root buddypress --path=/var/www/html; then
    # Save current component state to a temporary file
    wp bp component list --status=active --format=json --path=/var/www/html --allow-root > /tmp/bp_components_backup.json 2>/dev/null || true
    
    # Activate critical components to ensure they're included in the backup
    for critical in friends messages groups blogs xprofile members activity notifications settings; do
        wp bp component activate $critical --path=/var/www/html --allow-root || true
    done
    
    echo "✅ BuddyPress component state preserved"
fi

echo "✅ Steampunk BuddyX child theme installed successfully!"