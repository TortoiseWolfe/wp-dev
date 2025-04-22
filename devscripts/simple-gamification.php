<?php
/*
Plugin Name: Simple Tutorial Gamification
Description: A simple gamification system for BuddyPress tutorials
Version: 1.0
Author: Claude
*/

// Don't allow direct access
if (!defined('ABSPATH')) {
    exit;
}

class Simple_BP_Gamification {
    public function __construct() {
        // Add our JavaScript and CSS
        add_action('wp_enqueue_scripts', array($this, 'enqueue_assets'));
        
        // Add gamification elements to tutorial pages
        add_filter('the_content', array($this, 'add_gamification_to_content'));
        
        // Add reset button to footer
        add_action('wp_footer', array($this, 'add_reset_button'));
        
        // Fix BuddyX theme category display issue - it only shows first category by default
        add_action('wp_head', array($this, 'fix_buddyx_category_display'));
    }
    
    /**
     * Enqueue JavaScript and CSS
     */
    public function enqueue_assets() {
        // Only load on tutorial pages or curriculum
        if ($this->is_tutorial_page()) {
            wp_enqueue_script(
                'simple-gamification',
                plugins_url('assets/simple-gamification.js', __FILE__),
                array('jquery'),
                '1.0',
                true
            );
            
            wp_enqueue_style(
                'simple-gamification',
                plugins_url('assets/simple-gamification.css', __FILE__),
                array(),
                '1.0'
            );
        }
    }
    
    /**
     * Check if current page is a tutorial page
     */
    private function is_tutorial_page() {
        // Check for tutorial pages - parent or child category of "buddypress-tutorials"
        if (is_singular('post')) {
            $categories = get_the_category();
            foreach ($categories as $category) {
                // Either the post is directly in buddypress-tutorials
                if ($category->slug === 'buddypress-tutorials') {
                    return true;
                }
                // Or its category is a child of buddypress-tutorials
                if ($category->parent && get_category($category->parent)->slug === 'buddypress-tutorials') {
                    return true;
                }
            }
        }
        // Also include the curriculum page
        return is_page('tutorial-course-curriculum');
    }
    
    /**
     * Add gamification elements to tutorial content
     */
    public function add_gamification_to_content($content) {
        // Only modify tutorial posts
        if (!$this->is_tutorial_page()) {
            return $content;
        }
        
        // Get tutorial info - always use post slug (standardized permalink) as the identifier
        // This ensures consistency across the entire system
        $tutorial_slug = get_post_field('post_name', get_the_ID());
        $tutorial_title = get_the_title();
        
        // Special handling for curriculum page - add header but not the completion button
        if (is_page('tutorial-course-curriculum')) {
            // Add header only
            $header = $this->get_gamification_header();
            return $header . $content;
        }
        
        // Get the next tutorial
        $next_tutorial = '';
        
        // Check if the content has the data-next-tutorial attribute
        if (preg_match('/data-next-tutorial=[\'"]([^\'"]+)[\'"]/', $content, $matches)) {
            $next_tutorial = $matches[1];
        } else {
            // Fall back to the predefined sequence
            $next_tutorial = $this->get_next_tutorial($tutorial_slug);
        }
        
        $next_url = $next_tutorial ? '/' . $next_tutorial . '/' : '/tutorial-course-curriculum/';
        
        // Add header
        $header = $this->get_gamification_header();
        
        // Add footer with completion button
        $footer = $this->get_gamification_footer($tutorial_slug, $next_url);
        
        // Combine content
        return $header . $content . $footer;
    }
    
