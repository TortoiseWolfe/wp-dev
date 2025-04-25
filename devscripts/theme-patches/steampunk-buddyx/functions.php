<?php
/**
 * Steampunk BuddyX child theme functions
 */

// Modify featured image behavior, but don't completely disable 
function steampunk_buddyx_modify_thumbnail_support() {
    // Don't remove support completely since we need thumbnails on home/archive
    // Just set a reasonable size for the homepage
    set_post_thumbnail_size(350, 350);
}
add_action('after_setup_theme', 'steampunk_buddyx_modify_thumbnail_support', 11);

// Remove featured image HTML only on single posts
function steampunk_buddyx_remove_thumbnail_html($html) {
    // Return empty string on single posts, but allow thumbnails on archive/home
    if (is_single()) {
        return '';
    }
    return $html;
}
add_filter('post_thumbnail_html', 'steampunk_buddyx_remove_thumbnail_html', 10);

// Enable Classic Widgets
function steampunk_buddyx_enable_classic_widgets() {
    // This will only have an effect if the Classic Widgets plugin is installed
    add_filter('use_widgets_block_editor', '__return_false');
}
add_action('after_setup_theme', 'steampunk_buddyx_enable_classic_widgets');

// Hide the duplicate H2 heading in all posts
function steampunk_buddyx_hide_duplicate_headings($content) {
    // Only apply to single posts
    if (is_single()) {
        // Get post title to match it in the content
        $post_title = get_the_title();
        
        // Only remove headings that exactly match the post title
        $content = preg_replace(
            '/<!-- wp:heading -->\s*<h2>' . preg_quote($post_title, '/') . '<\/h2>\s*<!-- \/wp:heading -->/s',
            '',
            $content,
            1
        );
    }
    return $content;
}
add_filter('the_content', 'steampunk_buddyx_hide_duplicate_headings', 5);