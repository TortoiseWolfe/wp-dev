#!/bin/bash
set -e

echo "Starting WordPress demo content cleanup..."

# Check if WordPress is installed
if ! wp core is-installed --path=/var/www/html; then
    echo "WordPress is not installed. Nothing to clean up."
    exit 1
fi

# Function to confirm before proceeding
confirm() {
    read -p "This will delete ALL demo content. Are you sure? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi
}

# Skip confirmation in non-interactive mode
if [ -t 0 ]; then
    confirm
fi

echo "Deleting sample pages..."
# Get all pages except the default Sample Page and Privacy Policy
sample_pages=$(wp post list --post_type=page --post__not_in=2,3 --field=ID --path=/var/www/html)
if [ -n "$sample_pages" ]; then
    for page_id in $sample_pages; do
        wp post delete $page_id --force --path=/var/www/html
    done
    echo "Sample pages deleted."
else
    echo "No sample pages to delete."
fi

echo "Deleting demo posts and their comments..."
# Delete all posts except the default "Hello World" post (usually ID 1)
demo_posts=$(wp post list --post_type=post --post__not_in=1 --field=ID --path=/var/www/html)
if [ -n "$demo_posts" ]; then
    for post_id in $demo_posts; do
        wp post delete $post_id --force --path=/var/www/html
    done
    echo "Demo posts deleted."
else
    echo "No demo posts to delete."
fi

echo "Checking if BuddyPress is active..."
if wp plugin is-active buddypress --path=/var/www/html; then
    echo "Deleting BuddyPress groups..."
    # Get all BuddyPress groups
    bp_groups=$(wp bp group list --field=id --path=/var/www/html)
    if [ -n "$bp_groups" ]; then
        for group_id in $bp_groups; do
            wp bp group delete $group_id --yes --path=/var/www/html
        done
        echo "BuddyPress groups deleted."
    else
        echo "No BuddyPress groups to delete."
    fi
    
    echo "Deleting BuddyPress activities..."
    # Delete all BuddyPress activities
    wp bp activity delete --yes --path=/var/www/html
    echo "BuddyPress activities deleted."
    
    echo "Checking if BuddyPress Messages component is active..."
    if wp bp component list --format=json --path=/var/www/html | grep -q '"component_id":"messages".*"is_active":true'; then
        echo "Deleting BuddyPress messages..."
        # This might be a bit tricky as WP-CLI doesn't have a direct command to delete all messages
        # We use wp db query as a workaround
        tables_prefix=$(wp config get table_prefix --path=/var/www/html)
        wp db query "TRUNCATE TABLE ${tables_prefix}bp_messages_messages" --path=/var/www/html
        wp db query "TRUNCATE TABLE ${tables_prefix}bp_messages_meta" --path=/var/www/html
        wp db query "TRUNCATE TABLE ${tables_prefix}bp_messages_recipients" --path=/var/www/html
        wp db query "TRUNCATE TABLE ${tables_prefix}bp_notifications" --path=/var/www/html
        echo "BuddyPress messages deleted."
    fi
    
    echo "Deleting BuddyPress friendships..."
    if wp bp component list --format=json --path=/var/www/html | grep -q '"component_id":"friends".*"is_active":true'; then
        tables_prefix=$(wp config get table_prefix --path=/var/www/html)
        wp db query "TRUNCATE TABLE ${tables_prefix}bp_friends" --path=/var/www/html
        echo "BuddyPress friendships deleted."
    fi
fi

echo "Deleting demo users..."
# Get all users except admin (ID 1)
demo_users=$(wp user list --field=ID --exclude=1 --path=/var/www/html)
if [ -n "$demo_users" ]; then
    for user_id in $demo_users; do
        wp user delete $user_id --yes --path=/var/www/html
    done
    echo "Demo users deleted."
else
    echo "No demo users to delete."
fi

echo "Resetting WordPress permalinks..."
wp rewrite flush --path=/var/www/html

# region: TUTORIAL CONTENT CLEANUP
echo "Cleaning up tutorial content..."

# Delete tutorial curriculum page
curriculum_page=$(wp post list --post_type=page --s="Tutorial Course Curriculum" --field=ID --path=/var/www/html)
if [ -n "$curriculum_page" ]; then
    wp post delete $curriculum_page --force --path=/var/www/html
    echo "Tutorial curriculum page deleted."
else
    echo "No tutorial curriculum page found."
fi

# Delete tutorial categories and posts
tutorial_cat=$(wp term list category --name="BuddyPress Tutorials" --field=term_id --path=/var/www/html)
if [ -n "$tutorial_cat" ]; then
    # Get all subcategories
    subcats=$(wp term list category --parent=$tutorial_cat --field=term_id --path=/var/www/html)
    
    # Delete posts in the main category and subcategories
    wp post list --post_type=post --category=$tutorial_cat --field=ID --path=/var/www/html | xargs -I % wp post delete % --force --path=/var/www/html 2>/dev/null || true
    
    # Delete posts in subcategories
    for subcat in $subcats; do
        wp post list --post_type=post --category=$subcat --field=ID --path=/var/www/html | xargs -I % wp post delete % --force --path=/var/www/html 2>/dev/null || true
    done
    
    # Delete subcategories
    for subcat in $subcats; do
        wp term delete category $subcat --path=/var/www/html
    done
    
    # Delete main tutorial category
    wp term delete category $tutorial_cat --path=/var/www/html
    echo "Tutorial categories and posts deleted."
else
    echo "No tutorial categories found."
fi
# endregion: TUTORIAL CONTENT CLEANUP

echo "Demo content cleanup completed!"
echo "Your WordPress site has been reset to a clean installation."
echo "Only the default admin user, 'Hello World' post, Sample Page, and Privacy Policy page remain."