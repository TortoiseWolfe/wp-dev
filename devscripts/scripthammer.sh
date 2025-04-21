#!/bin/bash
# ScriptHammer band members creation script
set -e
set -x

echo "Creating ScriptHammer band members..."

# Make sure BuddyPress is active
echo "Verifying BuddyPress is active..."
if ! wp plugin is-active buddypress --path=/var/www/html; then
    echo "BuddyPress is not active. Activating..."
    wp plugin activate buddypress --path=/var/www/html || {
        echo "Failed to activate BuddyPress. Exiting."
        exit 1
    }
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

# Directly clear all BuddyPress cache entries in the database 
wp db query "DELETE FROM wp_options WHERE option_name LIKE '%bp%cache%'" --path=/var/www/html || true
wp db query "DELETE FROM wp_options WHERE option_name LIKE '%bp%transient%'" --path=/var/www/html || true
wp db query "DELETE FROM wp_options WHERE option_name LIKE '_transient_bp_%'" --path=/var/www/html || true
wp db query "DELETE FROM wp_options WHERE option_name LIKE '_site_transient_bp_%'" --path=/var/www/html || true
wp db query "DELETE FROM wp_options WHERE option_name LIKE 'bp_groups_memberships_for_user_%'" --path=/var/www/html || true
wp db query "UPDATE wp_options SET option_value = NOW() WHERE option_name = 'bp-groups-last-activity'" --path=/var/www/html || true

# Make sure BuddyPress can see the members - very important for UI display
wp eval "
// Get current number of members
\$members = BP_Groups_Group::get_group_members($group_id);
\$count = count(\$members['members']);
echo 'Group members found: ' . \$count . '\\n';

// Update the group membership count in BuddyPress
if (function_exists('groups_update_groupmeta')) {
    groups_update_groupmeta($group_id, 'total_member_count', $total_members);
}

// Force cache clearing for all users
foreach(explode(',','${band_user_ids[@]}') as \$user_id_str) {
    \$user_id = trim(\$user_id_str);
    if (is_numeric(\$user_id)) {
        echo 'Clearing cache for user ' . \$user_id . '\\n';
        wp_cache_delete('bp_groups_memberships_' . \$user_id);
        wp_cache_delete('bp_group_' . \$group_id . '_has_member_' . \$user_id);
    }
}
" --path=/var/www/html || true

# Final flush to make sure everything is clean
wp cache flush --path=/var/www/html || true
wp eval "groups_update_groupmeta($group_id, 'last_activity', bp_core_current_time());" --path=/var/www/html || true

# Verify group details
echo "ScriptHammer group details:"
wp bp group get $group_id --path=/var/www/html || true
echo "Members in group $group_id:"
wp bp group member list --group-id=$group_id --path=/var/www/html || true

echo "ScriptHammer band setup completed successfully!"