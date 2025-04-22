#!/bin/bash
# ScriptHammer band members creation script
set -e

# Add fix for permissions - make script executable inside container
chmod +x "$(realpath "$0")" 2>/dev/null || true

# Enable debugging if requested
if [ "$1" = "debug" ]; then
    set -x
fi

# Force activation of all required components before proceeding
echo "Ensuring all BuddyPress components are activated..."
for component in xprofile members groups friends messages activity notifications settings blogs; do
    wp bp component activate $component --path=/var/www/html || true
    sleep 1
done

echo "Creating ScriptHammer band members..."

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

# Array of required components
required_components=(
    "xprofile"
    "members"
    "groups"
    "friends"
    "messages"
    "activity"
    "notifications"
    "settings"
    "blogs"
)

# Activate each component if not already active
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

# Verify all critical components are active
critical_components=("groups" "friends" "messages" "activity")
for component in "${critical_components[@]}"; do
    if ! wp bp component list --path=/var/www/html | grep -q "$component.*active"; then
        echo "Critical component $component could not be activated. Exiting."
        exit 1
    fi
done

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
EOT
)

# No category variables needed - we'll get them by slug when needed

# Create Ivory's blog posts
echo "Creating Ivory's blog posts about the band..."

# Create both posts with a more robust approach
# Get count of Ivory's posts
existing_posts=$(wp post list --post_type=post --author="$creator_id" --format=count --path=/var/www/html)
echo "Found $existing_posts existing posts by Ivory"

# Only create posts if Ivory doesn't have any yet
if [ "$existing_posts" -lt "2" ]; then
    echo "Creating new posts for Ivory..."
    
    # Get the default category ID (Uncategorized)
    DEFAULT_CAT_ID=$(wp term get category --by=slug --slug=uncategorized --field=term_id --path=/var/www/html || echo "1")
    echo "Using Uncategorized category ID: $DEFAULT_CAT_ID"
    
    # Directly create both posts in sequence
    echo "Creating band formation post..."
    
    # First, explicitly create needed categories with correct slugs
    echo "Creating all needed categories first..."
    wp term create category "Music" --slug="music" --path=/var/www/html || true
    wp term create category "Tour" --slug="tour" --path=/var/www/html || true
    
    # Get category IDs by numeric ID (more reliable)
    MUSIC_CAT_ID=$(wp term list category --slug=music --fields=term_id --format=ids --path=/var/www/html)
    TOUR_CAT_ID=$(wp term list category --slug=tour --fields=term_id --format=ids --path=/var/www/html)
    
    echo "Using category IDs - Music: $MUSIC_CAT_ID, Tour: $TOUR_CAT_ID"
    
    # Now create post with explicit category assignment
    formation_id=$(wp post create --post_title="The Birth of ScriptHammer: How We Came Together" \
                   --post_content="$band_formation_post_content" \
                   --post_status="publish" \
                   --post_author="$creator_id" \
                   --post_category=$MUSIC_CAT_ID \
                   --porcelain \
                   --path=/var/www/html)
                   
    if [ -n "$formation_id" ]; then
        echo "Created band formation post with ID: $formation_id"
    fi
    
    echo "Creating tour announcement post..."
    # Create post with both categories at once - use a specific slug to avoid conflict with group slug
    tour_id=$(wp post create --post_title="ScriptHammer Announces: The Aether Trail Tour of 1848" \
                   --post_content="$tour_announcement_post_content" \
                   --post_status="publish" \
                   --post_author="$creator_id" \
                   --post_name="aether-trail-tour-1848" \
                   --post_category="$MUSIC_CAT_ID,$TOUR_CAT_ID" \
                   --porcelain \
                   --path=/var/www/html)
    
    if [ -n "$tour_id" ]; then
        echo "Created tour announcement post with ID: $tour_id with categories Music and Tour"
        
        # Verify categories
        wp post term list $tour_id category --format=csv --path=/var/www/html || true
        
        echo "Added proper categories to both posts"
    fi
    
    echo "Created Ivory's blog posts successfully"
else
    echo "Ivory already has posts, skipping creation"
fi

echo "ScriptHammer band setup completed successfully!"