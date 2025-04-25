#!/bin/bash
# Theme patching script to fix BuddyX templates

set -e
echo "Installing theme patches..."

# Create the target directory if it doesn't exist
mkdir -p /var/www/html/wp-content/themes/buddyx/template-parts/content/

# Copy the fixed template that shows all categories
cp /usr/local/bin/devscripts/theme-patches/entry_categories.php /var/www/html/wp-content/themes/buddyx/template-parts/content/entry_categories.php
echo "✅ Installed category fix template"

# Optional: Add CSS to style the categories nicely
echo "<style>
.post-meta-category {
    display: flex;
    flex-wrap: wrap;
    gap: 5px;
}
.post-meta-category__item {
    display: inline-block !important;
    margin-right: 5px;
}
</style>" > /tmp/category-styles.txt

# Add this style to the theme's header
wp eval 'add_action("wp_head", function() { echo file_get_contents("/tmp/category-styles.txt"); });' --path=/var/www/html || true
echo "✅ Added styling for categories"

# Install the Steampunk BuddyX child theme if the directory exists
if [ -d "/usr/local/bin/devscripts/theme-patches/steampunk-buddyx" ]; then
    echo "Installing Steampunk BuddyX child theme manually..."
    
    # Create the child theme directory
    mkdir -p /var/www/html/wp-content/themes/steampunk-buddyx
    
    # Copy the core files directly (ONLY the CSS and functions.php)
    cp /usr/local/bin/devscripts/theme-patches/steampunk-buddyx/style.css /var/www/html/wp-content/themes/steampunk-buddyx/
    cp /usr/local/bin/devscripts/theme-patches/steampunk-buddyx/functions.php /var/www/html/wp-content/themes/steampunk-buddyx/ 2>/dev/null || true
    
    # Copy screenshot.png if it exists
    if [ -f "/usr/local/bin/devscripts/theme-patches/steampunk-buddyx/screenshot.png" ]; then
        cp /usr/local/bin/devscripts/theme-patches/steampunk-buddyx/screenshot.png /var/www/html/wp-content/themes/steampunk-buddyx/
    fi
    
    # Copy single.php if it exists
    if [ -f "/usr/local/bin/devscripts/theme-patches/steampunk-buddyx/single.php" ]; then
        cp /usr/local/bin/devscripts/theme-patches/steampunk-buddyx/single.php /var/www/html/wp-content/themes/steampunk-buddyx/
    fi
    
    # Set proper ownership
    chown -R www-data:www-data /var/www/html/wp-content/themes/steampunk-buddyx
    
    # Wait for WordPress to be fully initialized before activating the theme
    echo "Waiting for WordPress to be fully initialized before activating theme..."
    # Try multiple times with increasing delays to ensure WordPress is ready
    for i in 1 2 3 4 5; do
        sleep $(($i * 5))  # Increase wait time with each attempt
        echo "Attempt $i to activate steampunk-buddyx theme..."
        
        # Check WordPress status before attempting theme activation
        if wp core is-installed --path=/var/www/html --allow-root; then
            # Activate the child theme
            if wp theme activate steampunk-buddyx --path=/var/www/html --allow-root; then
                echo "✅ Successfully activated steampunk-buddyx theme on attempt $i"
                break
            else
                echo "⚠️ Failed to activate theme on attempt $i, will retry..."
            fi
        else
            echo "⚠️ WordPress core not fully installed yet, waiting longer..."
        fi
    done
    
    # Make sure Classic Widgets plugin is active
    wp plugin activate classic-widgets --path=/var/www/html --allow-root || true
    
    # Register a WordPress hook to check and activate the theme after init
    wp eval '
    add_action("init", function() {
        if (get_option("stylesheet") !== "steampunk-buddyx") {
            switch_theme("steampunk-buddyx");
            update_option("theme_switched", "steampunk-buddyx");
        }
    }, 999);
    ' --path=/var/www/html --allow-root || true
    
    echo "✅ Steampunk BuddyX child theme installed and activation process complete"
else
    echo "⚠️ Warning: Steampunk BuddyX child theme directory not found, skipping installation."
fi

echo "Theme patches installed successfully!"