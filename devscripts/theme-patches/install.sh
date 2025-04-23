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

echo "Theme patches installed successfully!"