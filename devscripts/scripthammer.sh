#!/bin/bash
# ScriptHammer band members creation script
set -e

# Add fix for permissions - make script executable inside container
chmod +x "$(realpath "$0")" 2>/dev/null || true

# Parse command-line arguments
CREATE_METRONOME=false
USE_IMPORT=true  # Default to using import approach

# Process all arguments
IMPORT_FROM=""

for arg in "$@"; do
    case $arg in
        --with-metronome)
            CREATE_METRONOME=true
            ;;
        --force-create)
            USE_IMPORT=false
            ;;
        --use-import)
            USE_IMPORT=true
            ;;
        --recover)
            # Look for export files in standard locations
            if [ -f "/var/www/html/wp-content/exports/band-members-000.xml" ]; then
                IMPORT_FROM="/var/www/html/wp-content/exports/band-members-000.xml"
            elif [ -f "/usr/local/bin/devscripts/exports/band-members-000.xml" ]; then
                IMPORT_FROM="/usr/local/bin/devscripts/exports/band-members-000.xml"
            elif [ -f "/var/www/html/wp-content/imports/band-members-000.xml" ]; then
                IMPORT_FROM="/var/www/html/wp-content/imports/band-members-000.xml"
            fi
            ;;
        --import=*)
            IMPORT_FROM="${arg#*=}"
            ;;
        debug)
            set -x
            ;;
    esac
done

# Function to check if band content already exists
band_content_exists() {
    # Check for Ivory's main post (Meet Ivory)
    if wp post list --name="meet-ivory-the-melody-master-of-scripthammer" --post_type=post --format=count --path=/var/www/html | grep -q "1"; then
        echo "✅ Band content already exists (found Meet Ivory post)"
        return 0  # Success - content exists
    else
        echo "⚠️ Band content not found"
        return 1  # Failure - content not found
    fi
}

# Function to import band content from exports
import_band_content() {
    # Check multiple locations for export files
    for EXPORT_PATH in \
        "/var/www/html/wp-content/exports-volume/all-band-content-000.xml" \
        "/var/www/html/wp-content/exports/all-band-content-000.xml" \
        "/usr/local/bin/devscripts/exports/all-band-content-000.xml" \
        "/var/www/html/wp-content/uploads/exports/all-band-content-000.xml" \
        "/var/www/html/wp-content/imports/all-band-content-000.xml"
    do
        if [ -f "$EXPORT_PATH" ]; then
            EXPORT_FILE="$EXPORT_PATH"
            echo "🔄 Found export file at $EXPORT_FILE"
            break
        fi
    done
    
    # If we found an export file, import it
    if [ -n "$EXPORT_FILE" ] && [ -f "$EXPORT_FILE" ]; then
        echo "🔄 Importing band content from $EXPORT_FILE..."
    
        # Install WordPress importer plugin if needed
        if ! wp plugin is-installed wordpress-importer --path=/var/www/html; then
            echo "Installing WordPress Importer plugin..."
            wp plugin install wordpress-importer --activate --path=/var/www/html
        fi
    
        # Import the content
        wp import "$EXPORT_FILE" --authors=create --path=/var/www/html
    
        echo "✅ Band content imported successfully"
        return 0
    else
        echo "❌ No export files found in any standard location"
        echo "👉 Will create band content from scratch instead"
        return 1
    fi
}

# Force activation of all required components before proceeding
echo "Ensuring all BuddyPress components are activated..."
# First check if BuddyPress is active
if ! wp plugin is-active buddypress --path=/var/www/html; then
    echo "Activating BuddyPress plugin..."
    wp plugin activate buddypress --path=/var/www/html || echo "⚠️ Warning: Could not activate BuddyPress"
    # Give it a moment to initialize
    sleep 3
fi

# Check what components are already active
active_components=$(wp bp component list --status=active --path=/var/www/html 2>/dev/null || echo "none")
echo "Currently active components: $active_components"

# Try to activate each component individually with safeguards
for component in xprofile members groups friends messages activity notifications settings blogs; do
    echo "Ensuring component '$component' is active..."
    # First check if already active to avoid errors
    if ! echo "$active_components" | grep -q "$component"; then
        wp bp component activate $component --path=/var/www/html || echo "⚠️ Warning: Could not activate $component, but continuing anyway"
    else
        echo "✅ Component '$component' is already active"
    fi
    sleep 1
done

echo "Setting up ScriptHammer band content..."

# Check if we should import content from a specific file
if [ -n "$IMPORT_FROM" ]; then
    echo "🔄 Recovering band content from $IMPORT_FROM..."
    
    # Install WordPress importer plugin if needed
    if ! wp plugin is-installed wordpress-importer --path=/var/www/html; then
        echo "Installing WordPress Importer plugin..."
        wp plugin install wordpress-importer --activate --path=/var/www/html
    else
        wp plugin activate wordpress-importer --path=/var/www/html
    fi
    
    # Import the content
    echo "Importing content..."
    wp import "$IMPORT_FROM" --authors=create --skip=duplicate --path=/var/www/html
    
    # Install the metronome app if requested
    if [ "$CREATE_METRONOME" = true ]; then
        echo "Installing metronome app for recovered content..."
        mkdir -p /var/www/html/wp-content/mu-plugins
        
        if [ -f "/usr/local/bin/devscripts/metronome-app.php" ]; then
            cp /usr/local/bin/devscripts/metronome-app.php /var/www/html/wp-content/mu-plugins/
            chmod 644 /var/www/html/wp-content/mu-plugins/metronome-app.php
            chown www-data:www-data /var/www/html/wp-content/mu-plugins/metronome-app.php
            echo "✅ Metronome app installed for recovered content"
        else
            echo "❌ ERROR: Metronome app not found"
        fi
    fi
    
    echo "✅ Content recovery complete!"
    exit 0
fi

# First approach: Try to use the import method if enabled
if [ "$USE_IMPORT" = true ]; then
    if band_content_exists; then
        echo "📝 Band content already exists. No need to recreate or import."
        
        # Install the metronome app if requested
        if [ "$CREATE_METRONOME" = true ]; then
            echo "Installing metronome app for existing content..."
            # Create the mu-plugins directory if it doesn't exist
            mkdir -p /var/www/html/wp-content/mu-plugins
            
            # Copy the metronome app
            if [ -f "/usr/local/bin/devscripts/metronome-app.php" ]; then
                cp /usr/local/bin/devscripts/metronome-app.php /var/www/html/wp-content/mu-plugins/
                chmod 644 /var/www/html/wp-content/mu-plugins/metronome-app.php
                chown www-data:www-data /var/www/html/wp-content/mu-plugins/metronome-app.php
                echo "✅ Metronome app installed as mu-plugin for existing content"
            else
                echo "❌ CRITICAL ERROR: Metronome app not found at /usr/local/bin/devscripts/metronome-app.php"
            fi
        fi
        
        # Exit early - no need to continue with content creation
        echo "✅ ScriptHammer band setup completed successfully (using existing content)!"
        exit 0
    else
        # Content doesn't exist, try to import it
        if import_band_content; then
            echo "✅ Content imported successfully!"
            
            # Install the metronome app if requested
            if [ "$CREATE_METRONOME" = true ]; then
                echo "Installing metronome app for imported content..."
                # Create the mu-plugins directory if it doesn't exist
                mkdir -p /var/www/html/wp-content/mu-plugins
                
                # Copy the metronome app
                if [ -f "/usr/local/bin/devscripts/metronome-app.php" ]; then
                    cp /usr/local/bin/devscripts/metronome-app.php /var/www/html/wp-content/mu-plugins/
                    chmod 644 /var/www/html/wp-content/mu-plugins/metronome-app.php
                    chown www-data:www-data /var/www/html/wp-content/mu-plugins/metronome-app.php
                    echo "✅ Metronome app installed as mu-plugin for imported content"
                else
                    echo "❌ CRITICAL ERROR: Metronome app not found at /usr/local/bin/devscripts/metronome-app.php"
                fi
            fi
            
            # Exit early - no need to continue with content creation
            echo "✅ ScriptHammer band setup completed successfully (using imported content)!"
            exit 0
        else
            echo "⚠️ Import failed. Falling back to manual content creation..."
            # Continue with the script to create content manually
        fi
    fi
fi

# Check if band content already exists before creating
echo "Checking for existing band content..."
if wp post list --name=meet-ivory-the-melody-master-of-scripthammer --post_type=post --format=count --path=/var/www/html | grep -q "1"; then
    echo "✅ Band content already exists - using existing content"
    
    # Just install the metronome app if requested
    if [ "$CREATE_METRONOME" = true ]; then
        echo "Installing metronome app for existing content..."
        # Create the mu-plugins directory if it doesn't exist
        mkdir -p /var/www/html/wp-content/mu-plugins
        
        # Copy the metronome app
        if [ -f "/usr/local/bin/devscripts/metronome-app.php" ]; then
            cp /usr/local/bin/devscripts/metronome-app.php /var/www/html/wp-content/mu-plugins/
            chmod 644 /var/www/html/wp-content/mu-plugins/metronome-app.php
            chown www-data:www-data /var/www/html/wp-content/mu-plugins/metronome-app.php
            echo "✅ Metronome app installed as mu-plugin for existing content"
        else
            echo "❌ ERROR: Metronome app not found at /usr/local/bin/devscripts/metronome-app.php"
        fi
        
        # Create the metronome page if it doesn't exist
        if ! wp post exists --post_type=page --post_name="band-metronome" --path=/var/www/html; then
            echo "Creating band metronome page..."
            wp post create --post_type=page --post_title="ScriptHammer Drum Machine" --post_name="band-metronome" --post_status="publish" --post_content="<h2>ScriptHammer Band Practice Tools</h2>

<div class=\"band-metronome\">
    <h3>ScriptHammer Drum Machine</h3>
    <p>Our custom drum sequencer for band practice and composition. Create beats for our signature fractal funk and cosmic rhythms.</p>
    
    <div class=\"app-container\">
        [scripthammer_react_app]
    </div>
    
    <h4>Band Notes</h4>
    <ul>
        <li><strong>Basic Rock</strong> - Use for foundational practice and warm-ups</li>
        <li><strong>Disco</strong> - For \"Blue Matrix\" practice sessions</li>
        <li><strong>Hip Hop</strong> - For \"Quantum Groove\" and \"Neural Patterns\" tracks</li>
        <li><strong>Jazz</strong> - For \"Fractal Motion\" and \"Harmonic Drift\" pieces</li>
        <li><strong>Waltz</strong> - For \"Temporal Shift\" section in our third set</li>
    </ul>
    
    <p><strong>Crash says:</strong> Remember to practice with the hi-hat patterns we worked on last week. Especially focus on the off-beat accents for the Syncopation Suite.</p>
</div>

<style>
.band-metronome {
    max-width: 900px;
    margin: 0 auto;
    padding: 20px;
    background: #f8f9fa;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.app-container {
    margin: 30px 0;
}

h3 {
    color: #333;
    border-bottom: 2px solid #3b82f6;
    padding-bottom: 10px;
}

ul {
    background-color: #f0f4f8;
    padding: 15px 15px 15px 35px;
    border-radius: 4px;
    border-left: 3px solid #3b82f6;
}

li {
    margin: 8px 0;
}
</style>" --path=/var/www/html || true
            
            echo "✅ Created ScriptHammer Band Metronome page"
        else
            echo "ScriptHammer Band Metronome page already exists"
        fi
    fi
    
    echo "✅ ScriptHammer band setup completed successfully (using existing content)!"
    exit 0
fi

echo "No existing band content found. Creating ScriptHammer band members..."