    /**
     * Get header content
     */
    private function get_gamification_header() {
        ob_start();
        ?>
        <!-- GAMIFICATION HEADER -->
        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 30px; border-left: 4px solid #0073aa;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div style="font-size: 16px; font-weight: bold; color: #0073aa;">
                    BuddyPress Tutorial Series
                </div>
                <a href="/tutorial-course-curriculum/" style="text-decoration: none; font-size: 14px; color: #555;">
                    ← Back to Curriculum
                </a>
            </div>
            
            <div class="tutorial-progress-container" style="margin-top: 15px;">
                <div class="tutorial-progress-bar"></div>
            </div>
            <div style="display: flex; justify-content: space-between; font-size: 12px; color: #555; margin-top: 5px;">
                <span class="tutorial-progress-text">0 of 7 tutorials completed</span>
                <span class="tutorial-points-text">0 points earned</span>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }
    
    /**
     * Get footer content
     */
    private function get_gamification_footer($tutorial_slug, $next_url) {
        ob_start();
        ?>
        <!-- GAMIFICATION FOOTER -->
        <div class="tutorial-completion-box tutorial-content" data-tutorial-slug="<?php echo esc_attr($tutorial_slug); ?>">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                <h3 style="margin: 0; color: #333;">Tutorial Progress</h3>
                <a href="/tutorial-course-curriculum/" style="text-decoration: none; background-color: #0073aa; color: white; padding: 8px 15px; border-radius: 4px; font-size: 14px;">
                    View All Tutorials
                </a>
            </div>
            
            <div class="tutorial-progress-container">
                <div class="tutorial-progress-bar"></div>
            </div>
            
            <div style="display: flex; justify-content: space-between; font-size: 14px; color: #555; margin: 10px 0 20px;">
                <div class="tutorial-progress-text">0 of 7 tutorials completed</div>
                <div class="tutorial-points-text">0 points earned</div>
            </div>
            
            <!-- Message shown when completed -->
            <div class="completed-message" style="display: none;">
                <div style="display: flex; align-items: center;">
                    <span class="completed-icon">✓</span>
                    <p style="margin: 0; font-weight: 500;">Tutorial Complete! +100 points earned</p>
                </div>
            </div>
            
            <div style="text-align: center; margin-top: 20px;">
                <!-- Button to mark as complete -->
                <button class="mark-complete-button" data-tutorial-slug="<?php echo esc_attr($tutorial_slug); ?>">
                    Mark as Complete (+100 points)
                </button>
                
                <!-- Link to next tutorial, shown when completed -->
                <a href="<?php echo esc_url($next_url); ?>" class="next-tutorial-button" style="display: none;">
                    Continue to Next Tutorial →
                </a>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }
    
    /**
     * Get next tutorial in sequence
     */
    private function get_next_tutorial($tutorial_slug) {
        $tutorial_order = array(
            'introduction-to-buddypress' => 'installing-and-configuring-buddypress',
            'installing-and-configuring-buddypress' => 'customizing-member-profiles',
            'customizing-member-profiles' => 'creating-and-managing-groups',
            'creating-and-managing-groups' => 'setting-up-group-discussions',
            'setting-up-group-discussions' => 'introduction-to-buddyx-theme',
            'introduction-to-buddyx-theme' => 'customizing-buddyx-appearance',
            'customizing-buddyx-appearance' => '' // No next tutorial
        );
        
        return isset($tutorial_order[$tutorial_slug]) ? $tutorial_order[$tutorial_slug] : '';
    }
    
    /**
     * Add reset button to footer
     */
    public function add_reset_button() {
        if ($this->is_tutorial_page()) {
            echo '<div style="text-align: center; margin: 30px 0;">
                <button class="reset-progress-button" style="background-color: #f44336; color: white; padding: 8px 15px; border-radius: 4px; border: none; font-size: 14px; cursor: pointer;">
                    Reset Progress
                </button>
            </div>';
        }
    }
    
    /**
     * Fix BuddyX theme's category display limitation
     * By default, BuddyX theme only shows the first category even if a post has multiple categories
     */
    public function fix_buddyx_category_display() {
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
                
                // Run the function
                addAllCategories();
            });
        </script>
        <?php
        ob_end_flush();
    }
}

// Initialize the plugin
new Simple_BP_Gamification();