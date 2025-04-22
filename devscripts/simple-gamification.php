<?php
/**
 * Plugin Name: Simple Gamification
 * Description: Custom gamification and BuddyPress integration for ScriptHammer
 * Version: 1.0
 * Author: The ScriptHammer Team
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

// Ensure BuddyPress components are always active
add_action('plugins_loaded', function() {
    // Only run this if BuddyPress is active
    if (!function_exists('buddypress')) {
        return;
    }

    // Get the active components
    $active_components = bp_get_option('bp-active-components', array());
    
    // Required components
    $required_components = array(
        'xprofile'      => 1,
        'settings'      => 1,
        'members'       => 1,
        'groups'        => 1,
        'activity'      => 1,
        'notifications' => 1,
        'friends'       => 1,
        'messages'      => 1,
        'blogs'         => 1
    );
    
    // Check if any required components are missing
    $needs_update = false;
    foreach ($required_components as $component => $active) {
        if (!isset($active_components[$component]) || !$active_components[$component]) {
            $active_components[$component] = 1;
            $needs_update = true;
        }
    }
    
    // Save active components if changes were made
    if ($needs_update) {
        bp_update_option('bp-active-components', $active_components);
    }
}, 99); // Run after BuddyPress initializes

// Add points for creating a post
add_action('wp_insert_post', function($post_id, $post) {
    // Only award points if the post is published and is a standard post
    if ($post->post_status !== 'publish' || $post->post_type !== 'post') {
        return;
    }
    
    // Award points to the post author
    $author_id = $post->post_author;
    
    // Get current points or initialize with 0
    $user_points = get_user_meta($author_id, 'sh_user_points', true);
    if (empty($user_points)) {
        $user_points = 0;
    }
    
    // Add 10 points for creating a post
    $user_points += 10;
    
    // Update the user's points
    update_user_meta($author_id, 'sh_user_points', $user_points);
    
    // Log activity if BuddyPress is active
    if (function_exists('bp_activity_add')) {
        bp_activity_add(array(
            'action'       => sprintf(__('%s earned 10 points for publishing a new post!', 'simple-gamification'), bp_core_get_userlink($author_id)),
            'primary_link' => get_permalink($post_id),
            'component'    => 'activity',
            'type'         => 'points_earned',
            'user_id'      => $author_id,
            'item_id'      => $post_id
        ));
    }
}, 10, 2);

// Add points for commenting
add_action('wp_insert_comment', function($comment_id, $comment) {
    // Only award points if the comment is approved
    if ($comment->comment_approved !== '1') {
        return;
    }
    
    // Award points to the comment author (if logged in)
    $author_id = $comment->user_id;
    if ($author_id === 0) {
        return; // Don't award points to non-logged-in users
    }
    
    // Get current points or initialize with 0
    $user_points = get_user_meta($author_id, 'sh_user_points', true);
    if (empty($user_points)) {
        $user_points = 0;
    }
    
    // Add 5 points for posting a comment
    $user_points += 5;
    
    // Update the user's points
    update_user_meta($author_id, 'sh_user_points', $user_points);
    
    // Log activity if BuddyPress is active
    if (function_exists('bp_activity_add')) {
        bp_activity_add(array(
            'action'       => sprintf(__('%s earned 5 points for commenting on a post!', 'simple-gamification'), bp_core_get_userlink($author_id)),
            'primary_link' => get_comment_link($comment_id),
            'component'    => 'activity',
            'type'         => 'points_earned',
            'user_id'      => $author_id,
            'item_id'      => $comment_id
        ));
    }
}, 10, 2);

// Add points for joining or creating a group
add_action('groups_join_group', function($group_id, $user_id) {
    // Get current points or initialize with 0
    $user_points = get_user_meta($user_id, 'sh_user_points', true);
    if (empty($user_points)) {
        $user_points = 0;
    }
    
    // Add 15 points for joining a group
    $user_points += 15;
    
    // Update the user's points
    update_user_meta($user_id, 'sh_user_points', $user_points);
    
    // Log activity
    if (function_exists('bp_activity_add')) {
        $group = groups_get_group($group_id);
        bp_activity_add(array(
            'action'       => sprintf(__('%s earned 15 points for joining the group %s!', 'simple-gamification'), 
                             bp_core_get_userlink($user_id), 
                             '<a href="' . bp_get_group_permalink($group) . '">' . $group->name . '</a>'),
            'component'    => 'activity',
            'type'         => 'points_earned',
            'user_id'      => $user_id,
            'item_id'      => $group_id
        ));
    }
}, 10, 2);

// Add points for creating a group
add_action('groups_group_create_complete', function($group_id) {
    // Get the group creator
    $group = groups_get_group($group_id);
    $creator_id = $group->creator_id;
    
    // Get current points or initialize with 0
    $user_points = get_user_meta($creator_id, 'sh_user_points', true);
    if (empty($user_points)) {
        $user_points = 0;
    }
    
    // Add 30 points for creating a group
    $user_points += 30;
    
    // Update the user's points
    update_user_meta($creator_id, 'sh_user_points', $user_points);
    
    // Log activity
    if (function_exists('bp_activity_add')) {
        bp_activity_add(array(
            'action'       => sprintf(__('%s earned 30 points for creating the group %s!', 'simple-gamification'), 
                             bp_core_get_userlink($creator_id), 
                             '<a href="' . bp_get_group_permalink($group) . '">' . $group->name . '</a>'),
            'component'    => 'activity',
            'type'         => 'points_earned',
            'user_id'      => $creator_id,
            'item_id'      => $group_id
        ));
    }
});

// Add points for creating a friendship
add_action('friends_friendship_accepted', function($friendship_id, $initiator_user_id, $friend_user_id) {
    // Award points to both users
    foreach ([$initiator_user_id, $friend_user_id] as $user_id) {
        // Get current points or initialize with 0
        $user_points = get_user_meta($user_id, 'sh_user_points', true);
        if (empty($user_points)) {
            $user_points = 0;
        }
        
        // Add 10 points for making a friend
        $user_points += 10;
        
        // Update the user's points
        update_user_meta($user_id, 'sh_user_points', $user_points);
    }
    
    // Log activity for initiator
    if (function_exists('bp_activity_add')) {
        bp_activity_add(array(
            'action'       => sprintf(__('%s earned 10 points for becoming friends with %s!', 'simple-gamification'), 
                             bp_core_get_userlink($initiator_user_id), 
                             bp_core_get_userlink($friend_user_id)),
            'component'    => 'activity',
            'type'         => 'points_earned',
            'user_id'      => $initiator_user_id,
            'item_id'      => $friendship_id
        ));
        
        // Log activity for friend (separate activity for each user)
        bp_activity_add(array(
            'action'       => sprintf(__('%s earned 10 points for becoming friends with %s!', 'simple-gamification'), 
                             bp_core_get_userlink($friend_user_id), 
                             bp_core_get_userlink($initiator_user_id)),
            'component'    => 'activity',
            'type'         => 'points_earned',
            'user_id'      => $friend_user_id,
            'item_id'      => $friendship_id
        ));
    }
}, 10, 3);

// Display user points in the profile
add_action('bp_before_member_header_meta', function() {
    // Get current user ID
    $user_id = bp_displayed_user_id();
    
    // Get user points
    $user_points = get_user_meta($user_id, 'sh_user_points', true);
    if (empty($user_points)) {
        $user_points = 0;
    }
    
    // Display points
    echo '<div class="user-points">';
    echo '<h4>' . __('ScriptHammer Points', 'simple-gamification') . '</h4>';
    echo '<span class="points-value">' . number_format($user_points) . '</span>';
    echo '</div>';
});

// Add the User Points column to the members directory
add_action('bp_members_directory_member_types', function() {
    ?>
    <li id="members-sh-points">
        <a href="#" data-bp-sort="sh_user_points"><?php _e('Most Points', 'simple-gamification'); ?></a>
    </li>
    <?php
});

// Fix BuddyX theme's category display limitation - only shows the first category by default
add_action('wp_head', function() {
    // Buffer the output to prevent potential issues
    ob_start();
    ?>
    <style>
        .post-meta-category {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }
        .post-meta-category__item {
            display: inline-block !important;
            margin-right: 5px;
        }
    </style>
    <script>
        // More aggressive fix - actually add all categories to the post display
        document.addEventListener('DOMContentLoaded', function() {
            // Function to get all categories for a post
            async function fetchCategories(postId) {
                try {
                    // Use WordPress REST API to get the post's categories
                    const response = await fetch('/wp-json/wp/v2/posts/' + postId + '?_embed');
                    if (!response.ok) return null;
                    
                    const postData = await response.json();
                    if (!postData.categories || !postData._embedded || !postData._embedded['wp:term']) {
                        return null;
                    }
                    
                    // Find the category terms
                    let categories = [];
                    for (const termGroup of postData._embedded['wp:term']) {
                        for (const term of termGroup) {
                            if (term.taxonomy === 'category') {
                                categories.push(term);
                            }
                        }
                    }
                    
                    return categories;
                } catch (error) {
                    console.error('Error fetching categories:', error);
                    return null;
                }
            }
            
            // Add all categories to the post header
            const addAllCategories = async () => {
                // Check if we're on a single post page
                const postContainer = document.querySelector('article.post');
                if (!postContainer) return;
                
                // Get the post ID
                const postId = postContainer.id.replace('post-', '');
                if (!postId) return;
                
                // Get categories
                const categories = await fetchCategories(postId);
                if (!categories || categories.length <= 1) return;
                
                // Find the category container
                const categoryContainer = document.querySelector('.post-meta-category');
                if (!categoryContainer) return;
                
                console.log('Found categories:', categories);
                
                // Clear existing content and add all categories
                categoryContainer.innerHTML = '';
                
                // Add all categories
                categories.forEach(category => {
                    const categoryItem = document.createElement('div');
                    categoryItem.className = 'post-meta-category__item';
                    categoryItem.innerHTML = `
                        <a href="/category/${category.slug}/" class="post-meta-category__link">
                            ${category.name}
                        </a>
                    `;
                    categoryContainer.appendChild(categoryItem);
                });
            };
            
            // Make it run repeatedly to catch any late loading situations
            setTimeout(() => {
                addAllCategories();
            }, 500);
            
            setTimeout(() => {
                addAllCategories();
            }, 1000);
            
            // Run the function immediately
            addAllCategories();
        });
    </script>
    <?php
    ob_end_flush();
});


// Ensure BuddyPress components are activated when WP is fully loaded (extra safety measure)
add_action('wp_loaded', function() {
    // Run this check only occasionally to avoid performance issues
    // Use transients to control the frequency (once per hour)
    $transient_key = 'sh_bp_components_check';
    if (get_transient($transient_key)) {
        return;
    }
    
    // Set transient to avoid frequent checks
    set_transient($transient_key, true, HOUR_IN_SECONDS);
    
    // Only run if BuddyPress is active
    if (!function_exists('buddypress')) {
        return;
    }
    
    // Get current active components
    $active_components = bp_get_option('bp-active-components', array());
    
    // Required components
    $required_components = array(
        'xprofile'      => 1,
        'settings'      => 1,
        'members'       => 1,
        'groups'        => 1,
        'activity'      => 1,
        'notifications' => 1,
        'friends'       => 1,
        'messages'      => 1,
        'blogs'         => 1
    );
    
    // Check if any required components are missing
    $needs_update = false;
    foreach ($required_components as $component => $active) {
        if (!isset($active_components[$component]) || !$active_components[$component]) {
            $active_components[$component] = 1;
            $needs_update = true;
        }
    }
    
    // Save active components if changes were made
    if ($needs_update) {
        // Use the BP function to ensure proper handling
        bp_update_option('bp-active-components', $active_components);
        
        // Also delete component caches
        wp_cache_delete('bp_active_components', 'bp');
    }
});