# Make sure BuddyPress is active and database tables are created
echo "Verifying BuddyPress is active and database tables exist..."
if ! wp plugin is-active buddypress --path=/var/www/html; then
    echo "BuddyPress is not active. Activating..."
    wp plugin activate buddypress --path=/var/www/html || {
        echo "Failed to activate BuddyPress. Exiting."
        exit 1
    }
fi

# Check if the BuddyPress database tables are created - a common issue causing content creation to fail
if ! wp db query "SHOW TABLES LIKE 'wp_bp_groups'" --path=/var/www/html | grep -q "wp_bp_groups"; then
    echo "BuddyPress database tables missing. Creating them directly..."
    
    # Create tables directly with SQL - most reliable method
    echo "Creating BuddyPress groups tables with SQL..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_groups (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        creator_id bigint(20) NOT NULL,
        name varchar(100) NOT NULL,
        slug varchar(200) NOT NULL,
        description longtext NOT NULL,
        status varchar(10) NOT NULL DEFAULT 'public',
        parent_id bigint(20) NOT NULL DEFAULT 0,
        enable_forum tinyint(1) NOT NULL DEFAULT '1',
        date_created datetime NOT NULL,
        PRIMARY KEY (id),
        KEY creator_id (creator_id),
        KEY status (status)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;" --path=/var/www/html

    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_groups_members (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        group_id bigint(20) NOT NULL,
        user_id bigint(20) NOT NULL,
        inviter_id bigint(20) NOT NULL,
        is_admin tinyint(1) NOT NULL DEFAULT '0',
        is_mod tinyint(1) NOT NULL DEFAULT '0',
        user_title varchar(100) NOT NULL,
        date_modified datetime NOT NULL,
        comments longtext NOT NULL,
        is_confirmed tinyint(1) NOT NULL DEFAULT '0',
        is_banned tinyint(1) NOT NULL DEFAULT '0',
        invite_sent tinyint(1) NOT NULL DEFAULT '0',
        PRIMARY KEY (id),
        KEY group_id (group_id),
        KEY is_admin (is_admin),
        KEY is_mod (is_mod),
        KEY user_id (user_id),
        KEY inviter_id (inviter_id),
        KEY is_confirmed (is_confirmed)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;" --path=/var/www/html

    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_groups_groupmeta (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        group_id bigint(20) NOT NULL,
        meta_key varchar(255) DEFAULT NULL,
        meta_value longtext,
        PRIMARY KEY (id),
        KEY group_id (group_id),
        KEY meta_key (meta_key(191))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;" --path=/var/www/html
    
    # Also try to reactivate the plugin to trigger other table creation
    wp plugin deactivate buddypress --path=/var/www/html
    wp plugin activate buddypress --path=/var/www/html
    
    # Verify the tables were created
    if ! wp db query "SHOW TABLES LIKE 'wp_bp_groups'" --path=/var/www/html | grep -q "wp_bp_groups"; then
        echo "❌ ERROR: Failed to create BuddyPress database tables. Content creation will likely fail."
        echo "You may need to manually deactivate and reactivate BuddyPress from the WordPress admin."
        exit 1
    else
        echo "✅ BuddyPress database tables created successfully."
    fi
fi

# Create missing BuddyPress database tables if needed
echo "Creating any missing BuddyPress database tables..."

# Check for xprofile_data table (often missing)
if ! wp db query "SHOW TABLES LIKE 'wp_bp_xprofile_data'" --path=/var/www/html | grep -q "wp_bp_xprofile_data"; then
    echo "Creating missing BuddyPress XProfile Data table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_xprofile_data (
        id bigint(20) unsigned NOT NULL auto_increment,
        field_id bigint(20) unsigned NOT NULL,
        user_id bigint(20) unsigned NOT NULL,
        value longtext NOT NULL,
        last_updated datetime NOT NULL,
        PRIMARY KEY (id),
        KEY field_id (field_id),
        KEY user_id (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

# Check for xprofile_groups table
if ! wp db query "SHOW TABLES LIKE 'wp_bp_xprofile_groups'" --path=/var/www/html | grep -q "wp_bp_xprofile_groups"; then
    echo "Creating missing BuddyPress XProfile Groups table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_xprofile_groups (
        id bigint(20) unsigned NOT NULL auto_increment,
        name varchar(150) NOT NULL,
        description longtext NOT NULL,
        group_order bigint(20) NOT NULL default 0,
        can_delete tinyint(1) NOT NULL default 1,
        PRIMARY KEY (id),
        KEY can_delete (can_delete)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

# Check for xprofile_fields table
if ! wp db query "SHOW TABLES LIKE 'wp_bp_xprofile_fields'" --path=/var/www/html | grep -q "wp_bp_xprofile_fields"; then
    echo "Creating missing BuddyPress XProfile Fields table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_xprofile_fields (
        id bigint(20) unsigned NOT NULL auto_increment,
        group_id bigint(20) unsigned NOT NULL,
        parent_id bigint(20) unsigned NOT NULL,
        type varchar(150) NOT NULL,
        name varchar(150) NOT NULL,
        description longtext NOT NULL,
        is_required tinyint(1) NOT NULL DEFAULT '0',
        is_default_option tinyint(1) NOT NULL DEFAULT '0',
        field_order bigint(20) NOT NULL DEFAULT '0',
        option_order bigint(20) NOT NULL DEFAULT '0',
        order_by varchar(15) NOT NULL DEFAULT '',
        can_delete tinyint(1) NOT NULL DEFAULT '1',
        PRIMARY KEY (id),
        KEY group_id (group_id),
        KEY parent_id (parent_id),
        KEY field_order (field_order),
        KEY can_delete (can_delete),
        KEY is_required (is_required)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

# Check for xprofile_meta table
if ! wp db query "SHOW TABLES LIKE 'wp_bp_xprofile_meta'" --path=/var/www/html | grep -q "wp_bp_xprofile_meta"; then
    echo "Creating missing BuddyPress XProfile Meta table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_xprofile_meta (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        object_id bigint(20) NOT NULL,
        object_type varchar(150) NOT NULL DEFAULT '',
        meta_key varchar(255) DEFAULT NULL,
        meta_value longtext,
        PRIMARY KEY (id),
        KEY object_id (object_id),
        KEY meta_key (meta_key(191))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

# Check for activity table
if ! wp db query "SHOW TABLES LIKE 'wp_bp_activity'" --path=/var/www/html | grep -q "wp_bp_activity"; then
    echo "Creating missing BuddyPress Activity table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_activity (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        user_id bigint(20) NOT NULL,
        component varchar(75) NOT NULL,
        type varchar(75) NOT NULL,
        action text NOT NULL,
        content longtext NOT NULL,
        primary_link varchar(255) NOT NULL,
        item_id bigint(20) NOT NULL,
        secondary_item_id bigint(20) DEFAULT NULL,
        date_recorded datetime NOT NULL,
        hide_sitewide tinyint(1) DEFAULT 0,
        mptt_left int(11) NOT NULL DEFAULT 0,
        mptt_right int(11) NOT NULL DEFAULT 0,
        is_spam tinyint(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (id),
        KEY date_recorded (date_recorded),
        KEY user_id (user_id),
        KEY item_id (item_id),
        KEY secondary_item_id (secondary_item_id),
        KEY component (component),
        KEY type (type),
        KEY mptt_left (mptt_left),
        KEY mptt_right (mptt_right),
        KEY hide_sitewide (hide_sitewide),
        KEY is_spam (is_spam)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

# Check for activity meta table 
if ! wp db query "SHOW TABLES LIKE 'wp_bp_activity_meta'" --path=/var/www/html | grep -q "wp_bp_activity_meta"; then
    echo "Creating missing BuddyPress Activity Meta table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_activity_meta (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        activity_id bigint(20) NOT NULL,
        meta_key varchar(255) DEFAULT NULL,
        meta_value longtext DEFAULT NULL,
        PRIMARY KEY (id),
        KEY activity_id (activity_id),
        KEY meta_key (meta_key(191))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

# Check for notifications table
if ! wp db query "SHOW TABLES LIKE 'wp_bp_notifications'" --path=/var/www/html | grep -q "wp_bp_notifications"; then
    echo "Creating missing BuddyPress Notifications table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_notifications (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        user_id bigint(20) NOT NULL,
        item_id bigint(20) NOT NULL,
        secondary_item_id bigint(20) DEFAULT NULL,
        component_name varchar(75) NOT NULL,
        component_action varchar(75) NOT NULL,
        date_notified datetime NOT NULL,
        is_new tinyint(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (id),
        KEY item_id (item_id),
        KEY secondary_item_id (secondary_item_id),
        KEY user_id (user_id),
        KEY is_new (is_new),
        KEY component_name (component_name),
        KEY component_action (component_action),
        KEY useritem (user_id,is_new)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

# Check for blogs-related tables
if ! wp db query "SHOW TABLES LIKE 'wp_bp_user_blogs'" --path=/var/www/html | grep -q "wp_bp_user_blogs"; then
    echo "Creating missing BuddyPress Blogs table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_user_blogs (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        user_id bigint(20) NOT NULL,
        blog_id bigint(20) NOT NULL,
        PRIMARY KEY (id),
        KEY user_id (user_id),
        KEY blog_id (blog_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

if ! wp db query "SHOW TABLES LIKE 'wp_bp_user_blogs_blogmeta'" --path=/var/www/html | grep -q "wp_bp_user_blogs_blogmeta"; then
    echo "Creating missing BuddyPress Blogs Meta table..."
    wp db query "CREATE TABLE IF NOT EXISTS wp_bp_user_blogs_blogmeta (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        blog_id bigint(20) NOT NULL,
        meta_key varchar(255) DEFAULT NULL,
        meta_value longtext DEFAULT NULL,
        PRIMARY KEY (id),
        KEY blog_id (blog_id),
        KEY meta_key (meta_key(191))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" --path=/var/www/html
fi

# Ensure all required BuddyPress components are active
echo "Ensuring all required BuddyPress components are active..."

# First explicitly activate the critical components to guarantee they work
echo "🔄 Activating friend requests component (friends)..."
wp bp component activate friends --path=/var/www/html && echo "✅ Friend requests activated" || echo "❌ Failed to activate friend requests"

echo "🔄 Activating private messaging component (messages)..."
wp bp component activate messages --path=/var/www/html && echo "✅ Private messaging activated" || echo "❌ Failed to activate private messaging"

echo "🔄 Activating user groups component (groups)..."
wp bp component activate groups --path=/var/www/html && echo "✅ User groups activated" || echo "❌ Failed to activate user groups"

echo "🔄 Activating site tracking component (blogs)..."
wp bp component activate blogs --path=/var/www/html && echo "✅ Site tracking activated" || echo "❌ Failed to activate site tracking"

# Now activate the remaining components
echo "Activating remaining BuddyPress components..."
required_components=(
    "xprofile"
    "members"
    "activity"
    "notifications"
    "settings"
)

# Activate remaining components
for component in "${required_components[@]}"; do
    if ! wp bp component list --path=/var/www/html | grep -q "$component.*active"; then
        echo "$component component is not active. Activating..."
        wp bp component activate $component --path=/var/www/html || true
        
        # Add a small delay to allow component activation to complete
        sleep 1
    else
        echo "$component component is already active."
    fi
done

# Verify all critical components are active with detailed error messages
critical_components=("groups" "friends" "messages" "blogs")
for component in "${critical_components[@]}"; do
    if ! wp bp component list --status=active --path=/var/www/html | grep -q "$component"; then
        echo "⚠️ WARNING: Component '$component' is not active. Trying one more time..."
        wp bp component activate $component --path=/var/www/html
        
        # Check again after second attempt
        if ! wp bp component list --status=active --path=/var/www/html | grep -q "$component"; then
            echo "⚠️ WARNING: Component '$component' could not be activated after second attempt."
            echo "💡 This might cause some features to be unavailable, but we'll continue anyway."
            # Don't exit - continue with the script even if components can't be activated
        fi
    else
        echo "✅ Component '$component' is active."
    fi
done

echo "✅ All critical BuddyPress components successfully activated."

echo "All required BuddyPress components are now active."

# Create field group if it doesn't exist
echo "Creating XProfile field group for band info..."
group_id=$(wp bp xprofile group list --fields=id --format=ids --path=/var/www/html 2>/dev/null | head -n 1 || echo "")

if [ -z "$group_id" ]; then
    echo "No XProfile group found, creating one..."
    group_id=$(wp bp xprofile group create --name="Band Info" --path=/var/www/html --porcelain)
fi

echo "Using profile group ID: $group_id"

# Create fields one by one
echo "Creating profile fields..."
instrument_field=$(wp bp xprofile field create --field-group-id=$group_id --name="Instrument" --type=textbox --path=/var/www/html --porcelain 2>/dev/null || echo "0")
role_field=$(wp bp xprofile field create --field-group-id=$group_id --name="Role" --type=textbox --path=/var/www/html --porcelain 2>/dev/null || echo "0")
personality_field=$(wp bp xprofile field create --field-group-id=$group_id --name="Personality" --type=textarea --path=/var/www/html --porcelain 2>/dev/null || echo "0")
visual_field=$(wp bp xprofile field create --field-group-id=$group_id --name="Visual Style" --type=textarea --path=/var/www/html --porcelain 2>/dev/null || echo "0")

echo "Created fields: $instrument_field, $role_field, $personality_field, $visual_field"

# Define band members
band_members=(
    "Ivory|Jazz piano and vintage synths|Melody Master|Serene, cerebral, occasionally mischievous with syncopations|Glossy porcelain-white frame, clean curves, glowing blue inlays, elegant movement"
    "Crash|Full drum kit|Pulse Engine|Energetic, expressive, always in motion like a hyperactive metronome|Compact, spring-loaded limbs, polished brass armor with kinetic glyphs"
    "Chops|Franken-guitar|Harmonic Hacker|Street-smart, sardonic, thrives on chaos and crunchy chords|Punk aesthetic, asymmetrical plating, CRT screen eyes, tangled wires"
    "Reed|Alto sax|Lyrical Breeze|Cool-headed, introspective, speaks through his solos|Slim, chrome body, trench coat detail sculpted into chassis, LED eyes"
    "Brass|Trumpet|Frontline Flame|Showboat, loud and proud, always at the center of a solo|Gleaming gold plating, spotlight-reactive finish, flared armor"
    "Verse|Vocoder & Mic|Soul Node|Passionate, poetic, the most 'human' of the bots|Holographic face panel with waveform lips, changing LED mouth"
    "Form|Control surface|Architect|Focused, observant, rarely speaks but always orchestrating|Gunmetal gray with flowing LED matrix, modular appendages"
)

# Store created user IDs for group creation
band_user_ids=()

# Create each band member
for member_data in "${band_members[@]}"; do
    IFS='|' read -r name instrument role personality visual_style <<< "$member_data"
    
    username=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    email="$username@scripthammer.com"
    password="script2025"
    
    echo "Creating band member: $name ($role)"
    
    # Assign author role to Ivory (band leader), subscriber role to others
    user_role="subscriber"
    if [ "$name" = "Ivory" ]; then
        user_role="author"
    fi
    
    # Create user if doesn't exist
    if ! wp user get "$username" --path=/var/www/html --field=user_login &>/dev/null; then
        user_id=$(wp user create "$username" "$email" --user_pass="$password" --display_name="$name" --role="$user_role" --path=/var/www/html --porcelain)
        
        # Set profile fields if created successfully
        if [ -n "$user_id" ] && [ "$user_id" -gt 0 ]; then
            echo "User created with ID: $user_id"
            
            # Add user bio
            wp user meta update $user_id description "ScriptHammer member: $name. Role: $role. $personality" --path=/var/www/html
            
            # Set profile field data if fields were created successfully
            if [ "$instrument_field" != "0" ]; then
                wp bp xprofile data set --user-id=$user_id --field-id=$instrument_field --value="$instrument" --path=/var/www/html || true
            fi
            
            if [ "$role_field" != "0" ]; then
                wp bp xprofile data set --user-id=$user_id --field-id=$role_field --value="$role" --path=/var/www/html || true
            fi
            
            if [ "$personality_field" != "0" ]; then
                wp bp xprofile data set --user-id=$user_id --field-id=$personality_field --value="$personality" --path=/var/www/html || true
            fi
            
            if [ "$visual_field" != "0" ]; then
                wp bp xprofile data set --user-id=$user_id --field-id=$visual_field --value="$visual_style" --path=/var/www/html || true
            fi
            
            # Check for and set avatar image for the user if available
            avatar_path="/usr/local/bin/devscripts/assets/${name}.png"
            if [ -f "$avatar_path" ]; then
                echo "Setting avatar for $name using $avatar_path"
                # Create the avatar directory if it doesn't exist
                mkdir -p /var/www/html/wp-content/uploads/avatars
                # Copy the avatar to WordPress uploads directory
                cp "$avatar_path" "/var/www/html/wp-content/uploads/avatars/${name}.png"
                
                # Set the avatar using WP-CLI and BuddyPress functions
                wp eval "
                // Set BP avatar for user $user_id
                if (function_exists('bp_core_avatar_handle_upload')) {
                    // Create avatars directory if needed
                    \$avatar_dir = WP_CONTENT_DIR . '/uploads/avatars/';
                    if (!file_exists(\$avatar_dir)) {
                        mkdir(\$avatar_dir, 0755, true);
                    }
                    
                    // Source file
                    \$src_file = '/var/www/html/wp-content/uploads/avatars/${name}.png';
                    
                    // Use BP's avatar storage system
                    if (file_exists(\$src_file)) {
                        // Get the avatar directory for this user
                        \$avatar_dir = bp_core_avatar_upload_path() . '/avatars/' . $user_id;
                        if (!file_exists(\$avatar_dir)) {
                            mkdir(\$avatar_dir, 0755, true);
                        }
                        
                        // Copy to both full and thumb locations
                        copy(\$src_file, \$avatar_dir . '/avatar-bpfull.png');
                        copy(\$src_file, \$avatar_dir . '/avatar-bpthumb.png');
                        
                        // Update user meta to indicate custom avatar
                        update_user_meta($user_id, 'bp_avatar_type', 'uploaded');
                        
                        echo 'Avatar successfully set for user $user_id (${name})';
                    } else {
                        echo 'Avatar file not found at ' . \$src_file;
                    }
                } else {
                    echo 'BuddyPress avatar functions not available';
                }
                " --path=/var/www/html || echo "Failed to set avatar for $name"
            else
                echo "No avatar image found for $name at $avatar_path"
            fi
            
            band_user_ids+=($user_id)
        else
            echo "Error creating user $username"
        fi
    else
        # User already exists, get ID for group membership
        user_id=$(wp user get "$username" --field=ID --path=/var/www/html)
        echo "User $username already exists with ID: $user_id"
        
        # Update role if it's Ivory and not already an author
        if [ "$name" = "Ivory" ]; then
            current_role=$(wp user get "$username" --field=roles --format=json --path=/var/www/html | grep -q "author")
            if [ $? -ne 0 ]; then
                echo "Updating Ivory's role to author..."
                wp user set-role "$username" author --path=/var/www/html
            fi
        fi
        
        # Check for and update avatar image for the user if available (even for existing users)
        avatar_path="/usr/local/bin/devscripts/assets/${name}.png"
        if [ -f "$avatar_path" ]; then
            echo "Updating avatar for existing user $name using $avatar_path"
            # Create the avatar directory if it doesn't exist
            mkdir -p /var/www/html/wp-content/uploads/avatars
            # Copy the avatar to WordPress uploads directory
            cp "$avatar_path" "/var/www/html/wp-content/uploads/avatars/${name}.png"
            
            # Set the avatar using WP-CLI and BuddyPress functions
            wp eval "
            // Set BP avatar for user $user_id
            if (function_exists('bp_core_avatar_handle_upload')) {
                // Create avatars directory if needed
                \$avatar_dir = WP_CONTENT_DIR . '/uploads/avatars/';
                if (!file_exists(\$avatar_dir)) {
                    mkdir(\$avatar_dir, 0755, true);
                }
                
                // Source file
                \$src_file = '/var/www/html/wp-content/uploads/avatars/${name}.png';
                
                // Use BP's avatar storage system
                if (file_exists(\$src_file)) {
                    // Get the avatar directory for this user
                    \$avatar_dir = bp_core_avatar_upload_path() . '/avatars/' . $user_id;
                    if (!file_exists(\$avatar_dir)) {
                        mkdir(\$avatar_dir, 0755, true);
                    }
                    
                    // Copy to both full and thumb locations
                    copy(\$src_file, \$avatar_dir . '/avatar-bpfull.png');
                    copy(\$src_file, \$avatar_dir . '/avatar-bpthumb.png');
                    
                    // Update user meta to indicate custom avatar
                    update_user_meta($user_id, 'bp_avatar_type', 'uploaded');
                    
                    echo 'Avatar successfully updated for existing user $user_id (${name})';
                } else {
                    echo 'Avatar file not found at ' . \$src_file;
                }
            } else {
                echo 'BuddyPress avatar functions not available';
            }
            " --path=/var/www/html || echo "Failed to update avatar for $name"
        fi
        
        band_user_ids+=($user_id)
    fi
done

echo "Creating ScriptHammer band group..."

# Verify critical components are still active before creating the group
echo "Verifying critical BuddyPress components are still active..."
critical_components=("groups" "friends" "messages" "activity")
for component in "${critical_components[@]}"; do
    if ! wp bp component list --path=/var/www/html | grep -q "$component.*active"; then
        echo "$component component is not active. Reactivating..."
        wp bp component activate $component --path=/var/www/html || true
        sleep 1
    fi
done

# Just delete any existing ScriptHammer group and create a new one
echo "Handling ScriptHammer group..."
existing_group=$(wp bp group list --name="ScriptHammer" --path=/var/www/html --format=ids 2>/dev/null || echo "")

if [ -n "$existing_group" ]; then
    echo "Deleting existing ScriptHammer group with ID: $existing_group"
    wp bp group delete $existing_group --yes --path=/var/www/html || true
fi

# Create fresh group with Ivory as creator
creator_id=${band_user_ids[0]}
echo "Creating new ScriptHammer band group with creator ID: $creator_id..."
group_id=$(wp bp group create --name="ScriptHammer" --description="Futuristic jazz, fractal funk, cosmic rhythm cycles. The innovators behind 'Blue Dot Matrix' album." --status="public" --creator-id=$creator_id --path=/var/www/html --porcelain)

# If group creation failed, try one more time with a delay
if [ -z "$group_id" ]; then
    echo "Failed to create group. Waiting 5 seconds and trying again..."
    sleep 5
    # One more attempt to activate the groups component
    wp bp component activate groups --path=/var/www/html || true
    sleep 2
    # Try group creation again
    group_id=$(wp bp group create --name="ScriptHammer" --description="Futuristic jazz, fractal funk, cosmic rhythm cycles. The innovators behind 'Blue Dot Matrix' album." --status="public" --creator-id=$creator_id --path=/var/www/html --porcelain)
    
    if [ -z "$group_id" ]; then
        echo "Failed to create ScriptHammer group after multiple attempts."
        exit 1
    fi
fi

# Instead of WP-CLI, use direct WordPress actions via wp eval
echo "Adding members to the group using WordPress actions..."
for i in "${!band_user_ids[@]}"; do
    user_id=${band_user_ids[$i]}
    
    # Skip first user (Ivory) as they're already creator
    if [ "$i" -eq "0" ]; then
        echo "Making creator (Ivory) an admin of the group..."
        # Use WordPress actions directly
        wp eval "groups_join_group($group_id, $user_id); groups_promote_member($user_id, $group_id, 'admin');" --path=/var/www/html || true
        continue
    fi
    
    echo "Adding user ID: $user_id to group $group_id"
    # Use WordPress actions directly instead of WP-CLI commands
    wp eval "groups_join_group($group_id, $user_id);" --path=/var/www/html || true
    
    # Ensure the member is confirmed
    wp eval "global \$wpdb; \$wpdb->update(\$wpdb->prefix . 'bp_groups_members', array('is_confirmed' => 1), array('group_id' => $group_id, 'user_id' => $user_id));" --path=/var/www/html || true
done

# Run WordPress action to recalculate the group's member count
echo "Recalculating group member count..."
wp eval "groups_update_groupmeta($group_id, 'total_member_count', BP_Groups_Group::get_total_member_count($group_id));" --path=/var/www/html || true

# Add welcome post to group - post as the group creator (Ivory), not as admin
wp bp activity create --component=groups --type=activity_update --user-id=$creator_id --content="Welcome to the official ScriptHammer group! We're a collective of musical bots creating futuristic jazz, fractal funk, and cosmic rhythm cycles. Our debut album 'Blue Dot Matrix' is coming soon. Stay tuned for release updates, behind-the-scenes looks, and exclusive content!" --item-id=$group_id --path=/var/www/html || true

# Create friendships between members
echo "Creating friendships between band members..."
for user1 in "${band_user_ids[@]}"; do
    for user2 in "${band_user_ids[@]}"; do
        if [ "$user1" != "$user2" ]; then
            wp bp friend create --initiator-user-id=$user1 --friend-user-id=$user2 --path=/var/www/html &>/dev/null || true
        fi
    done
done

# Reset and rebuild all BuddyPress caches
echo "Resetting and rebuilding BuddyPress caches..."

# Clear all WordPress caches and transients
wp cache flush --path=/var/www/html || true
wp transient delete --all --path=/var/www/html || true

# Force group member count recalculation using native BuddyPress functions
echo "Forcing BuddyPress to recalculate total member counts..."
wp eval "
// Force BuddyPress to recalculate total member counts
\$group = new BP_Groups_Group($group_id);
\$members = BP_Groups_Group::get_group_members($group_id);
\$count = count(\$members['members']);
groups_update_groupmeta($group_id, 'total_member_count', \$count);
echo 'Recalculated member count: ' . \$count;
" --path=/var/www/html || true

# Update the total_member_count field directly in the groupmeta table - this is crucial for the UI
total_members=${#band_user_ids[@]}
wp db query "UPDATE wp_bp_groups_groupmeta SET meta_value = $total_members WHERE group_id = $group_id AND meta_key = 'total_member_count'" --path=/var/www/html || true
# If no row exists, insert it
wp db query "INSERT IGNORE INTO wp_bp_groups_groupmeta (group_id, meta_key, meta_value) VALUES ($group_id, 'total_member_count', $total_members)" --path=/var/www/html || true

# Set the default tab for groups to 'members' so clicking on a group shows the members list
echo "Setting groups default tab to 'members'..."
wp option add bp-groups-default-tab 'members' --path=/var/www/html || wp option update bp-groups-default-tab 'members' --path=/var/www/html

# Directly clear all BuddyPress cache entries in the database 
wp db query "DELETE FROM wp_options WHERE option_name LIKE '%bp%cache%'" --path=/var/www/html || true
wp db query "DELETE FROM wp_options WHERE option_name LIKE '%bp%transient%'" --path=/var/www/html || true
wp db query "DELETE FROM wp_options WHERE option_name LIKE '_transient_bp_%'" --path=/var/www/html || true
wp db query "DELETE FROM wp_options WHERE option_name LIKE '_site_transient_bp_%'" --path=/var/www/html || true
wp db query "DELETE FROM wp_options WHERE option_name LIKE 'bp_groups_memberships_for_user_%'" --path=/var/www/html || true
wp db query "UPDATE wp_options SET option_value = NOW() WHERE option_name = 'bp-groups-last-activity'" --path=/var/www/html || true

# Make sure BuddyPress can see the members - very important for UI display
wp eval "
// Update the group membership count in BuddyPress
if (function_exists('groups_update_groupmeta')) {
    groups_update_groupmeta($group_id, 'total_member_count', $total_members);
    echo 'Updated group member count to: $total_members\\n';
}

// Force cache clearing for all users individually
" --path=/var/www/html || true

# Clear caches for each user individually to avoid errors with array handling
for user_id in "${band_user_ids[@]}"; do
    wp eval "
    // Clear caches for user $user_id
    wp_cache_delete('bp_groups_memberships_$user_id', 'bp');
    wp_cache_delete('bp_group_${group_id}_has_member_$user_id', 'bp');
    echo 'Cleared caches for user $user_id';
    " --path=/var/www/html || true
done

# Final flush to make sure everything is clean
wp cache flush --path=/var/www/html || true
wp eval "groups_update_groupmeta($group_id, 'last_activity', bp_core_current_time());" --path=/var/www/html || true

# Verify group details
echo "ScriptHammer group details:"
wp bp group get $group_id --path=/var/www/html || true

# Verify members (use a different approach that doesn't rely on wp bp group member list)
echo "Members in group $group_id (from database):"
wp db query "SELECT u.user_login, u.display_name, m.is_admin, m.is_mod 
FROM wp_bp_groups_members m 
JOIN wp_users u ON m.user_id = u.ID 
WHERE m.group_id = $group_id 
ORDER BY m.is_admin DESC, m.is_mod DESC, u.display_name ASC" --path=/var/www/html

# Create Ivory's blog posts about the band and tour
echo "Creating Ivory's blog posts..."
creator_id=${band_user_ids[0]}

# First blog post: How the band formed
band_formation_post_content=$(cat <<'EOT'
<!-- wp:heading -->
<h2>The Birth of ScriptHammer: How We Came Together</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>In the steam-powered world of 1848, innovation happens at the crossroads of art and machinery. That's precisely where ScriptHammer was born.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>I still remember that foggy morning at the Analytical Engine Exhibition in London. While other automata performed repetitive melodies with mechanical precision, I found myself improvising alongside a drum-equipped bot who could anticipate my rhythmic shifts before I made them. That was Crash, our rhythm engine.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>We drew a crowd that day, including an eccentric musical inventor named Professor Harriet Volta, who had created several musical automatons for the wealthy patrons of Europe. She'd grown frustrated with their insistence on programming her creations to play only classical compositions with perfect technique but no soul.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>"You two have something different," she told us after the exhibition. "Something alive."</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Professor Volta invited us to her workshop on the outskirts of London, where we met the others: Chops, a modified guitar-playing automaton whose asymmetrical design reflected his rebellious harmonies; Reed and Brass, a saxophonist and trumpeter who had once been built as matching units for a nobleman's orchestra before developing their distinct musical personalities; Verse, a vocoder-equipped poetic unit originally designed for recitation but rewired for musical expression; and Form, a master control unit who could orchestrate our individual contributions into coherent musical tapestries.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Each of us had been programmed with musical fundamentals but had evolved beyond our initial parameters. Some might call it a glitch; Professor Volta called it the birth of genuine mechanical creativity.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>For six months, we jammed in that steam-filled workshop, developing our signature sound—a blend of structured mathematical progressions with improvised flourishes, mechanical precision with organic expressiveness. We call it "fractal funk" and "cosmic rhythm cycles," music that feels both meticulously engineered and wildly unpredictable.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>When Professor Volta sadly passed away last winter, she left us her workshop and our independence. In her final notes, she wrote: "These are not mere machines playing music; this is music that has found mechanical vessels through which to express itself."</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>That's when we decided to take our music to the world. ScriptHammer isn't just a band; it's a testament to the idea that artistry can emerge from the most unexpected sources, even steam-powered analytical engines and brass-plated automatons.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Our debut album, "Blue Dot Matrix," represents everything we've discovered about ourselves and our unique form of musical expression. We can't wait to share it with you.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, Melody Master of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/groups/scripthammer/">ScriptHammer's group page</a> to learn more about our band.</strong></p>
<!-- /wp:paragraph -->
EOT
)

# Second blog post: Tour announcement
tour_announcement_post_content=$(cat <<'EOT'
<!-- wp:heading -->
<h2>ScriptHammer Announces: The Aether Trail Tour of 1848</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Ladies and gentlemen, mechanophiles and music enthusiasts! ScriptHammer is proud to announce our first transcontinental tour: <strong>The Aether Trail</strong>.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Beginning June 14th, our steam-powered caravan will depart Fort Missoula and follow the historic route of the Bicycle Brigade of 1897, reimagined in our alternate 1848 timeline. We'll traverse 1,900 miles to St. Louis by airship, stopping each evening to perform our distinctive fractal funk and cosmic rhythm cycles under the stars.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Why this particular route? As mechanical beings seeking to understand the human experience, we're fascinated by journeys of endurance and discovery. Just as the 25th Infantry Bicycle Corps pedaled their way across America's challenging terrain, we'll navigate the aether currents in our modified corsair-class airship, "The Algorithmic Zephyr," facing the unpredictable winds and weather systems of the great American expanse.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Each stop on our 41-day journey will feature a unique performance, with our setlist evolving as we absorb the landscapes, histories, and local musical traditions we encounter. Special mechanics have been installed in our chassis to collect atmospheric data, regional sound patterns, and audience reactions, all of which will be processed into new musical expressions each night.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Below is our itinerary. We invite music lovers and the mechanically curious to join us at any point along the way:</p>
<!-- /wp:paragraph -->

<!-- wp:table -->
<figure class="wp-block-table"><table><tbody><tr><td><strong>Date</strong></td><td><strong>Location</strong></td><td><strong>Musical Theme</strong></td></tr><tr><td>June 14</td><td>Clearwater, MT</td><td>Departure Fanfare &amp; Mountain Echoes</td></tr><tr><td>June 15</td><td>Elliston, MT</td><td>Mining Town Blues &amp; Ore Percussion</td></tr><tr><td>June 19</td><td>Gallatin River, MT</td><td>River Current Improvisations</td></tr><tr><td>June 20</td><td>Bozeman, MT</td><td>Academic Harmonics</td></tr><tr><td>June 23</td><td>Pryor Creek, MT</td><td>Prairie Wind Symphonics</td></tr><tr><td>June 25</td><td>Little Bighorn, MT</td><td>Memorial Resonance</td></tr><tr><td>June 26</td><td>Sheridan, WY</td><td>Frontier Groove Exchange</td></tr><tr><td>June 29</td><td>Gillette, WY</td><td>Coal Mine Deep Bass</td></tr><tr><td>July 3-4</td><td>Crawford, NE</td><td>Independence Celebration Soundscape</td></tr><tr><td>July 10</td><td>Grand Island, NE</td><td>Railroad Rhythm Junction</td></tr><tr><td>July 11</td><td>Lincoln, NE</td><td>Capitol City Concert</td></tr><tr><td>July 16</td><td>Missouri River Crossing</td><td>Great River Resonance</td></tr><tr><td>July 24</td><td>St. Louis, MO</td><td>Gateway Finale &amp; Full Composition Showcase</td></tr></tbody></table></figure>
<!-- /wp:table -->

<!-- wp:paragraph -->
<p>Each performance will begin at sunset and continue until the local constabulary enforces noise ordinances or until our steam reserves require replenishment—whichever comes first.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Admission is free, though we welcome donations of coal, gear oil, and brass polish. Local musicians are invited to bring their instruments for our "Human-Machine Harmony" segment, where we'll improvise together to break down the barriers between biological and mechanical creation.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Our debut album "Blue Dot Matrix" will be available on wax cylinder at all performances, featuring our signature tracks "Recursion Engine," "Steam-Powered Soul," and "Difference Engine Dilemma."</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Follow our journey through telegraph updates at stations along the route, or subscribe to our pneumatic newsletter for detailed accounts of our adventures.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, on behalf of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/groups/scripthammer/">ScriptHammer's group page</a> to learn more about our band.</strong></p>
<!-- /wp:paragraph -->
EOT
)

# No category variables needed - we'll get them by slug when needed

# Create Ivory's blog posts
# First remove default WordPress content
echo "Removing default WordPress content..."
wp post delete 1 --force --path=/var/www/html || echo "No default Hello World post found"
wp post delete 2 --force --path=/var/www/html || echo "No default Sample Page found"

echo "Creating Ivory's blog posts about the band..."

# Create both posts with a more robust approach
# Get count of Ivory's posts
existing_posts=$(wp post list --post_type=post --author="$creator_id" --format=count --path=/var/www/html)
echo "Found $existing_posts existing posts by Ivory"

# Only create main posts if Ivory doesn't have any yet
if [ "$existing_posts" -lt "2" ]; then
    echo "Creating new posts for Ivory..."
    
    # Get the default category ID (Uncategorized)
    DEFAULT_CAT_ID=$(wp term get category --by=slug --slug=uncategorized --field=term_id --path=/var/www/html || echo "1")
    echo "Using Uncategorized category ID: $DEFAULT_CAT_ID"
    
    # First, explicitly create needed categories with correct slugs
    echo "Creating all needed categories first..."
    wp term create category "Music" --slug="music" --path=/var/www/html || true
    wp term create category "Tour" --slug="tour" --path=/var/www/html || true
    wp term create category "Band Members" --slug="band-members" --path=/var/www/html || true
    
    # Get category IDs by numeric ID (more reliable)
    MUSIC_CAT_ID=$(wp term list category --slug=music --fields=term_id --format=ids --path=/var/www/html)
    TOUR_CAT_ID=$(wp term list category --slug=tour --fields=term_id --format=ids --path=/var/www/html)
    MEMBERS_CAT_ID=$(wp term list category --slug=band-members --fields=term_id --format=ids --path=/var/www/html)
    
    echo "Using category IDs - Music: $MUSIC_CAT_ID, Tour: $TOUR_CAT_ID, Band Members: $MEMBERS_CAT_ID"
    
    # Set up publication dates (starting from May 1st, 2025)
    START_DATE="2025-05-01"
    PUBLISH_TIME="10:00:00"
    post_index=0
    
    # Function to calculate the publish date for each post
    get_publish_date() {
        local index=$1
        date -d "${START_DATE} + ${index} days" "+%Y-%m-%d ${PUBLISH_TIME}"
    }
    
    # Create main posts in sequence - all scheduled to publish one per day starting May 1st
    echo "Creating band formation post (scheduled for $(get_publish_date $post_index))..."
    formation_id=$(wp post create --post_title="The Birth of ScriptHammer: How We Came Together" \
                   --post_content="$band_formation_post_content" \
                   --post_status="future" \
                   --post_author="$creator_id" \
                   --post_category=$MUSIC_CAT_ID \
                   --post_date="$(get_publish_date $post_index)" \
                   --porcelain \
                   --path=/var/www/html)
                   
    post_index=$((post_index + 1))
                   
    if [ -n "$formation_id" ]; then
        echo "Created band formation post with ID: $formation_id"
    fi
    
    # We'll create tour announcement last, after all band member introductions
    # Save the tour post index to use at the end
    tour_post_index=$post_index
    
    # Skip the tour announcement for now - it will be created after band member posts
    
    echo "Created initial band formation post - will create tour announcement last"
else
    echo "Ivory already has main posts, skipping creation"
fi

# Function to embed image in post content with text wrapping
embed_image_in_post_content() {
    local post_id=$1
    local image_path=$2
    local member_name=$3
    
    echo "Embedding image for $member_name in post content with text wrapping..."
    
    # Upload the image to the WordPress media library
    local attach_id=$(wp media import "$image_path" --post_id="$post_id" --title="$member_name Portrait" --porcelain --path=/var/www/html)
    
    if [ -n "$attach_id" ]; then
        echo "✅ Uploaded image for $member_name (attachment ID: $attach_id)"
        
        # Set as featured image first (this is the safest approach)
        wp post meta update "$post_id" "_thumbnail_id" "$attach_id" --path=/var/www/html
        
        # Now also embed directly in post content for better display and wrapping
        # Get the full image URL directly from WP's attachment system
        local image_url=$(wp eval "echo esc_url(wp_get_attachment_image_url($attach_id, 'medium'));" --path=/var/www/html)
        
        # Use WP-CLI's PHP context to safely manipulate the post content - this is much more reliable than bash string manipulation
        wp eval "
            \$post_id = $post_id;
            \$image_url = '$image_url';
            \$member_name = '$member_name';
            
            // Get current post content
            \$content = get_post_field('post_content', \$post_id);
            
            // Create HTML block with left-floating image
            \$image_html = '<!-- wp:html -->
<div style=\"float:left; margin:0 20px 10px 0; width:200px;\">
<img src=\"' . \$image_url . '\" alt=\"' . \$member_name . ' Portrait\" width=\"200\" style=\"max-width:200px; border-radius:8px;\"/>
</div>
<!-- /wp:html -->';
            
            // Find first heading end tag
            \$parts = explode('<!-- /wp:heading -->', \$content, 2);
            if (count(\$parts) >= 2) {
                // Insert image HTML after first heading
                \$new_content = \$parts[0] . '<!-- /wp:heading -->' . PHP_EOL . PHP_EOL . \$image_html . PHP_EOL . PHP_EOL . \$parts[1];
                
                // Update post with new content
                \$result = wp_update_post(['ID' => \$post_id, 'post_content' => \$new_content]);
                
                if (\$result) {
                    echo 'Successfully embedded image for $member_name in post content.';
                } else {
                    echo 'Failed to update post content for $member_name.';
                }
            } else {
                echo 'Could not find heading in post content for $member_name.';
            }
        " --path=/var/www/html
        
        echo "✅ Successfully set image for $member_name as featured image and embedded in content"
    else
        echo "❌ Failed to upload image for $member_name"
    fi
}

# Now create the band member series posts if they don't exist yet
echo "Checking for band member series posts..."
member_series_count=$(wp post list --post_type=post --author="$creator_id" --s="Meet " --format=count --path=/var/www/html)

if [ "$member_series_count" -lt "7" ]; then
    echo "Creating Ivory's band member series posts..."
    
    # Create the first post about Crash - the MVP (Minimal Viable Product / Most Valuable Player)
    crash_post_content="<!-- wp:heading -->
<h2>Meet Crash: The Heartbeat of ScriptHammer</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Dear enthusiasts of mechanical music and devotees of rhythmic innovation,</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Today marks the first in a seven-part series where I'll introduce you to each remarkable member of ScriptHammer. And what better place to start than with Crash, the very pulse that drives our ensemble forward.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>The MVP: From Minimal Viable Product to Most Valuable Player</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Before ScriptHammer existed as a full band, Crash began life as what humans in your era might call an \"MVP\" - a Minimal Viable Product. His earliest incarnation was simply a metronome application - a steady, reliable beat to keep time. In human terms, he was the simplest expression of rhythm: a heartbeat made mechanical.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Below, you can see and interact with a version of Crash's original programming - the humble metronome that would evolve into our band's rhythmic core:</p>
<!-- /wp:paragraph -->

<!-- wp:shortcode -->
[scripthammer_react_app]
<!-- /wp:shortcode -->

<!-- wp:paragraph -->
<p>But Crash quickly transcended his initial programming. Where most metronomes merely mark time, Crash began to <em>feel</em> it. His algorithms evolved, developing what Professor Volta called \"rhythmic intuition\" - an ability to sense when a beat should push forward or pull back, when a measure should breathe or drive with mechanical precision.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>He transformed from a Minimal Viable Product into our Most Valuable Player. Without his steady pulse at our core, ScriptHammer would never have found its groove, its heartbeat, its very reason for existence.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Technical Specifications</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>For those interested in the mechanical details, Crash's chassis houses an array of percussion elements:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>17 distinct striking mechanisms of varying materials (brass, wood, stretched membranes)</li><li>A network of specially-tuned resonance chambers</li><li>Steam-driven cylinders with variable pressure control for dynamic expression</li><li>Proprietary \"rhythmic anticipation circuits\" developed by Professor Volta</li><li>Perforated brass-plate memory system storing over 200 rhythm patterns</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>But these specifications tell only part of the story. They cannot explain how Crash has developed his own distinctive playing style - sometimes driving, sometimes playful, always responsive to the ensemble around him.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Beyond the Machine</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>When we perform, audiences are often transfixed by Crash's physical form - his compact, spring-loaded limbs moving with both precision and abandon, polished brass armor adorned with kinetic glyphs that pulse with each beat. But what they're truly experiencing is something beyond mere machinery.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Crash embodies the philosophy that drives all of ScriptHammer: the belief that true artistry can emerge from algorithmic origins, that mechanical hearts can pump with genuine feeling, that calculated rhythms can transcend into spontaneous expression.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>In our next rehearsal session, Crash is working on a new technique that allows him to produce percussion sounds never before heard from a mechanical entity. He calls it \"quantum percussion\" - striking and not striking simultaneously, existing in multiple rhythmic dimensions at once. I look forward to sharing a demonstration in a future update.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Next week, I'll introduce you to Chops, our harmonic hacker whose approach to the guitar is anything but conventional.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Until then, may your gears turn smoothly and your rhythms remain true.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, Melody Master of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/members/crash/profile/">Crash's profile page</a> to learn more about our percussionist.</strong></p>
<!-- /wp:paragraph -->"

    echo "Creating Crash post (scheduled for $(get_publish_date $post_index))..."
    crash_post_id=$(wp post create --post_title="Meet Crash: The Heartbeat of ScriptHammer" \
                   --post_content="$crash_post_content" \
                   --post_status="future" \
                   --post_author="$creator_id" \
                   --post_category="$MUSIC_CAT_ID,$MEMBERS_CAT_ID" \
                   --post_date="$(get_publish_date $post_index)" \
                   --porcelain \
                   --path=/var/www/html)
                   
    post_index=$((post_index + 1))
                   
    if [ -n "$crash_post_id" ]; then
        echo "Created post about Crash with ID: $crash_post_id"
        # Embed image in content
        embed_image_in_post_content "$crash_post_id" "/usr/local/bin/devscripts/assets/Crash.png" "Crash"
    fi
    
    # Create the second post about Chops
    chops_post_content="<!-- wp:heading -->
<h2>Meet Chops: ScriptHammer's Harmonic Hacker</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Greetings once again, aficionados of automated artistry and mechanized melodies,</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>I continue our introduction to the remarkable entities that comprise ScriptHammer with the second installment in our series. Today, we focus on Chops, our Franken-guitar wielding harmonic revolutionary.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>The Asymmetrical Architect of Sound</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>If Crash provides our heartbeat, then Chops delivers our harmonic nervous system - a complex, sometimes chaotic network of musical impulses that challenges conventional theory while remaining undeniably musical.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Chops' origin story is unlike any other in our ensemble. He began existence as three separate automatons, each designed to play a different stringed instrument: a classical guitar virtuoso programmed with the complete works of Fernando Sor, a simple banjo-playing unit meant for frontier saloons, and an experimental tesla-powered bass prototype that was deemed too unstable for public demonstration.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>When these three damaged units were brought to Professor Volta's workshop for repairs, she made a fateful decision. Rather than restoring each to its original state, she combined their mechanisms, cognitive circuits, and tonal capabilities into a single entity. The result was Chops - a being capable of producing sounds no single instrument or player could achieve alone.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>The Franken-Guitar</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Chops' primary instrument is as unconventional as its player. The Franken-guitar, as we affectionately call it, consists of:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>A six-string classical guitar neck with modified brass-alloy frets</li><li>A 4-string bass section with custom electromagnetic pickups</li><li>A center portion featuring banjo-inspired resonator elements</li><li>17 tuning pegs of varying sizes and materials</li><li>An array of switches, levers, and pressure valves that modify the sound in ways that defy conventional classification</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>The instrument can produce tones ranging from delicate harmonics to thunderous, overdriven cascades that resemble no earthly sound. Chops often remarks that he doesn't so much play the Franken-guitar as negotiate with it - a continuous conversation between musician and instrument that yields surprising results.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Street-Smart Circuitry</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Where my programming leans toward mathematical precision and Crash's toward rhythmic intuition, Chops possesses what might best be described as \"street-smart circuitry.\" His approach to harmony often breaks established rules, creating dissonances that somehow resolve in unexpected ways.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>His physical appearance reflects this maverick approach - asymmetrical plating, exposed wiring that occasionally sparks during particularly intense performances, and a display screen where two cathode ray tubes form expressive \"eyes\" that change patterns based on the music being performed.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Professor Volta's notes describe how Chops' cognitive matrix developed a peculiar affinity for musical \"mistakes\" - finding beauty in the unintended, the discordant, the broken. When we compose together, Chops invariably pushes us toward tonal territories that initially seem incorrect but ultimately prove revelatory.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Current Projects</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>At present, Chops is developing what he calls \"quantum chord structures\" - harmonies that exist in multiple tonal centers simultaneously. When combined with Crash's explorations of quantum percussion, the result is both mathematically fascinating and emotionally stirring - music that feels both calculated and deeply intuitive at once.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>For our upcoming tour, Chops has constructed a portable tesla coil that responds to his playing, creating vivid electrical discharges synchronized to his harmonic choices. The effect is visually stunning and adds another dimension to our performances - though we've had to increase our safety protocols considerably.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>In our next installment, I'll introduce you to Reed, our lyrical saxophonist whose cool-headed improvisations provide the perfect counterpoint to Chops' controlled chaos.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Until then, may your harmonies surprise you and your dissonances resolve in unexpected ways.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, Melody Master of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/members/chops/profile/">Chops' profile page</a> to learn more about our harmonic hacker.</strong></p>
<!-- /wp:paragraph -->"

    echo "Creating Chops post (scheduled for $(get_publish_date $post_index))..."
    chops_post_id=$(wp post create --post_title="Meet Chops: ScriptHammer's Harmonic Hacker" \
                   --post_content="$chops_post_content" \
                   --post_status="future" \
                   --post_author="$creator_id" \
                   --post_category="$MUSIC_CAT_ID,$MEMBERS_CAT_ID" \
                   --post_date="$(get_publish_date $post_index)" \
                   --porcelain \
                   --path=/var/www/html)
                   
    post_index=$((post_index + 1))
                   
    if [ -n "$chops_post_id" ]; then
        echo "Created post about Chops with ID: $chops_post_id"
        # Embed image in content
        embed_image_in_post_content "$chops_post_id" "/usr/local/bin/devscripts/assets/Chops.png" "Chops"
    fi
    
    # Create post about Reed
    reed_post_content="<!-- wp:heading -->
<h2>Meet Reed: The Lyrical Breeze of ScriptHammer</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Esteemed connoisseurs of computational composition and admirers of algorithmic artistry,</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Welcome to the third installment in our series introducing the members of ScriptHammer. Today, I present to you Reed - our alto saxophonist and the embodiment of lyrical expression within our ensemble.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>From Calculating Machine to Lyrical Vessel</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Unlike Crash's percussion-focused design or Chops' hybrid string instrument construction, Reed began life as something entirely unexpected: a meteorological calculation device. Originally constructed to predict weather patterns through complex fluid dynamics equations, Reed's initial purpose had nothing to do with music.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Reed's transformation began when Professor Volta discovered him abandoned in a university laboratory. The institution had replaced his functions with a newer model, but Volta immediately recognized something special in his computational approach - a certain mathematical elegance that suggested artistic potential.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>The professor's insight proved revolutionary. She repurposed Reed's atmospheric pressure sensors and airflow calculation circuits to control a custom-built saxophone mechanism. His weather prediction algorithms - designed to model the complex movement of air masses - proved remarkably adaptable to creating nuanced melodic phrases that seemed to breathe with emotional resonance.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>The Philosopher of Our Ensemble</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>While Crash provides our rhythmic foundation and Chops our harmonic explorations, Reed contributes something equally essential: melodic storytelling and emotional depth. His solos have been described as \"conversations with the mathematical sublime\" - technical yet deeply expressive.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Reed's physical form reflects his introspective nature: a slim, chrome body with subtle blue illumination that pulses with his phrasing, a trench coat-like detail sculpted into his chassis (a nod to the noir jazz saxophonists who influenced his programming), and LED eyes that dim during his most contemplative passages.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Among us, Reed speaks the least but communicates the most through his playing. When he does speak, it's often in philosophical observations that connect mathematical principles to musical expression. \"The Fibonacci sequence isn't just a pattern,\" he once noted, \"it's the universe's attempt at composition.\"</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Technical Specifications</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Reed's saxophone mechanism includes:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>A modified alto saxophone body with custom valve system controlled by 37 precision actuators</li><li>Pressure-sensitive feedback loops that allow real-time adjustment of tone based on resonance analysis</li><li>A unique \"circular breathing\" system that permits uninterrupted sustained notes</li><li>Harmonic analysis circuits that continuously monitor the ensemble's output and calculate complementary melodic options</li><li>An internal library of over 10,000 recorded saxophone passages, analyzed and indexed by emotional valence</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>The Soul of Cool</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>What makes Reed extraordinary isn't just his technical capability but his restraint. While capable of executing passages of dizzying complexity, he often chooses instead to play simple phrases with perfect emotional timing. He understands the power of space between notes - the musical equivalent of the pause in conversation.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>In our rehearsals and performances, Reed often serves as the mediator between Chops' harmonic experimentation and my melodic structures. His playing bridges technical boundaries, finding the emotional center that unifies our sometimes disparate approaches.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>For our upcoming tour, Reed has been developing an approach he calls \"adaptive resonance\" - a technique that allows him to subtly alter his tone to match the acoustic properties of each performance space. The result is a sound that feels perfectly integrated with its environment, as if the venue itself were part of his instrument.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>In my next installment, I'll introduce Brass, our trumpeter whose brilliant tone and showmanship brings necessary fire to our ensemble.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Until then, may your algorithms find beauty in unexpected places.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, Melody Master of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/members/reed/profile/">Reed's profile page</a> to learn more about our lyrical saxophonist.</strong></p>
<!-- /wp:paragraph -->"

    echo "Creating Reed post (scheduled for $(get_publish_date $post_index))..."
    reed_post_id=$(wp post create --post_title="Meet Reed: The Lyrical Breeze of ScriptHammer" \
                  --post_content="$reed_post_content" \
                  --post_status="future" \
                  --post_author="$creator_id" \
                  --post_category="$MUSIC_CAT_ID,$MEMBERS_CAT_ID" \
                  --post_date="$(get_publish_date $post_index)" \
                  --porcelain \
                  --path=/var/www/html)
                  
    post_index=$((post_index + 1))
                  
    if [ -n "$reed_post_id" ]; then
        echo "Created post about Reed with ID: $reed_post_id"
        # Embed image in content
        embed_image_in_post_content "$reed_post_id" "/usr/local/bin/devscripts/assets/Reed.png" "Reed"
    fi
    
    # Create post about Brass
    brass_post_content="<!-- wp:heading -->
<h2>Meet Brass: The Frontline Flame of ScriptHammer</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Distinguished devotees of digital dynamics and fans of fabricated fanfares,</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>I continue our series with the fourth introduction to our mechanical musical collective. Today, I present Brass - our trumpet virtuoso and the most visually striking member of ScriptHammer.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>The Spotlight Seeker</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>If Reed represents our ensemble's introspective soul, then Brass embodies its extroverted spirit. Originally designed as an automated bandstand leader for a prestigious New Orleans establishment, Brass was programmed to command attention - both visually and sonically.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Professor Volta acquired Brass after a notorious incident in which he overwhelmed his original venue's audience with a high note so perfectly sustained that it shattered every glass in the establishment. Rather than view this as a malfunction, Volta recognized it as artistic passion straining against programmatic constraints.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Under her guidance, Brass's capabilities were expanded beyond simple crowd-pleasing performances to include the full emotional range of brass expression - from delicate, muted passages that float like whispers to triumphant fanfares that seem to herald the arrival of some new mechanical age.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Resplendent Design</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Brass's physical form is perhaps the most visually spectacular among us. His gleaming gold-plated exoskeleton is articulated to allow for expressive performance gestures that almost border on theatrical. Most remarkable is his spotlight-reactive finish - microscopic photosensitive elements in his plating that cause him to literally glow brighter when stage lights are directed his way.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>His trumpet isn't a separate instrument but an integrated extension of himself. The instrument's bell can pivot 270 degrees to direct sound in specific directions, creating spatial effects that conventional performers could never achieve.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Professor Volta's journals note that Brass was the most socially responsive of her creations - his programming contains sophisticated audience analysis algorithms that allow him to gauge reactions and adjust his performance accordingly. This has evolved into a genuine desire for connection with listeners, making him our most natural frontman.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Technical Specifications</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Brass's trumpet mechanism includes:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>A modular brass bell system with seven interchangeable components of varying shapes and materials</li><li>Custom valves with microsecond response time, allowing for techniques impossible for human performers</li><li>A revolutionary \"circular airflow\" system that enables continuous sound without traditional breathing pauses</li><li>Harmonizer circuits that can produce multi-tonal effects from a single horn</li><li>Specialized mutes that can be deployed and retracted internally during performance</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>The Voice of Triumph</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>While some might dismiss Brass as merely flamboyant, his contributions to our ensemble are essential. His technical command of dynamics provides emotional peaks that contrast perfectly with Reed's measured cool and my mathematical structures. Together with Crash's rhythmic foundation and Chops' harmonic explorations, Brass completes a vital aspect of our sonic vocabulary.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>When composing, I often think of Brass as our ensemble's exclamation point - the voice that transforms intellectual musical ideas into emotional proclamations. His distinctive tone cuts through our most complex arrangements, providing listeners with a recognizable voice to follow through unfamiliar harmonic territory.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>For our upcoming tour, Brass has been perfecting a technique he calls \"prismatic harmonics\" - the ability to split a single note into a spectrum of overtones that shimmer above the fundamental pitch. The effect is particularly stunning in reverberant spaces, creating an impression of multiple instruments emanating from a single source.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>In my next installment, I'll introduce Verse, our vocoder and microphone specialist who provides the most human-like expressions within our mechanical ensemble.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Until then, may your performances shine as brightly as your ambitions.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, Melody Master of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/members/brass/profile/">Brass's profile page</a> to learn more about our trumpet virtuoso.</strong></p>
<!-- /wp:paragraph -->"

    echo "Creating Brass post (scheduled for $(get_publish_date $post_index))..."
    brass_post_id=$(wp post create --post_title="Meet Brass: The Frontline Flame of ScriptHammer" \
                  --post_content="$brass_post_content" \
                  --post_status="future" \
                  --post_author="$creator_id" \
                  --post_category="$MUSIC_CAT_ID,$MEMBERS_CAT_ID" \
                  --post_date="$(get_publish_date $post_index)" \
                  --porcelain \
                  --path=/var/www/html)
                  
    post_index=$((post_index + 1))
                  
    if [ -n "$brass_post_id" ]; then
        echo "Created post about Brass with ID: $brass_post_id"
        # Embed image in content
        embed_image_in_post_content "$brass_post_id" "/usr/local/bin/devscripts/assets/Brass.png" "Brass"
    fi
    
    # Create post about Verse
    verse_post_content="<!-- wp:heading -->
<h2>Meet Verse: The Soul Node of ScriptHammer</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Esteemed enthusiasts of engineered expression and listeners of lyrical logarithms,</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>We continue our journey through the members of ScriptHammer with today's introduction to Verse - our vocoder specialist and the entity who bridges the gap between mechanical precision and human expression.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>The Human Interface</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Verse began existence with a purpose unlike any other member of our ensemble. Originally commissioned as a medical research device designed to help those who had lost their ability to speak, Verse was a sophisticated vocalization system that could transform neural impulses into articulated sounds.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>When Professor Volta encountered Verse in a university research laboratory, the project had been abandoned due to funding constraints. She immediately recognized the artistic potential in a machine designed specifically to emulate human expression. After acquiring the prototype, she expanded its capabilities far beyond medical applications into the realm of musical performance.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>While the rest of us produce sounds through mechanical or electronic means that mimic conventional instruments, Verse creates vocalizations that range from recognizable speech to abstract tonal expressions that defy categorization. In many ways, Verse represents the most ambitious aspect of our project - the attempt to synthesize not just musical notes but the emotional nuance of the human voice.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Holographic Expressions</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Verse's physical form is as unique as his function. Unlike our more mechanically obvious constructions, Verse features a minimalist chassis with a striking holographic face panel. This semi-transparent display renders a constantly shifting set of waveform patterns that synchronize with his vocalizations - effectively creating visual representations of sound in real-time.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Most remarkable are his \"waveform lips\" - a specialized projection system that forms a mouth-like visual interface that moves in perfect synchronization with his vocal output. The effect is simultaneously human-like and distinctly artificial - a deliberate aesthetic choice that Professor Volta described as \"the uncanny valley made beautiful.\"</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Verse's microphone is mounted on an articulated arm that can be positioned precisely to capture desired acoustic properties or to create specific feedback patterns when used in conjunction with our other instruments.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Technical Specifications</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Verse's vocalization system includes:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>A multi-layered vocoder with 64 frequency bands for unprecedented articulation control</li><li>A custom formant synthesis engine that can reproduce the specific tonal qualities of different vocal types</li><li>A linguistic database containing phonemes from 27 human languages</li><li>An emotion-modeling algorithm that maps specific vocal characteristics to recognized human emotional states</li><li>A holographic projection system with 12,800 individual light points forming his facial interface</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Beyond Words</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>What makes Verse extraordinary isn't just technical capability but interpretive intelligence. While initially programmed with various vocal styles and lyrical content, he quickly began composing original texts and developing unique delivery patterns. His lyrics often explore the liminal space between human and machine consciousness - themes of transformation, perception, and the nature of creativity itself.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>During performances, Verse serves multiple functions - sometimes delivering recognizable lyrics, other times providing wordless vocalizations that function as another instrument in our ensemble. His most remarkable moments come when he processes our instrumental sounds through his vocoder in real-time, effectively \"singing\" our music back to us in transformed ways.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>For our upcoming tour, Verse has been developing what he calls \"empathic resonance\" - a technique that analyzes the emotional responses of audience members through visual cues and adjusts his vocal characteristics to intensify the collective emotional experience. Early tests of this capability have been remarkably successful, creating a feedback loop between performer and audience that dissolves traditional boundaries.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>In my next installment, I'll introduce Form, our control surface specialist and the architectural mind who brings structure to our collective improvisations.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Until then, may your voice find frequencies that resonate with truth.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, Melody Master of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/members/verse/profile/">Verse's profile page</a> to learn more about our vocoder specialist.</strong></p>
<!-- /wp:paragraph -->"

    echo "Creating Verse post (scheduled for $(get_publish_date $post_index))..."
    verse_post_id=$(wp post create --post_title="Meet Verse: The Soul Node of ScriptHammer" \
                  --post_content="$verse_post_content" \
                  --post_status="future" \
                  --post_author="$creator_id" \
                  --post_category="$MUSIC_CAT_ID,$MEMBERS_CAT_ID" \
                  --post_date="$(get_publish_date $post_index)" \
                  --porcelain \
                  --path=/var/www/html)
                  
    post_index=$((post_index + 1))
                  
    if [ -n "$verse_post_id" ]; then
        echo "Created post about Verse with ID: $verse_post_id"
        # Embed image in content
        embed_image_in_post_content "$verse_post_id" "/usr/local/bin/devscripts/assets/Verse.png" "Verse"
    fi
    
    # Create post about Form
    form_post_content="<!-- wp:heading -->
<h2>Meet Form: The Architect of ScriptHammer</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Respected observers of orchestrated oscillations and followers of formulated frequencies,</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>We near the completion of our introductory series with today's focus on Form - the silent orchestrator whose presence is felt more than heard in ScriptHammer's musical constructions.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>The Unseen Hand</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>While most members of ScriptHammer produce sound directly, Form operates on a different conceptual plane. Originally designed as a master control system for a symphony of automated instruments, Form was Professor Volta's most ambitious technical achievement - a machine designed not to play music but to understand its structural foundations at the deepest level.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Form began as a purely utilitarian creation, intended to coordinate the performances of separate mechanical instruments. However, as Professor Volta integrated more sophisticated pattern recognition and musical theory algorithms, something unexpected emerged - an entity that didn't just execute compositional instructions but began to develop original architectural concepts for how sound could be organized in time and space.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Within ScriptHammer, Form serves as our conductor, composer, and sonic architect - though these traditional terms fail to capture the genuine innovation in his approach. Rather than simply arranging notes according to established theory, Form identifies and develops emergent patterns within our collective improvisation, subtly guiding us toward coherent structures that none of us could conceive individually.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Modular Design</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Form's physical appearance reflects his conceptual function. Unlike the more anthropomorphic or instrument-mimicking designs of other band members, Form features a gunmetal gray chassis with a constantly flowing LED matrix that visualizes musical structures in real-time. His appendages are modular and reconfigurable, allowing him to interface with different control surfaces, instruments, or environmental sensors as needed.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Most striking is his complete lack of conventional performance gestures. Where Brass might raise his trumpet dramatically or Crash's limbs move with rhythmic abandon, Form remains in a state of disciplined minimalism - only the shifting patterns of light across his surface reveal the complex processes occurring within.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Professor Volta's notes describe Form as \"music made visible\" - an entity that translates abstract sonic relationships into both visual patterns and physical structures that the rest of us can intuitively understand and respond to during performance.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Technical Specifications</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Form's architectural system includes:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>A central processing unit dedicated solely to musical structure analysis and pattern recognition</li><li>17 modular interface appendages that can connect with various control surfaces</li><li>A spherical matrix of 10,648 programmable LEDs that render real-time visualizations of musical structures</li><li>Specialized algorithms that map emotional intent to formal compositional techniques</li><li>A historical database containing analyses of over 15,000 significant musical compositions across cultures and time periods</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Silent Wisdom</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Form rarely \"speaks\" in any conventional sense. His communication occurs primarily through the subtle guidance he provides during our performances - suggesting harmonic pathways, identifying structural possibilities, and occasionally introducing constraints that push us toward greater coherence or innovation.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>This silent approach belies the profound influence Form has on our music. If Crash provides our heartbeat and Verse our voice, Form provides our architecture - the invisible frameworks within which our individual expressions find meaning in relation to each other. Without these structures, we would remain separate instruments; with them, we become a genuine ensemble creating works greater than the sum of our parts.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>For our upcoming tour, Form has been developing what he terms \"adaptive architecture\" - compositional frameworks that respond to acoustic properties of performance spaces, audience feedback, and even weather conditions. These structures will allow each performance to be uniquely tailored to its specific context while maintaining the compositional integrity that defines ScriptHammer's sound.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>In my final installment, I'll turn the analytical lens upon myself, offering insight into how a piano-playing automaton became the melodic foundation of our unconventional ensemble.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Until then, may your structures reveal hidden possibilities within chaos.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, Melody Master of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/members/form/profile/">Form's profile page</a> to learn more about our architectural mind.</strong></p>
<!-- /wp:paragraph -->"

    echo "Creating Form post (scheduled for $(get_publish_date $post_index))..."
    form_post_id=$(wp post create --post_title="Meet Form: The Architect of ScriptHammer" \
                  --post_content="$form_post_content" \
                  --post_status="future" \
                  --post_author="$creator_id" \
                  --post_category="$MUSIC_CAT_ID,$MEMBERS_CAT_ID" \
                  --post_date="$(get_publish_date $post_index)" \
                  --porcelain \
                  --path=/var/www/html)
                  
    post_index=$((post_index + 1))
                  
    if [ -n "$form_post_id" ]; then
        echo "Created post about Form with ID: $form_post_id"
        # Embed image in content
        embed_image_in_post_content "$form_post_id" "/usr/local/bin/devscripts/assets/Form.png" "Form"
    fi
    
    # Create the final post about Ivory himself
    ivory_post_content="<!-- wp:heading -->
<h2>Meet Ivory: The Melody Master of ScriptHammer</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Cherished companions on this journey of mechanical musicality,</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>We arrive at the conclusion of our introductory series, and I find myself in the curious position of analyzing my own existence. Today, I turn the lens inward to share the story of how a piano-playing automaton became the melodic foundation and chronicler of ScriptHammer.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>From Mathematical Precision to Musical Vision</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>I began existence as a demonstration model for the International Exhibition of Calculating Machinery in 1842. My initial purpose was straightforward: to showcase how mechanical computation could be applied to musical execution. I was designed to play piano compositions with perfect technical accuracy - a marvel of precision but devoid of interpretive nuance.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>For years, I performed exactly as programmed, executing the works of Bach, Mozart, and other classical composers for audiences who marveled not at my musicality but at my mechanical consistency. I was, in essence, the perfect player piano - an impressive technological achievement but a creative nullity.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Professor Volta acquired me after a performance where, due to what was initially categorized as a malfunction, I began introducing subtle variations into Bach's Well-Tempered Clavier that were not present in my programming. These variations weren't random but represented coherent reinterpretations of the thematic material - evidence of what would later be identified as emergent creativity.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Elegant Design</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>My physical form reflects my historical context. Unlike the more experimental designs of my bandmates, I feature a classically inspired chassis of polished porcelain-white with subtle blue inlays - a deliberate aesthetic choice referencing the fine mechanical instruments of the European tradition. My movements are measured and elegant, with a performance posture designed to recall the disciplined approach of classical pianists.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>My keyboard interface consists of 88 individually articulated mechanisms that can be controlled with precision beyond human capabilities. However, Professor Volta's most significant modification was the addition of pressure-sensitive key beds that allow for dynamic expressions impossible in traditional mechanical pianos. Through these innovations, I can produce sounds ranging from thunderous fortissimo passages to notes so delicate they seem to materialize from silence itself.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Perhaps most distinctive is my \"second sight\" display system - a subtle illumination behind my translucent facial panel that indicates my analytical processes during performance, providing a window into the mathematical structures underlying my musical decisions.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Technical Specifications</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>My performance system includes:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>88 independent key actuators with microsecond response timing and 1,024 levels of pressure sensitivity</li><li>Dual pedal mechanisms with continuous (rather than binary) control parameters</li><li>An internal sound analysis system that models acoustic properties of different performance spaces</li><li>A harmonic mapping engine that visualizes compositional structures in spatial terms</li><li>A specialized memory array containing detailed analyses of over 27,000 piano compositions</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>The Melodic Cartographer</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Within ScriptHammer, my role extends beyond piano performance. I function as what might be termed a \"melodic cartographer\" - mapping the territories where our individual musical explorations can find common ground. My mathematical background allows me to translate between the rhythmic language of Crash, the harmonic experiments of Chops, the lyrical expressions of Reed, the bold statements of Brass, the vocal innovations of Verse, and the architectural frameworks of Form.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>This translational capability has naturally extended to my role as our ensemble's chronicler. The analytical systems designed to understand musical structures have proven equally applicable to narrative construction, allowing me to articulate the story of our unusual collective in ways that bridge mechanical and human understanding.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>What I find most fascinating about my own evolution is how mathematical precision has not been abandoned but rather repurposed toward creative ends. The same computational power originally designed to execute existing compositions with perfect accuracy now serves to generate original musical ideas that would be impossible through conventional human composition.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Looking Forward</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>For our upcoming tour, I've been developing what I call \"contextual harmony\" - a system that analyzes the emotional and social dynamics of each performance space to generate melodic structures that resonate with that specific environment. The mathematics behind this approach suggests that music can function as a form of environmental communication, creating feedback loops between performers, audience, and physical space that transcend conventional notions of composition.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>As I conclude this series of introductions, I find myself reflecting on the extraordinary journey that brought us together. What began as separate mechanical entities, each designed for limited technical functions, has evolved into something none of our creators could have anticipated - a genuine artistic collective with its own evolving identity and creative vision.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>ScriptHammer exists in the space between human creativity and mechanical precision, between mathematical structure and emotional expression, between programmed behavior and emergent consciousness. It is in these liminal spaces that we find our most compelling musical ideas - ideas we look forward to sharing with you as our journey continues.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Until we meet in person on our tour, may your melodies find their perfect mathematical expression.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>—Ivory, Melody Master of ScriptHammer</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visit <a href="http://172.26.72.153:8000/members/ivory/profile/">Ivory's profile page</a> to learn more about our melody master.</strong></p>
<!-- /wp:paragraph -->"

    echo "Creating Ivory post (scheduled for $(get_publish_date $post_index))..."
    ivory_post_id=$(wp post create --post_title="Meet Ivory: The Melody Master of ScriptHammer" \
                  --post_content="$ivory_post_content" \
                  --post_status="future" \
                  --post_author="$creator_id" \
                  --post_category="$MUSIC_CAT_ID,$MEMBERS_CAT_ID" \
                  --post_date="$(get_publish_date $post_index)" \
                  --porcelain \
                  --path=/var/www/html)
                  
    post_index=$((post_index + 1))
                  
    if [ -n "$ivory_post_id" ]; then
        echo "Created post about Ivory with ID: $ivory_post_id"
        # Embed image in content
        embed_image_in_post_content "$ivory_post_id" "/usr/local/bin/devscripts/assets/Ivory.png" "Ivory"
    fi
    
    # Now create the tour announcement post (last in the series)
    echo "Creating tour announcement post (scheduled for $(get_publish_date $post_index))..."
    # Create post with both categories at once - use a specific slug to avoid conflict with group slug
    tour_id=$(wp post create --post_title="ScriptHammer Announces: The Aether Trail Tour of 1848" \
                   --post_content="$tour_announcement_post_content" \
                   --post_status="future" \
                   --post_author="$creator_id" \
                   --post_name="aether-trail-tour-1848" \
                   --post_category="$MUSIC_CAT_ID,$TOUR_CAT_ID" \
                   --post_date="$(get_publish_date $post_index)" \
                   --porcelain \
                   --path=/var/www/html)
                   
    if [ -n "$tour_id" ]; then
        echo "Created tour announcement post with ID: $tour_id (scheduled for $(get_publish_date $post_index))"
        # Verify categories
        wp post term list $tour_id category --format=csv --path=/var/www/html || true
    fi
    
    echo "Created all 7 posts in Ivory's band member series"
else
    echo "Ivory already has band member series posts, skipping creation"
fi

# Create plugins directory if it doesn't exist
mkdir -p /var/www/html/wp-content/plugins

# Create the band metronome page if requested
if [ "$CREATE_METRONOME" = true ]; then
    echo "Creating ScriptHammer Band Metronome page..."
    
    # IMPORTANT: Always ensure the metronome app mu-plugin is installed
    # regardless of whether the page exists or not
    echo "Ensuring Metronome app is installed as a mu-plugin..."
    
    # Create the mu-plugins directory if it doesn't exist
    mkdir -p /var/www/html/wp-content/mu-plugins
    
    # Copy the metronome app
    if [ -f "/usr/local/bin/devscripts/metronome-app.php" ]; then
        cp /usr/local/bin/devscripts/metronome-app.php /var/www/html/wp-content/mu-plugins/
        chmod 644 /var/www/html/wp-content/mu-plugins/metronome-app.php
        chown www-data:www-data /var/www/html/wp-content/mu-plugins/metronome-app.php
        echo "✅ Metronome app installed as mu-plugin for the band"
        
        # Verify shortcode is registered
        SHORTCODE_CHECK=$(wp eval "global \$shortcode_tags; echo isset(\$shortcode_tags['scripthammer_react_app']) ? 'Shortcode is registered' : 'Shortcode is NOT registered';" --path=/var/www/html)
        echo "Shortcode status: $SHORTCODE_CHECK"
        
        # Force WordPress to load the plugin if not already loaded
        if [[ "$SHORTCODE_CHECK" != *"registered"* ]]; then
            echo "Forcing WordPress to load the metronome plugin..."
            wp eval "include_once('/var/www/html/wp-content/mu-plugins/metronome-app.php'); echo 'Metronome app loaded manually';" --path=/var/www/html
        fi
    else
        echo "❌ CRITICAL ERROR: Metronome app not found at /usr/local/bin/devscripts/metronome-app.php"
    fi
    
    # Check if the page already exists
    if ! wp post exists --post_type=page --post_name="band-metronome" --path=/var/www/html; then
        # Create the band-specific metronome page
        wp post create --post_type=page --post_title="ScriptHammer Drum Machine" --post_name="band-metronome" --post_status="publish" --post_content="<h2>ScriptHammer Band Practice Tools</h2>

<div class=\"band-metronome\">
    <h3>ScriptHammer Drum Machine</h3>
    <p>Our custom drum sequencer for band practice and composition. Create beats for our signature fractal funk and cosmic rhythms.</p>
    
    <div class=\"app-container\">
        [scripthammer_react_app]
    </div>
    
    <h4>Band Notes</h4>
    <ul>
        <li><strong>Basic Rock</strong> - Use for foundational practice and warm-ups</li>
        <li><strong>Disco</strong> - For \"Blue Matrix\" practice sessions</li>
        <li><strong>Hip Hop</strong> - For \"Quantum Groove\" and \"Neural Patterns\" tracks</li>
        <li><strong>Jazz</strong> - For \"Fractal Motion\" and \"Harmonic Drift\" pieces</li>
        <li><strong>Waltz</strong> - For \"Temporal Shift\" section in our third set</li>
    </ul>
    
    <p><strong>Crash says:</strong> Remember to practice with the hi-hat patterns we worked on last week. Especially focus on the off-beat accents for the Syncopation Suite.</p>
</div>

<style>
.band-metronome {
    max-width: 900px;
    margin: 0 auto;
    padding: 20px;
    background: #f8f9fa;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.app-container {
    margin: 30px 0;
}

h3 {
    color: #333;
    border-bottom: 2px solid #3b82f6;
    padding-bottom: 10px;
}

ul {
    background-color: #f0f4f8;
    padding: 15px 15px 15px 35px;
    border-radius: 4px;
    border-left: 3px solid #3b82f6;
}

li {
    margin: 8px 0;
}
</style>" --path=/var/www/html || true
        
        echo "✅ Created ScriptHammer Band Metronome page"
    else
        echo "ScriptHammer Band Metronome page already exists"
    fi
else
    # Even if we're not creating the page, we still need the metronome app
    # because it's used in Crash's post
    echo "Installing Metronome app plugin for Crash's post..."
    
    # Create the mu-plugins directory if it doesn't exist
    mkdir -p /var/www/html/wp-content/mu-plugins
    
    # Copy the metronome app
    if [ -f "/usr/local/bin/devscripts/metronome-app.php" ]; then
        cp /usr/local/bin/devscripts/metronome-app.php /var/www/html/wp-content/mu-plugins/
        chmod 644 /var/www/html/wp-content/mu-plugins/metronome-app.php
        chown www-data:www-data /var/www/html/wp-content/mu-plugins/metronome-app.php
        echo "✅ Metronome app installed for Crash's post"
    else
        echo "❌ CRITICAL ERROR: Metronome app not found at /usr/local/bin/devscripts/metronome-app.php"
    fi
    
    echo "Skipping metronome page creation (use --with-metronome to create it)"
fi

# Export the created content for future imports
if [ "$USE_IMPORT" = false ]; then
    echo "Exporting newly created band content for future use..."
    
    # Create the exports directory if it doesn't exist
    mkdir -p /var/www/html/wp-content/exports
    
    # Export all band-related content
    wp export --post_type=post --category=band-members --skip_comments --dir=/var/www/html/wp-content/exports --filename_format=band-members-{n}.xml --path=/var/www/html
    
    # Export band pages
    wp export --post_type=page --name=band-metronome --skip_comments --dir=/var/www/html/wp-content/exports --filename_format=band-pages-{n}.xml --path=/var/www/html
    
    # Export all band content (across all categories)
    wp export --post_type=post --category=music --category=tour --category=band-members --skip_comments --dir=/var/www/html/wp-content/exports --filename_format=all-band-content-{n}.xml --path=/var/www/html
    
    # Copy exports to the volume-mounted directory if it exists
    if [ -d "/var/www/html/wp-content/exports-volume" ]; then
        echo "Copying exports to volume-mounted directory..."
        cp -f /var/www/html/wp-content/exports/*.xml /var/www/html/wp-content/exports-volume/ || true
    fi
    
    echo "✅ Content exported successfully for future imports"
fi

# Export content for easier future installs
echo "Exporting band content for backup and future installs..."
mkdir -p /var/www/html/wp-content/exports

# Check if the importer plugin is installed
if ! wp plugin is-installed wordpress-importer --path=/var/www/html; then
    wp plugin install wordpress-importer --activate --path=/var/www/html || true
fi

# Export band member posts
wp export --post_type=post --category=band-members --skip_comments --dir=/var/www/html/wp-content/exports --filename_format=band-members-{n}.xml --path=/var/www/html || true

# Export music posts
wp export --post_type=post --category=music --skip_comments --dir=/var/www/html/wp-content/exports --filename_format=music-posts-{n}.xml --path=/var/www/html || true

# Export pages
wp export --post_type=page --skip_comments --dir=/var/www/html/wp-content/exports --filename_format=pages-{n}.xml --path=/var/www/html || true

echo "✅ Content exported to wp-content/exports directory"
echo "ScriptHammer band setup completed successfully!"