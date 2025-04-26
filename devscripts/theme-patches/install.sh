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
    
    echo "Copying all theme files..."
    # Copy ALL files from the theme directory
    cp -r /usr/local/bin/devscripts/theme-patches/steampunk-buddyx/* /var/www/html/wp-content/themes/steampunk-buddyx/
    
    # Set proper ownership
    chown -R www-data:www-data /var/www/html/wp-content/themes/steampunk-buddyx
    chmod -R 755 /var/www/html/wp-content/themes/steampunk-buddyx
    find /var/www/html/wp-content/themes/steampunk-buddyx -type f -exec chmod 644 {} \;
    
    # Print the content of style.css to verify it's there
    echo "Verifying theme style.css contains background color rules:"
    grep -A 5 "background-color: #f5f2e9" /var/www/html/wp-content/themes/steampunk-buddyx/style.css || echo "WARNING: Background color not found in theme CSS!"
    
    # Wait for WordPress to be fully initialized before activating the theme
    echo "Waiting for WordPress to be fully initialized before activating theme..."
    
    # Activate theme with multiple approaches
    for i in 1 2 3 4 5; do
        sleep $(($i * 5))  # Increase wait time with each attempt
        echo "Attempt $i to activate steampunk-buddyx theme..."
        
        # Check WordPress status before attempting theme activation
        if wp core is-installed --path=/var/www/html --allow-root; then
            # Method 1: Direct wp-cli theme activation 
            wp theme activate steampunk-buddyx --path=/var/www/html --allow-root
            
            # Method 2: PHP code to switch theme
            wp eval '
                switch_theme("steampunk-buddyx"); 
                update_option("template", "buddyx");
                update_option("stylesheet", "steampunk-buddyx");
                update_option("theme_switched", "steampunk-buddyx");
                update_option("current_theme", "Steampunk BuddyX");
            ' --path=/var/www/html --allow-root
            
            # Method 3: Force background color in option table
            wp option add steampunk_force_background '#e6dbc9' --path=/var/www/html --allow-root || wp option update steampunk_force_background '#e6dbc9' --path=/var/www/html --allow-root
            
            # Add a persistent inline style through options table
            wp eval '
                add_option("steampunk_inline_style", "true");
                add_action("wp_head", function() {
                    echo "<style>
                        /* Main backgrounds with darker sepia tone */
                        html, body, #page, .site, #content, #primary, .buddyx-content, main#main, 
                        .site-wrapper, .entry-wrapper, .entry-content-wrapper, .entry-content, 
                        .buddyx-article, .site-wrapper-frame, body.site, body.buddyx, body.blog, 
                        body.archive, body.home, body.page, body.single-post, .background-sticky.fixed-header, 
                        .site-content-grid, article, .section-title, .white-section, .comment-body, 
                        .comment-content, .widget, .widget-area, .single article, .entry-content, 
                        .card, .post-card, .buddyx-posts-list, .buddyx-posts-list__item, .container, 
                        .container-fluid, .site-footer, .buddyx-header {
                            background-color: #e6dbc9 !important; /* Darker, more sepia tone */
                        }
                        
                        /* UI elements with slightly darker color */
                        input, select, textarea, button, .button, .dropdown-menu, .menu, .sub-menu, 
                        .site-header, .site-header-wrapper, nav, .navigation, .navbar, .site-info, 
                        .footer-widget, .footer-wrap, .buddyx-search-results, .modal-content, 
                        .popup-content, .card-header, .card-footer, .panel {
                            background-color: #d9cdb9 !important; /* Slightly darker for UI elements */
                        }
                        
                        /* White elements should be off-white sepia */
                        .white, .bg-white, .background-white, [class*=\"bg-light\"], .light-bg, 
                        .buddyx-section--white, .buddyx-content--white, .wp-block-table, 
                        .wp-block-code, pre, code, .table, table, blockquote, .wp-block-cover, 
                        .alignwide, .alignfull, .buddyx-page-header {
                            background-color: #f0e8d9 !important; /* Off-white with sepia tone */
                            color: #3d3223 !important; /* Darker brown text */
                        }
                        
                        /* Extra specificity for stubborn elements */
                        [style*=\"background-color\"], [style*=\"background: white\"], [style*=\"background: #fff\"], 
                        [style*=\"background: rgb(255\"], [style*=\"background:#fff\"], 
                        [style*=\"background-color: white\"], [style*=\"background-color: #fff\"] {
                            background-color: #e6dbc9 !important;
                        }
                    </style>";
                }, 999999);
            ' --path=/var/www/html --allow-root
            
            # Verify the theme is active
            ACTIVE_THEME=$(wp theme list --status=active --field=name --path=/var/www/html --allow-root)
            echo "Currently active theme: $ACTIVE_THEME"
            
            if [ "$ACTIVE_THEME" = "steampunk-buddyx" ]; then
                echo "✅ Successfully activated steampunk-buddyx theme on attempt $i"
                break
            else
                echo "⚠️ Theme activation verification failed on attempt $i, theme is: $ACTIVE_THEME"
            fi
        else
            echo "⚠️ WordPress core not fully installed yet, waiting longer..."
        fi
    done
    
    # Make sure Classic Widgets plugin is active
    wp plugin activate classic-widgets --path=/var/www/html --allow-root || true
    
    # CRITICAL: Ensure BuddyPress components are activated
    # The theme activation might reset these components, so we need to reactivate them
    echo "Ensuring BuddyPress components remain activated after theme setup..."
    
    # First make sure BuddyPress is active
    wp plugin is-active buddypress --path=/var/www/html --allow-root || wp plugin activate buddypress --path=/var/www/html --allow-root
    
    # Force BuddyPress to refresh after theme activation
    wp cache flush --path=/var/www/html --allow-root || true
    
    # Critical components - explicitly activate each one
    echo "Reactivating critical BuddyPress components..."
    wp bp component activate friends --path=/var/www/html --allow-root && echo "✅ Friend requests component activated"
    wp bp component activate messages --path=/var/www/html --allow-root && echo "✅ Private messaging component activated"
    wp bp component activate groups --path=/var/www/html --allow-root && echo "✅ User groups component activated"
    wp bp component activate blogs --path=/var/www/html --allow-root && echo "✅ Site tracking component activated"
    
    # Also activate remaining components
    for component in xprofile settings members activity notifications; do
        wp bp component activate $component --path=/var/www/html --allow-root
        echo "✅ Activated BuddyPress component: $component"
    done
    
    # Set via options table for extra reliability
    echo "Securing BuddyPress component state in the database..."
    wp eval '
    // Define all required components
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
    
    // Get current components and merge with required ones
    $current = get_option("bp-active-components", array());
    $updated = array_merge($current, $required_components);
    
    // Update option multiple ways to ensure it persists
    update_option("bp-active-components", $updated);
    update_option("bp-active-components", $updated, "yes");
    
    // Clear BP cache
    if (function_exists("wp_cache_delete")) {
        wp_cache_delete("bp_active_components", "bp");
    }
    ' --path=/var/www/html --allow-root
    
    # Verify components are active
    echo "Verifying BuddyPress components..."
    INACTIVE_COUNT=$(wp bp component list --status=inactive --format=count --path=/var/www/html --allow-root || echo 0)
    if [ "$INACTIVE_COUNT" -gt 0 ]; then
        echo "⚠️ Warning: $INACTIVE_COUNT components are still inactive!"
        # Show which ones
        wp bp component list --status=inactive --path=/var/www/html --allow-root || true
    else
        echo "✅ All BuddyPress components are now active!"
    fi
    
    echo "✅ Steampunk BuddyX child theme installed and activation process complete"
else
    echo "⚠️ Warning: Steampunk BuddyX child theme directory not found, skipping installation."
fi

echo "Theme patches installed successfully!"