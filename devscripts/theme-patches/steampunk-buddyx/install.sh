#!/bin/bash
# Installation script for Steampunk BuddyX child theme

set -e
echo "Installing Steampunk BuddyX child theme..."

# Create the child theme directory and subdirectories
mkdir -p /var/www/html/wp-content/themes/steampunk-buddyx/template-parts/content
mkdir -p /var/www/html/wp-content/themes/steampunk-buddyx/template-parts/layout

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

echo "✅ Steampunk BuddyX child theme installed successfully!"