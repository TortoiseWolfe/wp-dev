<?php
/**
 * Steampunk BuddyX child theme functions
 */

// Force background colors through inline CSS (most reliable method)
function steampunk_buddyx_add_custom_background() {
    echo '<style>
        /* Main backgrounds with darker sepia tone */
        html, body, #page, .site, #content, #primary, .buddyx-content, main#main, 
        .entry-wrapper, .entry-content-wrapper, .entry-content,
        .buddyx-article, .site-wrapper-frame, .section-title, .white-section, .single article,
        .buddyx-posts-list, .buddyx-posts-list__item, .container-fluid, .site-footer, .buddyx-header {
            background-color: #e6dbc9 !important; /* Darker sepia tone */
        }
        
        /* UI elements with slightly darker color */
        .site-header, 
        .site-branding, 
        .site-branding-inner,
        .site-logo-wrapper, 
        nav, .navigation, .navbar, 
        .site-info, 
        .footer-widget, .footer-wrap,
        .buddyx-search-results, 
        .popup-content, 
        .card-header, .card-footer, 
        .panel {
            background-color: #d9cdb9 !important; /* Slightly darker for UI elements */
            opacity: 1 !important;
        }
        
        /* Fix for the header vertical white bars */
        .site-header-wrapper {
            background-color: #d9cdb9 !important;
            box-shadow: 0 1px 0 0 rgba(206, 206, 206, 0.05), 0 5px 10px 0 rgba(132, 132, 132, 0.15) !important;
            width: 100% !important;
            margin: 0 !important;
            padding: 0 !important;
            left: 0 !important;
            right: 0 !important;
            position: relative !important;
        }
        
        /* Fix for any potential interior elements */
        .site-header-wrapper .container {
            background-color: #d9cdb9 !important;
        }
    </style>';
}
add_action('wp_head', 'steampunk_buddyx_add_custom_background', 999999);

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