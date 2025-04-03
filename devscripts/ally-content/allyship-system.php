<?php
/**
 * Allyship Curriculum System
 * 
 * A completely independent curriculum system for allyship training.
 * Follows standard e-learning practices with modular lesson structure.
 */

// Don't allow direct access
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Main Allyship System class
 */
class Allyship_System {
    // These arrays will store the lesson ordering
    private $modules = [];
    private $lessons_by_module = [];
    private $lesson_order = [];
    
    /**
     * Constructor
     */
    public function __construct() {
        // Initialize the curriculum structure
        $this->init_curriculum_structure();
    }
    
    /**
     * Initialize the curriculum structure
     * This defines the module and lesson hierarchy
     */
    private function init_curriculum_structure() {
        // Define modules
        $this->modules = [
            'defining-allyship' => [
                'name' => 'Defining Allyship',
                'description' => 'Understanding what allyship means and how to practice it',
                'order' => 1
            ]
        ];
        
        // Define lessons by module (slug => details)
        $this->lessons_by_module = [
            'defining-allyship' => [
                'what-is-allyship-intro' => [
                    'title' => 'Introduction to Allyship',
                    'type' => 'content',
                    'order' => 1
                ],
                'what-is-allyship-video' => [
                    'title' => 'Video: What Does It Mean to Be an Ally?',
                    'type' => 'video',
                    'order' => 2
                ],
                'what-is-allyship-reflection' => [
                    'title' => 'Reflection: Your Allyship Moment',
                    'type' => 'reflection', 
                    'order' => 3
                ],
                'what-is-allyship-novella' => [
                    'title' => 'Graphic Novella: Just Another Meeting?',
                    'type' => 'content',
                    'order' => 4
                ],
                'what-is-allyship-quiz' => [
                    'title' => 'Quiz: Ally in Action',
                    'type' => 'quiz',
                    'order' => 5
                ],
                'what-is-allyship-commitment' => [
                    'title' => 'Commitment Builder: What\'s One Thing You\'ll Do?',
                    'type' => 'commitment',
                    'order' => 6
                ]
            ]
        ];
        
        // Build the full curriculum order
        $this->build_lesson_order();
    }
    
    /**
     * Build the lesson order array
     */
    private function build_lesson_order() {
        $this->lesson_order = [];
        $index = 0;
        
        // Sort modules by order
        uasort($this->modules, function($a, $b) {
            return $a['order'] - $b['order'];
        });
        
        // For each module
        foreach ($this->modules as $module_slug => $module) {
            // Sort lessons in this module by order
            $module_lessons = $this->lessons_by_module[$module_slug];
            uasort($module_lessons, function($a, $b) {
                return $a['order'] - $b['order']; 
            });
            
            // Add each lesson to the order
            foreach ($module_lessons as $lesson_slug => $lesson) {
                $this->lesson_order[$index] = [
                    'module_slug' => $module_slug,
                    'lesson_slug' => $lesson_slug
                ];
                $index++;
            }
        }
    }
    
    /**
     * Setup the entire allyship system
     */
    public function setup() {
        // Create custom post types
        $this->register_post_types();
        
        // Create allyship curriculum content
        $this->create_curriculum_content();
        
        // Create assets
        $this->create_assets();
        
        // Setup plugin
        $this->create_plugin();
    }
    
    /**
     * Register custom post types and taxonomies
     */
    private function register_post_types() {
        // Allyship Lesson post type
        register_post_type('allyship_lesson', array(
            'labels' => array(
                'name'               => 'Allyship Lessons',
                'singular_name'      => 'Allyship Lesson',
                'menu_name'          => 'Allyship',
                'add_new'            => 'Add New Lesson',
                'add_new_item'       => 'Add New Allyship Lesson',
                'edit_item'          => 'Edit Allyship Lesson',
                'new_item'           => 'New Allyship Lesson',
                'view_item'          => 'View Allyship Lesson',
                'search_items'       => 'Search Allyship Lessons',
                'not_found'          => 'No allyship lessons found',
                'not_found_in_trash' => 'No allyship lessons found in trash'
            ),
            'public'              => true,
            'has_archive'         => true,
            'publicly_queryable'  => true,
            'hierarchical'        => false,
            'supports'            => array('title', 'editor', 'thumbnail', 'excerpt', 'author'),
            'rewrite'             => array('slug' => 'allyship-lesson'),
            'show_in_rest'        => true,
            'menu_icon'           => 'dashicons-groups',
            'capability_type'     => 'post'
        ));
        
        // Module taxonomy
        register_taxonomy('allyship_module', 'allyship_lesson', array(
            'labels' => array(
                'name'          => 'Modules',
                'singular_name' => 'Module',
                'search_items'  => 'Search Modules',
                'all_items'     => 'All Modules',
                'edit_item'     => 'Edit Module',
                'update_item'   => 'Update Module',
                'add_new_item'  => 'Add New Module',
                'new_item_name' => 'New Module Name',
                'menu_name'     => 'Modules'
            ),
            'hierarchical'      => true,
            'show_ui'           => true,
            'show_admin_column' => true,
            'query_var'         => true,
            'rewrite'           => array('slug' => 'allyship-module')
        ));
        
        // Lesson Type taxonomy
        register_taxonomy('allyship_lesson_type', 'allyship_lesson', array(
            'labels' => array(
                'name'          => 'Lesson Types',
                'singular_name' => 'Lesson Type',
                'search_items'  => 'Search Lesson Types',
                'all_items'     => 'All Lesson Types',
                'edit_item'     => 'Edit Lesson Type',
                'update_item'   => 'Update Lesson Type',
                'add_new_item'  => 'Add New Lesson Type',
                'new_item_name' => 'New Lesson Type Name',
                'menu_name'     => 'Lesson Types'
            ),
            'hierarchical'      => false,
            'show_ui'           => true,
            'show_admin_column' => true,
            'query_var'         => true,
            'rewrite'           => array('slug' => 'allyship-lesson-type')
        ));
        
        // Flush rewrite rules to ensure post types and taxonomies work correctly
        flush_rewrite_rules();
        
        echo "Registered Allyship post types and taxonomies\n";
    }
    
    /**
     * Create the entire curriculum content
     */
    private function create_curriculum_content() {
        // Create the main curriculum page
        $this->create_curriculum_page();
        
        // Create module terms
        $this->create_module_terms();
        
        // Create lesson type terms
        $this->create_lesson_type_terms();
        
        // Create individual lessons
        $this->create_individual_lessons();
    }
    
    /**
     * Create module taxonomy terms
     */
    private function create_module_terms() {
        foreach ($this->modules as $slug => $module) {
            $module_exists = term_exists($slug, 'allyship_module');
            if (!$module_exists) {
                $result = wp_insert_term($module['name'], 'allyship_module', array(
                    'slug' => $slug,
                    'description' => $module['description']
                ));
                
                if (is_wp_error($result)) {
                    echo "Error creating module {$module['name']}: " . $result->get_error_message() . "\n";
                } else {
                    echo "Created '{$module['name']}' module\n";
                }
            } else {
                echo "Module '{$module['name']}' already exists\n";
            }
        }
    }
    
    /**
     * Create lesson type taxonomy terms
     */
    private function create_lesson_type_terms() {
        $lesson_types = [
            'content' => 'Content',
            'video' => 'Video',
            'reflection' => 'Reflection',
            'quiz' => 'Quiz',
            'commitment' => 'Commitment Builder'
        ];
        
        foreach ($lesson_types as $slug => $name) {
            $type_exists = term_exists($slug, 'allyship_lesson_type');
            if (!$type_exists) {
                $result = wp_insert_term($name, 'allyship_lesson_type', array(
                    'slug' => $slug
                ));
                
                if (is_wp_error($result)) {
                    echo "Error creating lesson type {$name}: " . $result->get_error_message() . "\n";
                } else {
                    echo "Created '{$name}' lesson type\n";
                }
            } else {
                echo "Lesson type '{$name}' already exists\n";
            }
        }
    }
    
    /**
     * Create the main curriculum page
     */
    private function create_curriculum_page() {
        $page_exists = get_page_by_path('allyship-curriculum');
        
        if ($page_exists) {
            echo "Allyship Curriculum page already exists\n";
            return;
        }
        
        $page_content = $this->get_curriculum_page_content();
        
        $page_id = wp_insert_post(array(
            'post_title'     => 'Allyship Curriculum',
            'post_content'   => $page_content,
            'post_status'    => 'publish',
            'post_type'      => 'page',
            'post_name'      => 'allyship-curriculum',
            'comment_status' => 'closed'
        ));
        
        if (is_wp_error($page_id)) {
            echo "Error creating curriculum page: " . $page_id->get_error_message() . "\n";
            return;
        }
        
        echo "Created Allyship Curriculum page with ID: $page_id\n";
        
        // Add the page to the primary menu
        $primary_menu = wp_get_nav_menu_object('primary');
        if ($primary_menu) {
            wp_update_nav_menu_item($primary_menu->term_id, 0, array(
                'menu-item-title'  => 'Allyship Curriculum',
                'menu-item-url'    => home_url('/allyship-curriculum/'),
                'menu-item-status' => 'publish',
                'menu-item-type'   => 'custom'
            ));
            echo "Added Allyship Curriculum to primary menu\n";
        } else {
            $menus = wp_get_nav_menus();
            if (!empty($menus)) {
                $menu_id = $menus[0]->term_id;
                wp_update_nav_menu_item($menu_id, 0, array(
                    'menu-item-title'  => 'Allyship Curriculum',
                    'menu-item-url'    => home_url('/allyship-curriculum/'),
                    'menu-item-status' => 'publish',
                    'menu-item-type'   => 'custom'
                ));
                echo "Added Allyship Curriculum to first available menu\n";
            }
        }
    }
    
    /**
     * Get curriculum page content
     */
    private function get_curriculum_page_content() {
        // Build the lesson list HTML dynamically from the module structure
        $html = '';
        
        // Start with the intro content
        $html .= <<<HTML
<!-- wp:heading -->
<h2>Allyship Curriculum</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Welcome to our interactive allyship curriculum. This educational program is designed to help you understand and practice allyship in the workplace.</p>
<!-- /wp:paragraph -->

HTML;

        // Add each module and its lessons
        foreach ($this->modules as $module_slug => $module) {
            $html .= <<<HTML
<!-- wp:heading {"level":3} -->
<h3>Module: {$module['name']}</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>{$module['description']}</p>
<!-- /wp:paragraph -->

<!-- wp:list {"className":"allyship-lesson-list"} -->
<ul class="allyship-lesson-list">
HTML;

            // Get the lessons for this module
            $module_lessons = $this->lessons_by_module[$module_slug];
            
            // Sort lessons by order
            uasort($module_lessons, function($a, $b) {
                return $a['order'] - $b['order'];
            });
            
            // Add each lesson as a list item
            foreach ($module_lessons as $lesson_slug => $lesson) {
                $html .= <<<HTML
  <li><a href="/allyship-lesson/{$lesson_slug}/" class="allyship-lesson-link" data-lesson-slug="{$lesson_slug}">Lesson {$lesson['order']}: {$lesson['title']}</a></li>
HTML;
            }
            
            $html .= <<<HTML
</ul>
<!-- /wp:list -->

HTML;
        }
        
        // Calculate total lesson count for progress tracking
        $total_lessons = 0;
        foreach ($this->lessons_by_module as $module => $lessons) {
            $total_lessons += count($lessons);
        }
        
        // Add progress tracking elements
        $html .= <<<HTML
<!-- wp:html -->
<div class="allyship-progress-container">
    <h3>Your Progress</h3>
    <div class="progress-bar-container">
        <div class="allyship-progress-bar"></div>
    </div>
    <div class="progress-stats">
        <span class="lessons-completed">0 of {$total_lessons} lessons completed</span>
        <span class="allyship-points">0 points earned</span>
    </div>
</div>

<div class="allyship-achievements">
    <h3>Achievements</h3>
    <div class="achievement-container">
        <div class="achievement allyship-foundation locked">
            <h4>🏆 Achievement: Allyship Foundation</h4>
            <p>Complete the "Introduction to Allyship" lesson</p>
        </div>
        <div class="achievement allyship-reflection locked">
            <h4>🏆 Achievement: Self-Reflection</h4>
            <p>Complete the "Reflection: Your Allyship Moment" lesson</p>
        </div>
        <div class="achievement allyship-knowledge locked">
            <h4>🏆 Achievement: Allyship Knowledge</h4>
            <p>Complete the "Quiz: Ally in Action" with 100% correct answers</p>
        </div>
        <div class="achievement allyship-commitment locked">
            <h4>🏆 Achievement: Active Ally</h4>
            <p>Make a commitment in the "What's One Thing You'll Do?" lesson</p>
        </div>
        <div class="achievement allyship-complete locked">
            <h4>🏆 Achievement: Allyship Champion</h4>
            <p>Complete all lessons in the Defining Allyship module</p>
        </div>
    </div>
</div>

<div class="reset-container">
    <button class="reset-allyship-progress">Reset Progress</button>
</div>
<!-- /wp:html -->
HTML;
        
        return $html;
    }
    
    /**
     * Create individual lessons
     */
    private function create_individual_lessons() {
        // Create all lessons defined in our curriculum structure
        foreach ($this->modules as $module_slug => $module) {
            $lessons = $this->lessons_by_module[$module_slug];
            
            foreach ($lessons as $lesson_slug => $lesson) {
                $this->create_individual_lesson($module_slug, $lesson_slug, $lesson);
            }
        }
    }
    
    /**
     * Create a single lesson
     */
    private function create_individual_lesson($module_slug, $lesson_slug, $lesson_data) {
        // Check if lesson already exists
        $lesson_exists = get_page_by_path($lesson_slug, OBJECT, 'allyship_lesson');
        
        if ($lesson_exists) {
            echo "Lesson '{$lesson_data['title']}' already exists\n";
            return;
        }
        
        // Get the lesson content method name based on the lesson slug
        $content_method = 'get_' . str_replace('-', '_', $lesson_slug) . '_content';
        
        // Check if specific content method exists, otherwise use the generic one
        if (method_exists($this, $content_method)) {
            $lesson_content = $this->$content_method();
        } else {
            $lesson_content = $this->get_generic_lesson_content($module_slug, $lesson_slug, $lesson_data);
        }
        
        // Create the lesson
        $lesson_id = wp_insert_post(array(
            'post_title'     => $lesson_data['title'],
            'post_content'   => $lesson_content,
            'post_status'    => 'publish',
            'post_type'      => 'allyship_lesson',
            'post_name'      => $lesson_slug,
            'comment_status' => 'closed'
        ));
        
        if (is_wp_error($lesson_id)) {
            echo "Error creating lesson '{$lesson_data['title']}': " . $lesson_id->get_error_message() . "\n";
            return;
        }
        
        // Set the lesson's module
        wp_set_object_terms($lesson_id, $module_slug, 'allyship_module');
        
        // Set the lesson's type
        wp_set_object_terms($lesson_id, $lesson_data['type'], 'allyship_lesson_type');
        
        // Store the lesson order as post meta
        update_post_meta($lesson_id, 'lesson_order', $lesson_data['order']);
        
        echo "Created '{$lesson_data['title']}' lesson with ID: $lesson_id\n";
    }
    
    /**
     * Get generic lesson content
     */
    private function get_generic_lesson_content($module_slug, $lesson_slug, $lesson_data) {
        // Find the lesson index in the overall curriculum order
        $lesson_index = array_search(
            $lesson_slug, 
            array_column(array_map(function($item) { 
                return $item['lesson_slug']; 
            }, $this->lesson_order), 'lesson_slug')
        );
        
        // Calculate previous and next lessons for navigation
        $prev_lesson = ($lesson_index > 0) ? $this->lesson_order[$lesson_index - 1] : null;
        $next_lesson = ($lesson_index < count($this->lesson_order) - 1) ? $this->lesson_order[$lesson_index + 1] : null;
        
        // Get module name
        $module_name = $this->modules[$module_slug]['name'];
        
        // Determine the estimated time based on lesson type
        $estimated_time = '15';
        switch ($lesson_data['type']) {
            case 'video':
                $estimated_time = '10';
                break;
            case 'reflection':
                $estimated_time = '15';
                break;
            case 'quiz':
                $estimated_time = '15';
                break;
            case 'commitment':
                $estimated_time = '10';
                break;
        }
        
        // Build the lesson content
        $content = <<<HTML
<!-- wp:heading -->
<h2>Module: {$module_name}</h2>
<!-- /wp:heading -->

<!-- wp:heading {"level":3} -->
<h3>Lesson {$lesson_data['order']}: {$lesson_data['title']}</h3>
<!-- /wp:heading -->

<!-- wp:html -->
<div class="lesson-info">
    <div class="lesson-time">
        <span class="dashicons dashicons-clock"></span> Estimated time: {$estimated_time} minutes
    </div>
    <div class="lesson-type">
        <span class="dashicons dashicons-welcome-learn-more"></span> {$this->get_lesson_type_name($lesson_data['type'])}
    </div>
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="lesson-placeholder">
    <p>This is a placeholder for the {$lesson_data['title']} content.</p>
    <p>Lesson type: {$this->get_lesson_type_name($lesson_data['type'])}</p>
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="lesson-navigation">
HTML;

        // Add previous lesson link if exists
        if ($prev_lesson) {
            $prev_lesson_data = $this->lessons_by_module[$prev_lesson['module_slug']][$prev_lesson['lesson_slug']];
            $content .= <<<HTML
    <a href="/allyship-lesson/{$prev_lesson['lesson_slug']}/" class="prev-lesson">
        <span class="dashicons dashicons-arrow-left-alt"></span>
        Previous: {$prev_lesson_data['title']}
    </a>
HTML;
        }
        
        // Add curriculum link
        $content .= <<<HTML
    <a href="/allyship-curriculum/" class="back-to-curriculum">
        <span class="dashicons dashicons-category"></span>
        Back to Curriculum
    </a>
HTML;
        
        // Add next lesson link if exists
        if ($next_lesson) {
            $next_lesson_data = $this->lessons_by_module[$next_lesson['module_slug']][$next_lesson['lesson_slug']];
            $content .= <<<HTML
    <a href="/allyship-lesson/{$next_lesson['lesson_slug']}/" class="next-lesson">
        Next: {$next_lesson_data['title']}
        <span class="dashicons dashicons-arrow-right-alt"></span>
    </a>
HTML;
        }
        
        // Close navigation div and add completion tracking
        $content .= <<<HTML
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="allyship-lesson-completion" data-lesson-slug="{$lesson_slug}">
    <h3>Lesson Progress</h3>
    <div class="completion-status">
        <div class="completion-icon incomplete">
            <span class="dashicons dashicons-marker"></span>
        </div>
        <div class="completion-icon complete" style="display: none;">
            <span class="dashicons dashicons-yes-alt"></span>
        </div>
        <div class="completion-text incomplete">
            <p>You haven't completed this lesson yet.</p>
        </div>
        <div class="completion-text complete" style="display: none;">
            <p>You've completed this lesson! +100 points earned.</p>
        </div>
    </div>
    <div class="completion-actions">
        <button class="mark-complete-button">Mark as Complete (+100 points)</button>
        <a href="/allyship-curriculum/" class="back-to-curriculum">Back to Curriculum</a>
    </div>
</div>
<!-- /wp:html -->
HTML;
        
        return $content;
    }
    
    /**
     * Get the display name for a lesson type
     */
    private function get_lesson_type_name($type_slug) {
        $types = [
            'content' => 'Interactive Content',
            'video' => 'Video Lesson',
            'reflection' => 'Reflection Exercise',
            'quiz' => 'Interactive Quiz',
            'commitment' => 'Commitment Builder'
        ];
        
        return isset($types[$type_slug]) ? $types[$type_slug] : 'Lesson';
    }
    
    /**
     * Get Introduction to Allyship lesson content
     */
    private function get_what_is_allyship_intro_content() {
        return <<<HTML
<!-- wp:heading -->
<h2>Module: Defining Allyship</h2>
<!-- /wp:heading -->

<!-- wp:heading {"level":3} -->
<h3>Lesson 1: Introduction to Allyship</h3>
<!-- /wp:heading -->

<!-- wp:html -->
<div class="lesson-info">
    <div class="lesson-time">
        <span class="dashicons dashicons-clock"></span> Estimated time: 10 minutes
    </div>
    <div class="lesson-type">
        <span class="dashicons dashicons-welcome-learn-more"></span> Interactive Content
    </div>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>Welcome to the Allyship Curriculum! This educational program is designed to help you understand and practice allyship in the workplace.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Let's start by exploring what allyship means and how it can transform workplace dynamics.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":4} -->
<h4>What is Allyship?</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Allyship is the ongoing process of building relationships based on trust, accountability, and consistency with marginalized individuals or groups.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>An ally isn't just someone who's sympathetic to a cause — it's someone who:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul>
<li>Takes action to support others</li>
<li>Uses their privilege and position to make space for others</li>
<li>Educates themselves continually</li>
<li>Makes mistakes, acknowledges them, and grows</li>
<li>Shows up consistently, not just when it's convenient</li>
</ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>In the workplace specifically, allies actively work to create more inclusive environments for all employees regardless of their backgrounds, identities, or experiences.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":4} -->
<h4>Why Allyship Matters at Work</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Organizations with strong allyship cultures benefit from:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul>
<li>Higher employee retention and satisfaction</li>
<li>Increased innovation through diverse perspectives</li>
<li>Stronger team cohesion and psychological safety</li>
<li>More equitable advancement opportunities</li>
<li>Improved problem-solving and decision-making</li>
</ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>For individuals, practicing allyship helps build leadership skills, empathy, and collaborative abilities that enhance career growth.</p>
<!-- /wp:paragraph -->

<!-- wp:html -->
<div class="lesson-navigation">
    <a href="/allyship-curriculum/" class="back-to-curriculum">
        <span class="dashicons dashicons-category"></span>
        Back to Curriculum
    </a>
    <a href="/allyship-lesson/what-is-allyship-video/" class="next-lesson">
        Next: Video: What Does It Mean to Be an Ally?
        <span class="dashicons dashicons-arrow-right-alt"></span>
    </a>
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="allyship-lesson-completion" data-lesson-slug="what-is-allyship-intro">
    <h3>Lesson Progress</h3>
    <div class="completion-status">
        <div class="completion-icon incomplete">
            <span class="dashicons dashicons-marker"></span>
        </div>
        <div class="completion-icon complete" style="display: none;">
            <span class="dashicons dashicons-yes-alt"></span>
        </div>
        <div class="completion-text incomplete">
            <p>You haven't completed this lesson yet.</p>
        </div>
        <div class="completion-text complete" style="display: none;">
            <p>You've completed this lesson! +100 points earned.</p>
        </div>
    </div>
    <div class="completion-actions">
        <button class="mark-complete-button">Mark as Complete (+100 points)</button>
        <a href="/allyship-curriculum/" class="back-to-curriculum">Back to Curriculum</a>
    </div>
</div>
<!-- /wp:html -->
HTML;
    }
    
    /**
     * Get Video lesson content
     */
    private function get_what_is_allyship_video_content() {
        return <<<HTML
<!-- wp:heading -->
<h2>Module: Defining Allyship</h2>
<!-- /wp:heading -->

<!-- wp:heading {"level":3} -->
<h3>Lesson 2: Video - What Does It Mean to Be an Ally?</h3>
<!-- /wp:heading -->

<!-- wp:html -->
<div class="lesson-info">
    <div class="lesson-time">
        <span class="dashicons dashicons-clock"></span> Estimated time: 8 minutes
    </div>
    <div class="lesson-type">
        <span class="dashicons dashicons-welcome-learn-more"></span> Video Lesson
    </div>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>Watch this video to hear people describe what allyship means to them and why it matters.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":4} -->
<h4>📹 Video (5 min)</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Title:</strong> What Does It Mean to Be an Ally?</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><a href="https://www.withersworldwide.com/en-gb/insight/watch/what-does-being-an-lgbtq-ally-mean-to-you-and-why">https://www.withersworldwide.com/en-gb/insight/watch/what-does-being-an-lgbtq-ally-mean-to-you-and-why</a></p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>(Note: We'll eventually create our own video or find a more updated version, but this serves as a placeholder for now.)</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":4} -->
<h4>Key Takeaways</h4>
<!-- /wp:heading -->

<!-- wp:list -->
<ul>
<li>Allyship is active, not passive</li>
<li>It's about both education and action</li>
<li>You don't need to be perfect to be an ally</li>
<li>Small everyday actions can make a big difference</li>
</ul>
<!-- /wp:list -->

<!-- wp:html -->
<div class="lesson-navigation">
    <a href="/allyship-lesson/what-is-allyship-intro/" class="prev-lesson">
        <span class="dashicons dashicons-arrow-left-alt"></span>
        Previous: Introduction to Allyship
    </a>
    <a href="/allyship-curriculum/" class="back-to-curriculum">
        <span class="dashicons dashicons-category"></span>
        Back to Curriculum
    </a>
    <a href="/allyship-lesson/what-is-allyship-reflection/" class="next-lesson">
        Next: Reflection: Your Allyship Moment
        <span class="dashicons dashicons-arrow-right-alt"></span>
    </a>
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="allyship-lesson-completion" data-lesson-slug="what-is-allyship-video">
    <h3>Lesson Progress</h3>
    <div class="completion-status">
        <div class="completion-icon incomplete">
            <span class="dashicons dashicons-marker"></span>
        </div>
        <div class="completion-icon complete" style="display: none;">
            <span class="dashicons dashicons-yes-alt"></span>
        </div>
        <div class="completion-text incomplete">
            <p>You haven't completed this lesson yet.</p>
        </div>
        <div class="completion-text complete" style="display: none;">
            <p>You've completed this lesson! +100 points earned.</p>
        </div>
    </div>
    <div class="completion-actions">
        <button class="mark-complete-button">Mark as Complete (+100 points)</button>
        <a href="/allyship-curriculum/" class="back-to-curriculum">Back to Curriculum</a>
    </div>
</div>
<!-- /wp:html -->
HTML;
    }
    
    /**
     * Get Reflection lesson content
     */
    private function get_what_is_allyship_reflection_content() {
        return <<<HTML
<!-- wp:heading -->
<h2>Module: Defining Allyship</h2>
<!-- /wp:heading -->

<!-- wp:heading {"level":3} -->
<h3>Lesson 3: Reflection - Your Allyship Moment</h3>
<!-- /wp:heading -->

<!-- wp:html -->
<div class="lesson-info">
    <div class="lesson-time">
        <span class="dashicons dashicons-clock"></span> Estimated time: 15 minutes
    </div>
    <div class="lesson-type">
        <span class="dashicons dashicons-welcome-learn-more"></span> Reflection Exercise
    </div>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>Reflection is a critical part of allyship. Taking time to think about our experiences helps us identify ways to be better allies.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":4} -->
<h4>💬 Reflection Prompt (10-15 min)</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Title:</strong> Your Allyship Moment</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Prompt:</strong></p>
<!-- /wp:paragraph -->

<!-- wp:quote -->
<blockquote class="wp-block-quote">
<p>"Think of a time when you witnessed allyship in action. What did the person do? What impact did it have on the person or group being supported?"</p>
<p>If you haven't witnessed allyship directly, describe what you think meaningful allyship would look like in your workplace.</p>
</blockquote>
<!-- /wp:quote -->

<!-- wp:paragraph -->
<p><strong>Delivery Options:</strong></p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul>
<li>Type into a journal-style field</li>
<li>Record a voice note</li>
</ul>
<!-- /wp:list -->

<!-- wp:html -->
<div class="allyship-reflection-box">
    <h4>Your Reflection</h4>
    <textarea id="allyship-reflection" rows="6" placeholder="Share your thoughts here..."></textarea>
    <button id="save-reflection" class="button button-primary">Save Reflection</button>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>Reflecting on allyship experiences - whether our own or others' - helps us understand what effective allyship looks like in practice. By identifying specific behaviors and their impacts, we can build a personal toolkit for being better allies.</p>
<!-- /wp:paragraph -->

<!-- wp:html -->
<div class="lesson-navigation">
    <a href="/allyship-lesson/what-is-allyship-video/" class="prev-lesson">
        <span class="dashicons dashicons-arrow-left-alt"></span>
        Previous: Video: What Does It Mean to Be an Ally?
    </a>
    <a href="/allyship-curriculum/" class="back-to-curriculum">
        <span class="dashicons dashicons-category"></span>
        Back to Curriculum
    </a>
    <a href="/allyship-lesson/what-is-allyship-novella/" class="next-lesson">
        Next: Graphic Novella: Just Another Meeting?
        <span class="dashicons dashicons-arrow-right-alt"></span>
    </a>
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="allyship-lesson-completion" data-lesson-slug="what-is-allyship-reflection">
    <h3>Lesson Progress</h3>
    <div class="completion-status">
        <div class="completion-icon incomplete">
            <span class="dashicons dashicons-marker"></span>
        </div>
        <div class="completion-icon complete" style="display: none;">
            <span class="dashicons dashicons-yes-alt"></span>
        </div>
        <div class="completion-text incomplete">
            <p>You haven't completed this lesson yet.</p>
        </div>
        <div class="completion-text complete" style="display: none;">
            <p>You've completed this lesson! +100 points earned.</p>
        </div>
    </div>
    <div class="completion-actions">
        <button class="mark-complete-button">Mark as Complete (+100 points)</button>
        <a href="/allyship-curriculum/" class="back-to-curriculum">Back to Curriculum</a>
    </div>
</div>
<!-- /wp:html -->
HTML;
    }
    
    /**
     * Get Graphic Novella lesson content
     */
    private function get_what_is_allyship_novella_content() {
        return <<<HTML
<!-- wp:heading -->
<h2>Module: Defining Allyship</h2>
<!-- /wp:heading -->

<!-- wp:heading {"level":3} -->
<h3>Lesson 4: Graphic Novella - Just Another Meeting?</h3>
<!-- /wp:heading -->

<!-- wp:html -->
<div class="lesson-info">
    <div class="lesson-time">
        <span class="dashicons dashicons-clock"></span> Estimated time: 8 minutes
    </div>
    <div class="lesson-type">
        <span class="dashicons dashicons-welcome-learn-more"></span> Interactive Content
    </div>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>Sometimes seeing allyship in action helps us understand what it looks like in real-world situations. This brief graphic story illustrates a common workplace scenario and the impact of choosing whether to act as an ally.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":3} -->
<h3>🎨 Graphic Novella: "Just Another Meeting?"</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Theme:</strong> Workplace Allyship in Everyday Moments<br><strong>Length:</strong> ~6–8 panels (1–2 minutes reading time)</p>
<!-- /wp:paragraph -->

<!-- wp:columns -->
<div class="wp-block-columns"><!-- wp:column -->
<div class="wp-block-column"><!-- wp:heading {"level":4} -->
<h4>Panel 1: Morning Zoom Check-In</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Visual:</strong> Lena (mid-30s, Black woman, team lead) sits at her desk, laptop open. Virtual meeting screen in view with 5 faces in video boxes.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Text Box (Narration):</strong><br>"It was just another Wednesday check-in. Deadlines. Deliverables. Another Zoom blur."</p>
<!-- /wp:paragraph --></div>
<!-- /wp:column -->

<!-- wp:column -->
<div class="wp-block-column"><!-- wp:heading {"level":4} -->
<h4>Panel 2: Dev Speaks</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Visual:</strong> Dev (South Asian, nonbinary, short-cropped hair, warm smile) is speaking in their video square.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Speech Bubble (Dev):</strong><br>"I think the rollout timing makes sense, based on the feedback from the customer team."</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Text Box (Narration):</strong><br>"Dev joined last quarter — thoughtful, sharp, and recently shared that they use they/them pronouns."</p>
<!-- /wp:paragraph --></div>
<!-- /wp:column --></div>
<!-- /wp:columns -->

<!-- wp:columns -->
<div class="wp-block-columns"><!-- wp:column -->
<div class="wp-block-column"><!-- wp:heading {"level":4} -->
<h4>Panel 3: Slip-Up</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Visual:</strong> Another team member (Jordan) is speaking in their video square, gesturing casually.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Speech Bubble (Jordan):</strong><br>"Well, she said it was fine, so we should be good."</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visual Detail:</strong> Dev's square is still, expression neutral. Small "…" above their head.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Text Box (Narration):</strong><br>"The comment slipped by. A small word. A misgendering."</p>
<!-- /wp:paragraph --></div>
<!-- /wp:column -->

<!-- wp:column -->
<div class="wp-block-column"><!-- wp:heading {"level":4} -->
<h4>Panel 4: Lena's Reaction</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Visual:</strong> Close-up of Lena's face. She's frozen, eyes focused, mouse hovering over her unmute button.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Thought Bubble (Lena):</strong><br>Do I say something? It was probably unintentional… Maybe Dev didn't even notice…</p>
<!-- /wp:paragraph --></div>
<!-- /wp:column --></div>
<!-- /wp:columns -->

<!-- wp:columns -->
<div class="wp-block-columns"><!-- wp:column -->
<div class="wp-block-column"><!-- wp:heading {"level":4} -->
<h4>Panel 5: Meeting Ends</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Visual:</strong> The Zoom meeting ends. Dev's square lingers briefly before disappearing. Lena stares at her screen, her finger hovering over the touchpad.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Text Box (Narration):</strong><br>"The moment passed. But so did the opportunity."</p>
<!-- /wp:paragraph --></div>
<!-- /wp:column -->

<!-- wp:column -->
<div class="wp-block-column"><!-- wp:heading {"level":4} -->
<h4>Panel 6: Flashback to Dev Sharing Pronouns</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Visual:</strong> Dev speaking at a team meeting a few weeks prior, smiling.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Speech Bubble (Dev):</strong><br>"Also, just a quick note — I use they/them pronouns!"</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Visual Detail:</strong> Lena smiling warmly in the background.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Text Box (Narration):</strong><br>"Lena had been proud when Dev shared their pronouns. She remembered the courage it took."</p>
<!-- /wp:paragraph --></div>
<!-- /wp:column --></div>
<!-- /wp:columns -->

<!-- wp:columns -->
<div class="wp-block-columns"><!-- wp:column -->
<div class="wp-block-column"><!-- wp:heading {"level":4} -->
<h4>Panel 7: Lena's Reflection</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Visual:</strong> Lena alone at her desk later that evening, looking at a sticky note that reads "Speak up even when it's hard."</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Text Box (Narration):</strong><br>"She realized silence — even in small moments — wasn't neutral. It reinforced the discomfort Dev didn't show."</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Thought Bubble (Lena):</strong><br>Next time, I speak up.</p>
<!-- /wp:paragraph --></div>
<!-- /wp:column -->

<!-- wp:column -->
<div class="wp-block-column"><!-- wp:heading {"level":4} -->
<h4>Panel 8: Call to Action Panel</h4>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Visual:</strong> Full-width panel with a clean background, bold text centered.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><strong>Text:</strong><br>"Allyship isn't about perfection — it's about showing up."<br>"Small moments matter. What would you do?"</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p><a class="button button-primary take-quiz-button">Continue to Quiz →</a></p>
<!-- /wp:paragraph --></div>
<!-- /wp:column --></div>
<!-- /wp:columns -->

<!-- wp:paragraph -->
<p>This graphic novella highlights a common scenario: the small, everyday moments where allyship matters. Sometimes the most important allyship actions are the seemingly small ones that show marginalized individuals they're seen, respected, and supported.</p>
<!-- /wp:paragraph -->

<!-- wp:html -->
<div class="lesson-navigation">
    <a href="/allyship-lesson/what-is-allyship-reflection/" class="prev-lesson">
        <span class="dashicons dashicons-arrow-left-alt"></span>
        Previous: Reflection: Your Allyship Moment
    </a>
    <a href="/allyship-curriculum/" class="back-to-curriculum">
        <span class="dashicons dashicons-category"></span>
        Back to Curriculum
    </a>
    <a href="/allyship-lesson/what-is-allyship-quiz/" class="next-lesson">
        Next: Quiz: Ally in Action
        <span class="dashicons dashicons-arrow-right-alt"></span>
    </a>
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="allyship-lesson-completion" data-lesson-slug="what-is-allyship-novella">
    <h3>Lesson Progress</h3>
    <div class="completion-status">
        <div class="completion-icon incomplete">
            <span class="dashicons dashicons-marker"></span>
        </div>
        <div class="completion-icon complete" style="display: none;">
            <span class="dashicons dashicons-yes-alt"></span>
        </div>
        <div class="completion-text incomplete">
            <p>You haven't completed this lesson yet.</p>
        </div>
        <div class="completion-text complete" style="display: none;">
            <p>You've completed this lesson! +100 points earned.</p>
        </div>
    </div>
    <div class="completion-actions">
        <button class="mark-complete-button">Mark as Complete (+100 points)</button>
        <a href="/allyship-curriculum/" class="back-to-curriculum">Back to Curriculum</a>
    </div>
</div>
<!-- /wp:html -->
HTML;
    }
    
    /**
     * Get Quiz lesson content
     */
    private function get_what_is_allyship_quiz_content() {
        return <<<HTML
<!-- wp:heading -->
<h2>Module: Defining Allyship</h2>
<!-- /wp:heading -->

<!-- wp:heading {"level":3} -->
<h3>Lesson 5: Quiz - Ally in Action</h3>
<!-- /wp:heading -->

<!-- wp:html -->
<div class="lesson-info">
    <div class="lesson-time">
        <span class="dashicons dashicons-clock"></span> Estimated time: 15 minutes
    </div>
    <div class="lesson-type">
        <span class="dashicons dashicons-welcome-learn-more"></span> Interactive Quiz
    </div>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>Now that you've learned about allyship principles and seen some examples, let's practice applying this knowledge to real-world scenarios.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":3} -->
<h3>❓ Mini-Scenario Quiz</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p><strong>Title:</strong> Ally in Action: What Would You Do?<br><strong>Format:</strong> Choose-your-path interactive case studies</p>
<!-- /wp:paragraph -->

<!-- wp:html -->
<div class="allyship-scenarios">
  <div class="scenario" id="scenario-1">
    <h4>✳️ Scenario 1: Misgendering in a Meeting</h4>
    <p>You're in a team meeting. A colleague repeatedly refers to Taylor, who uses they/them pronouns, as 'she.' Taylor looks visibly uncomfortable.</p>
    <p><strong>What do you do?</strong></p>
    <div class="scenario-options">
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-1" id="s1-a">
        <label for="s1-a">A. Say nothing during the meeting but check in with Taylor afterward.</label>
      </div>
      <div class="option" data-correct="true">
        <input type="radio" name="scenario-1" id="s1-b">
        <label for="s1-b">B. Gently correct the person in real time: "Hey, just a reminder that Taylor uses they/them pronouns."</label>
      </div>
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-1" id="s1-c">
        <label for="s1-c">C. Report the incident to HR immediately without checking in.</label>
      </div>
    </div>
    <div class="feedback correct-feedback">
      <h5>✅ Correct!</h5>
      <p>Correcting respectfully in the moment helps stop harm and models inclusive behavior. Checking in is also important, but silence in the moment can reinforce exclusion.</p>
    </div>
    <div class="feedback incorrect-feedback">
      <h5>Try Again</h5>
      <p>Consider what would most directly address the harm happening in the moment.</p>
    </div>
  </div>

  <div class="scenario" id="scenario-2">
    <h4>✳️ Scenario 2: Inclusive Hiring</h4>
    <p>You're on a hiring panel. A colleague comments, 'We don't want someone who's "too political" with all that identity stuff.'</p>
    <p><strong>What's the best ally move?</strong></p>
    <div class="scenario-options">
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-2" id="s2-a">
        <label for="s2-a">A. Nod to avoid conflict but later debrief with HR.</label>
      </div>
      <div class="option" data-correct="true">
        <input type="radio" name="scenario-2" id="s2-b">
        <label for="s2-b">B. Say, "Can we clarify what you mean by that? Let's make sure we're aligning with inclusive hiring practices."</label>
      </div>
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-2" id="s2-c">
        <label for="s2-c">C. Laugh awkwardly and hope someone else says something.</label>
      </div>
    </div>
    <div class="feedback correct-feedback">
      <h5>✅ Correct!</h5>
      <p>Asking clarifying questions helps surface bias without confrontation. It centers values without shaming.</p>
    </div>
    <div class="feedback incorrect-feedback">
      <h5>Try Again</h5>
      <p>Think about a response that addresses the issue in the moment while maintaining a professional tone.</p>
    </div>
  </div>

  <div class="scenario" id="scenario-3">
    <h4>✳️ Scenario 3: Pride Month Support</h4>
    <p>Your company shares a Pride Month post, but internally, there's no support for LGBTQ+ ERGs or trans-inclusive policies. What do you do?</p>
    <div class="scenario-options">
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-3" id="s3-a">
        <label for="s3-a">A. Comment on the post highlighting the disconnect.</label>
      </div>
      <div class="option" data-correct="true">
        <input type="radio" name="scenario-3" id="s3-b">
        <label for="s3-b">B. Raise concerns internally and suggest ways to align external messaging with internal practice.</label>
      </div>
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-3" id="s3-c">
        <label for="s3-c">C. Ignore it — marketing isn't your department.</label>
      </div>
    </div>
    <div class="feedback correct-feedback">
      <h5>✅ Correct!</h5>
      <p>Constructive internal advocacy is more likely to lead to change and shows meaningful allyship vs. performative gestures.</p>
    </div>
    <div class="feedback incorrect-feedback">
      <h5>Try Again</h5>
      <p>Consider which approach would be most effective in creating actual change in the organization.</p>
    </div>
  </div>

  <div class="scenario" id="scenario-4">
    <h4>✳️ Scenario 4: Correcting a Microaggression in Real-Time</h4>
    <p>You're chatting with coworkers after a team presentation. One colleague says, "Dev did a great job — especially for someone who's still figuring out their identity."</p>
    <p><strong>What's the best way to respond as an ally?</strong></p>
    <div class="scenario-options">
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-4" id="s4-a">
        <label for="s4-a">A. Say nothing — it wasn't meant to be harmful.</label>
      </div>
      <div class="option" data-correct="true">
        <input type="radio" name="scenario-4" id="s4-b">
        <label for="s4-b">B. Say, "Hey, I know you didn't mean harm, but that comment could come across as dismissive of Dev's expertise."</label>
      </div>
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-4" id="s4-c">
        <label for="s4-c">C. Pull Dev aside later to reassure them they're valued.</label>
      </div>
    </div>
    <div class="feedback correct-feedback">
      <h5>✅ Correct!</h5>
      <p>Allies speak up when microaggressions happen. Framing your response as feedback rather than confrontation helps build awareness without alienating others.</p>
    </div>
    <div class="feedback incorrect-feedback">
      <h5>Try Again</h5>
      <p>Consider which approach addresses the microaggression directly while maintaining working relationships.</p>
    </div>
  </div>

  <div class="scenario" id="scenario-5">
    <h4>✳️ Scenario 5: Supporting a Colleague Who Comes Out</h4>
    <p>A teammate, Sam, privately shares with you that they've come out as nonbinary and are nervous about telling the rest of the team.</p>
    <p><strong>How do you respond?</strong></p>
    <div class="scenario-options">
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-5" id="s5-a">
        <label for="s5-a">A. Offer to tell the team on their behalf to ease the pressure.</label>
      </div>
      <div class="option" data-correct="true">
        <input type="radio" name="scenario-5" id="s5-b">
        <label for="s5-b">B. Thank them for trusting you, ask how you can support them, and follow their lead.</label>
      </div>
      <div class="option" data-correct="false">
        <input type="radio" name="scenario-5" id="s5-c">
        <label for="s5-c">C. Tell a few trusted coworkers to prepare them ahead of time.</label>
      </div>
    </div>
    <div class="feedback correct-feedback">
      <h5>✅ Correct!</h5>
      <p>Allyship centers the other person's autonomy. Listening and asking how to support — without assuming or overstepping — builds trust and psychological safety.</p>
    </div>
    <div class="feedback incorrect-feedback">
      <h5>Try Again</h5>
      <p>Think about respecting the person's agency and privacy in your response.</p>
    </div>
  </div>
  
  <div class="quiz-results">
    <h4>Quiz Results</h4>
    <p>You've answered <span class="correct-count">0</span> out of 5 questions correctly.</p>
    <div class="quiz-complete-message" style="display: none;">
      <p><strong>Great job!</strong> You've completed all the scenarios correctly. You're ready to put these allyship skills into practice!</p>
    </div>
  </div>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>These scenarios reflect common situations where allyship can make a real difference. Remember that effective allyship is about:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul>
<li>Addressing issues in the moment when possible</li>
<li>Centering the experiences of marginalized individuals</li>
<li>Balancing directness with respect</li>
<li>Following the lead of those you're supporting</li>
<li>Taking constructive action rather than just expressing concern</li>
</ul>
<!-- /wp:list -->

<!-- wp:html -->
<div class="lesson-navigation">
    <a href="/allyship-lesson/what-is-allyship-novella/" class="prev-lesson">
        <span class="dashicons dashicons-arrow-left-alt"></span>
        Previous: Graphic Novella: Just Another Meeting?
    </a>
    <a href="/allyship-curriculum/" class="back-to-curriculum">
        <span class="dashicons dashicons-category"></span>
        Back to Curriculum
    </a>
    <a href="/allyship-lesson/what-is-allyship-commitment/" class="next-lesson">
        Next: Commitment Builder: What's One Thing You'll Do?
        <span class="dashicons dashicons-arrow-right-alt"></span>
    </a>
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="allyship-lesson-completion" data-lesson-slug="what-is-allyship-quiz">
    <h3>Lesson Progress</h3>
    <div class="completion-status">
        <div class="completion-icon incomplete">
            <span class="dashicons dashicons-marker"></span>
        </div>
        <div class="completion-icon complete" style="display: none;">
            <span class="dashicons dashicons-yes-alt"></span>
        </div>
        <div class="completion-text incomplete">
            <p>You haven't completed this lesson yet.</p>
        </div>
        <div class="completion-text complete" style="display: none;">
            <p>You've completed this lesson! +100 points earned.</p>
        </div>
    </div>
    <div class="completion-actions">
        <button class="mark-complete-button">Mark as Complete (+100 points)</button>
        <a href="/allyship-curriculum/" class="back-to-curriculum">Back to Curriculum</a>
    </div>
</div>
<!-- /wp:html -->
HTML;
    }
    
    /**
     * Get Commitment Builder lesson content
     */
    private function get_what_is_allyship_commitment_content() {
        return <<<HTML
<!-- wp:heading -->
<h2>Module: Defining Allyship</h2>
<!-- /wp:heading -->

<!-- wp:heading {"level":3} -->
<h3>Lesson 6: Commitment Builder - What's One Thing You'll Do?</h3>
<!-- /wp:heading -->

<!-- wp:html -->
<div class="lesson-info">
    <div class="lesson-time">
        <span class="dashicons dashicons-clock"></span> Estimated time: 10 minutes
    </div>
    <div class="lesson-type">
        <span class="dashicons dashicons-welcome-learn-more"></span> Commitment Builder
    </div>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>Congratulations on completing the allyship curriculum! Now comes the most important part: turning learning into action.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Research shows that making a specific commitment dramatically increases the likelihood that you'll follow through. This final exercise helps you identify one concrete step you can take to practice allyship.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":3} -->
<h3>🎯 Allyship Commitment Builder</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>You've just explored real-world allyship situations. The next step? Taking action.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Think of one meaningful step you can take this week — something small, specific, and within your control.</p>
<!-- /wp:paragraph -->

<!-- wp:html -->
<div class="commitment-builder">
    <div class="commitment-sections">
        <h4>Choose from Our Action Menu:</h4>
        <div class="commitment-cards">
            <div class="commitment-card">
                <h5>💬 Quick Wins (1–5 minutes)</h5>
                <ul>
                    <li>Add your pronouns to your email signature and Slack profile.</li>
                    <li>Use inclusive language like 'partner' or 'everyone' instead of 'guys'.</li>
                    <li>Share an LGBTQ+ learning resource in your team chat.</li>
                </ul>
                <button class="select-action">Select</button>
            </div>
            
            <div class="commitment-card">
                <h5>🧠 Deepen Awareness</h5>
                <ul>
                    <li>Sign up for your company's LGBTQ+ ERG or attend an ally event.</li>
                    <li>Spend 10 minutes researching trans-inclusive healthcare benefits.</li>
                    <li>Reflect on your privileges and how they show up at work.</li>
                </ul>
                <button class="select-action">Select</button>
            </div>
            
            <div class="commitment-card">
                <h5>✊ Speak Up or Act</h5>
                <ul>
                    <li>Commit to interrupting bias or misgendering in the moment.</li>
                    <li>Offer to mentor or support a queer colleague's professional growth.</li>
                    <li>Start a conversation about allyship in your next team meeting.</li>
                </ul>
                <button class="select-action">Select</button>
            </div>
        </div>
        
        <h4>Or Write Your Own Commitment:</h4>
        <textarea id="custom-commitment" rows="4" placeholder="In my own words, here's what I'll do this week to show up as an ally:"></textarea>
        
        <div class="commitment-actions">
            <button id="save-commitment" class="button button-primary">Save My Commitment</button>
            <button id="email-commitment" class="button">Email It to Me</button>
            <button id="set-reminder" class="button">Set a Reminder</button>
        </div>
        
        <div class="share-option">
            <input type="checkbox" id="share-commitment">
            <label for="share-commitment">Want to inspire others? Share your ally commitment anonymously on our Ally Wall.</label>
        </div>
        
        <p class="privacy-note">Your personal commitment is private unless you choose to share it. This space is about growth — not perfection.</p>
    </div>
</div>
<!-- /wp:html -->

<!-- wp:paragraph -->
<p>Remember, becoming an effective ally is a journey, not a destination. It's okay to make mistakes along the way. What matters most is your willingness to learn, listen, and take action.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Thank you for your commitment to creating a more inclusive workplace for everyone!</p>
<!-- /wp:paragraph -->

<!-- wp:html -->
<div class="lesson-navigation">
    <a href="/allyship-lesson/what-is-allyship-quiz/" class="prev-lesson">
        <span class="dashicons dashicons-arrow-left-alt"></span>
        Previous: Quiz: Ally in Action
    </a>
    <a href="/allyship-curriculum/" class="back-to-curriculum">
        <span class="dashicons dashicons-category"></span>
        Back to Curriculum
    </a>
</div>
<!-- /wp:html -->

<!-- wp:html -->
<div class="allyship-lesson-completion" data-lesson-slug="what-is-allyship-commitment">
    <h3>Lesson Progress</h3>
    <div class="completion-status">
        <div class="completion-icon incomplete">
            <span class="dashicons dashicons-marker"></span>
        </div>
        <div class="completion-icon complete" style="display: none;">
            <span class="dashicons dashicons-yes-alt"></span>
        </div>
        <div class="completion-text incomplete">
            <p>You haven't completed this lesson yet.</p>
        </div>
        <div class="completion-text complete" style="display: none;">
            <p>You've completed this lesson! +100 points earned.</p>
        </div>
    </div>
    <div class="completion-actions">
        <button class="mark-complete-button">Mark as Complete (+100 points)</button>
        <a href="/allyship-curriculum/" class="back-to-curriculum">Back to Curriculum</a>
    </div>
</div>
<!-- /wp:html -->
HTML;
    }
    
    /**
     * Create assets (CSS and JS)
     */
    private function create_assets() {
        // Create the CSS
        $this->create_css();
        
        // Create the JS
        $this->create_js();
    }
    
    /**
     * Create CSS for allyship system
     */
    private function create_css() {
        $css = <<<CSS
/**
 * Allyship System Styles
 * Modular Curriculum Implementation
 */

/* General Styles */
.lesson-info {
    display: flex;
    gap: 15px;
    margin-bottom: 20px;
    color: #555;
}

.lesson-time, .lesson-type {
    display: flex;
    align-items: center;
    gap: 5px;
}

/* Curriculum Page */
.allyship-lesson-list {
    margin-bottom: 30px;
}

.allyship-lesson-list li {
    margin-bottom: 10px;
}

.allyship-lesson-link {
    display: block;
    padding: 10px 15px;
    background-color: #f8f9fa;
    border-left: 4px solid #6a1b9a;
    border-radius: 4px;
    text-decoration: none;
    transition: all 0.2s ease;
}

.allyship-lesson-link:hover {
    background-color: #f0f0f0;
    border-left-color: #9c27b0;
}

.allyship-lesson-link.completed {
    border-left-color: #4caf50;
}

.allyship-lesson-link.completed::before {
    content: "✓";
    color: #4caf50;
    margin-right: 8px;
}

/* Progress Tracking */
.allyship-progress-container {
    background-color: #f8f9fa;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 20px;
    margin: 30px 0;
}

.allyship-progress-container h3 {
    margin-top: 0;
    padding-bottom: 10px;
    border-bottom: 1px solid #e0e0e0;
}

.progress-bar-container {
    background-color: #eee;
    height: 20px;
    border-radius: 10px;
    overflow: hidden;
    margin: 15px 0;
}

.allyship-progress-bar {
    height: 100%;
    background-color: #9c27b0;
    width: 0%;
    transition: width 0.5s ease;
}

.progress-stats {
    display: flex;
    justify-content: space-between;
    color: #555;
    font-size: 14px;
}

/* Achievements */
.allyship-achievements {
    background-color: #f8f9fa;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 20px;
    margin: 30px 0;
}

.allyship-achievements h3 {
    margin-top: 0;
    padding-bottom: 10px;
    border-bottom: 1px solid #e0e0e0;
}

.achievement-container {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 15px;
    margin-top: 20px;
}

.achievement {
    padding: 15px;
    border-radius: 5px;
    margin-bottom: 15px;
    transition: all 0.3s ease;
}

.achievement.locked {
    background-color: #f5f5f5;
    border-left: 4px solid #9e9e9e;
}

.achievement.unlocked {
    background-color: #f3e5f5;
    border-left: 4px solid #9c27b0;
}

.achievement h4 {
    margin-top: 0;
    margin-bottom: 5px;
}

.achievement p {
    margin-bottom: 0;
    color: #555;
}

/* Reset Button */
.reset-container {
    text-align: center;
    margin: 30px 0 10px;
}

.reset-allyship-progress {
    background-color: #f44336;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
}

.reset-allyship-progress:hover {
    background-color: #e53935;
}

/* Lesson Navigation */
.lesson-navigation {
    display: flex;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 10px;
    margin: 40px 0 20px;
    border-top: 1px solid #eee;
    padding-top: 20px;
}

.lesson-navigation a {
    padding: 10px 15px;
    border-radius: 4px;
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 5px;
    font-weight: 500;
    transition: all 0.2s ease;
}

.prev-lesson {
    background-color: #f5f5f5;
    color: #333;
}

.next-lesson {
    background-color: #9c27b0;
    color: white;
}

.back-to-curriculum {
    background-color: #f5f5f5;
    color: #333;
    margin: 0 auto;
}

.next-lesson:hover {
    background-color: #8e24aa;
}

.prev-lesson:hover, .back-to-curriculum:hover {
    background-color: #e0e0e0;
}

/* Lesson Content Styles */
.lesson-placeholder {
    background-color: #f5f5f5;
    border: 1px dashed #ccc;
    border-radius: 5px;
    padding: 20px;
    margin: 20px 0;
    text-align: center;
    color: #666;
}

.allyship-reflection-box {
    background-color: #f8f9fa;
    border: 1px solid #e0e0e0;
    border-radius: 5px;
    padding: 20px;
    margin: 20px 0;
}

.allyship-reflection-box textarea {
    width: 100%;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 4px;
    margin-bottom: 10px;
}

/* Graphic Novella */
.wp-block-columns {
    margin-bottom: 15px;
}

.wp-block-column {
    background-color: #f8f9fa;
    border: 1px solid #e0e0e0;
    border-radius: 5px;
    padding: 15px;
}

.take-quiz-button {
    display: inline-block;
    background-color: #9c27b0;
    color: white;
    padding: 10px 20px;
    border-radius: 4px;
    text-decoration: none;
    font-weight: bold;
    cursor: pointer;
}

.take-quiz-button:hover {
    background-color: #8e24aa;
}

/* Scenarios/Quiz */
.allyship-scenarios {
    margin: 20px 0;
}

.scenario {
    background-color: #f8f9fa;
    border: 1px solid #e0e0e0;
    border-radius: 5px;
    padding: 20px;
    margin-bottom: 20px;
}

.scenario h4 {
    margin-top: 0;
}

.scenario-options {
    margin: 15px 0;
}

.option {
    margin-bottom: 10px;
}

.option label {
    font-weight: normal;
    cursor: pointer;
}

.feedback {
    background-color: #f8f8f8;
    border-left: 4px solid;
    padding: 10px 15px;
    margin-top: 15px;
    display: none;
}

.correct-feedback {
    border-color: #4caf50;
}

.incorrect-feedback {
    border-color: #f44336;
}

.quiz-results {
    margin-top: 20px;
    padding: 15px;
    background-color: #f3e5f5;
    border-radius: 5px;
    border-left: 4px solid #9c27b0;
}

.quiz-complete-message {
    margin-top: 10px;
    padding: 10px;
    background-color: #e8f5e9;
    border-radius: 4px;
    border-left: 4px solid #4caf50;
}

/* Commitment Builder */
.commitment-builder {
    background-color: #f8f9fa;
    border: 1px solid #e0e0e0;
    border-radius: 5px;
    padding: 20px;
    margin: 20px 0;
}

.commitment-cards {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    margin: 15px 0;
}

.commitment-card {
    flex: 1;
    min-width: 250px;
    background-color: white;
    border: 1px solid #ddd;
    border-radius: 5px;
    padding: 15px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.05);
}

.commitment-card.selected {
    border-color: #9c27b0;
    box-shadow: 0 0 0 2px #9c27b0;
}

.commitment-card h5 {
    margin-top: 0;
}

.select-action {
    padding: 5px 10px;
    background-color: #eee;
    border: 1px solid #ddd;
    border-radius: 3px;
    cursor: pointer;
}

.select-action.selected {
    background-color: #9c27b0;
    color: white;
    border-color: #9c27b0;
}

#custom-commitment {
    width: 100%;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 4px;
    margin-bottom: 15px;
}

.commitment-actions {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
    margin-bottom: 15px;
}

.share-option {
    margin: 15px 0;
}

.privacy-note {
    font-size: 12px;
    color: #555;
    margin-top: 15px;
}

/* Lesson Completion */
.allyship-lesson-completion {
    background-color: #f8f9fa;
    border: 1px solid #e0e0e0;
    border-radius: 5px;
    padding: 20px;
    margin-top: 40px;
}

.completion-status {
    display: flex;
    align-items: center;
    margin: 15px 0;
}

.completion-icon {
    margin-right: 15px;
}

.completion-icon.incomplete .dashicons {
    color: #9e9e9e;
    font-size: 24px;
}

.completion-icon.complete .dashicons {
    color: #4caf50;
    font-size: 24px;
}

.completion-actions {
    display: flex;
    gap: 10px;
    margin-top: 20px;
}

.mark-complete-button {
    background-color: #9c27b0;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 4px;
    cursor: pointer;
    font-weight: 500;
}

.mark-complete-button:hover {
    background-color: #8e24aa;
}

.back-to-curriculum {
    background-color: #f5f5f5;
    color: #333;
    text-decoration: none;
    padding: 10px 20px;
    border-radius: 4px;
    display: inline-block;
}

/* Notification */
.allyship-notification {
    position: fixed;
    bottom: 20px;
    right: 20px;
    background-color: #9c27b0;
    color: white;
    padding: 15px 25px;
    border-radius: 4px;
    font-weight: 500;
    box-shadow: 0 2px 10px rgba(0,0,0,0.2);
    z-index: 1000;
    opacity: 0;
    transform: translateY(20px);
    transition: opacity 0.3s ease, transform 0.3s ease;
}

.allyship-notification.show {
    opacity: 1;
    transform: translateY(0);
}

/* Mobile Responsiveness */
@media (max-width: 768px) {
    .commitment-cards {
        flex-direction: column;
    }
    
    .commitment-card {
        min-width: 100%;
    }
    
    .commitment-actions {
        flex-direction: column;
    }
    
    .commitment-actions button {
        width: 100%;
    }
    
    .completion-actions {
        flex-direction: column;
    }
    
    .completion-actions button,
    .completion-actions a {
        width: 100%;
        text-align: center;
    }
    
    .lesson-navigation {
        flex-direction: column;
    }
    
    .lesson-navigation a {
        width: 100%;
        justify-content: center;
    }
    
    .achievement-container {
        grid-template-columns: 1fr;
    }
}
CSS;

        // Save CSS file
        $assets_dir = WP_CONTENT_DIR . '/plugins/allyship-system/assets';
        if (!file_exists($assets_dir)) {
            mkdir($assets_dir, 0755, true);
        }
        
        file_put_contents($assets_dir . '/allyship-styles.css', $css);
        echo "Created allyship CSS file\n";
    }
    
    /**
     * Create JS for allyship system
     */
    private function create_js() {
        $js = <<<JS
/**
 * Allyship System JavaScript
 *
 * Completely independent from other systems
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all allyship components
    initAllyshipSystem();
});

/**
 * Initialize the allyship system
 */
function initAllyshipSystem() {
    // Track completed lessons
    initCompletionTracking();
    
    // Initialize quiz functionality
    initQuizSystem();
    
    // Initialize commitment builder
    initCommitmentBuilder();
    
    // Initialize reflection system
    initReflectionSystem();
}

/**
 * Initialize lesson completion tracking
 */
function initCompletionTracking() {
    // Load completed lessons
    const completedLessons = getCompletedLessons();
    
    // Update UI based on completion status
    updateCompletionUI(completedLessons);
    
    // Set up completion button event listener
    const completeButtons = document.querySelectorAll('.mark-complete-button');
    completeButtons.forEach(button => {
        button.addEventListener('click', function() {
            const lessonSlug = this.closest('.allyship-lesson-completion').getAttribute('data-lesson-slug');
            if (lessonSlug) {
                markLessonComplete(lessonSlug);
            }
        });
    });
    
    // Set up reset button event listener
    const resetButton = document.querySelector('.reset-allyship-progress');
    if (resetButton) {
        resetButton.addEventListener('click', function() {
            resetAllyshipProgress();
        });
    }
}

/**
 * Get completed allyship lessons from localStorage
 */
function getCompletedLessons() {
    const lessonsData = localStorage.getItem('allyship_completed_lessons');
    return lessonsData ? JSON.parse(lessonsData) : [];
}

/**
 * Mark a lesson as complete
 */
function markLessonComplete(lessonSlug) {
    const completedLessons = getCompletedLessons();
    
    // Don't add duplicates
    if (!completedLessons.includes(lessonSlug)) {
        // Add to completed list
        completedLessons.push(lessonSlug);
        
        // Save to localStorage
        localStorage.setItem('allyship_completed_lessons', JSON.stringify(completedLessons));
        
        // Update UI
        updateCompletionUI(completedLessons);
        
        // Show notification
        showAllyshipNotification('Lesson completed! +100 points earned');
    }
}

/**
 * Reset allyship progress
 */
function resetAllyshipProgress() {
    // Clear localStorage
    localStorage.setItem('allyship_completed_lessons', JSON.stringify([]));
    localStorage.removeItem('allyship_reflection');
    localStorage.removeItem('allyship_commitment');
    
    // Update UI
    updateCompletionUI([]);
    
    // Reset other elements
    const reflectionTextarea = document.getElementById('allyship-reflection');
    if (reflectionTextarea) {
        reflectionTextarea.value = '';
    }
    
    const customCommitment = document.getElementById('custom-commitment');
    if (customCommitment) {
        customCommitment.value = '';
    }
    
    // Show notification
    showAllyshipNotification('Allyship progress has been reset');
}

/**
 * Update UI based on completion status
 */
function updateCompletionUI(completedLessons) {
    // Get total lessons count
    // We can count all the lesson links on the curriculum page
    const totalLessons = document.querySelectorAll('.allyship-lesson-link').length || 6; // Default to 6 if not found
    const completedCount = completedLessons.length;
    
    // Update lesson links on curriculum page
    const lessonLinks = document.querySelectorAll('.allyship-lesson-link');
    lessonLinks.forEach(link => {
        const slug = link.getAttribute('data-lesson-slug');
        if (completedLessons.includes(slug)) {
            link.classList.add('completed');
        } else {
            link.classList.remove('completed');
        }
    });
    
    // Update progress bar
    const progressBars = document.querySelectorAll('.allyship-progress-bar');
    const progressPercent = Math.round((completedCount / totalLessons) * 100);
    
    progressBars.forEach(bar => {
        bar.style.width = progressPercent + '%';
    });
    
    // Update progress text
    const progressTexts = document.querySelectorAll('.lessons-completed');
    progressTexts.forEach(text => {
        text.textContent = completedCount + ' of ' + totalLessons + ' lessons completed';
    });
    
    // Update points
    const pointsTexts = document.querySelectorAll('.allyship-points');
    const totalPoints = completedCount * 100;
    pointsTexts.forEach(text => {
        text.textContent = totalPoints + ' points earned';
    });
    
    // Update all lesson completion elements on the page
    const lessonCompletionElements = document.querySelectorAll('.allyship-lesson-completion');
    lessonCompletionElements.forEach(element => {
        const lessonSlug = element.getAttribute('data-lesson-slug');
        const isCompleted = completedLessons.includes(lessonSlug);
        
        // Update complete/incomplete elements
        const completeElements = element.querySelectorAll('.complete');
        const incompleteElements = element.querySelectorAll('.incomplete');
        
        if (isCompleted) {
            completeElements.forEach(el => el.style.display = 'block');
            incompleteElements.forEach(el => el.style.display = 'none');
            
            // Hide mark complete button
            const completeButton = element.querySelector('.mark-complete-button');
            if (completeButton) {
                completeButton.style.display = 'none';
            }
        } else {
            completeElements.forEach(el => el.style.display = 'none');
            incompleteElements.forEach(el => el.style.display = 'block');
            
            // Show mark complete button
            const completeButton = element.querySelector('.mark-complete-button');
            if (completeButton) {
                completeButton.style.display = 'inline-block';
            }
        }
    });
    
    // Update achievements
    updateAllyshipAchievements(completedLessons);
}

/**
 * Update achievements based on completed lessons
 */
function updateAllyshipAchievements(completedLessons) {
    // Allyship Foundation Achievement
    const foundationAchievement = document.querySelector('.allyship-foundation');
    if (foundationAchievement) {
        if (completedLessons.includes('what-is-allyship-intro')) {
            foundationAchievement.classList.remove('locked');
            foundationAchievement.classList.add('unlocked');
        } else {
            foundationAchievement.classList.remove('unlocked');
            foundationAchievement.classList.add('locked');
        }
    }
    
    // Reflection Achievement
    const reflectionAchievement = document.querySelector('.allyship-reflection');
    if (reflectionAchievement) {
        if (completedLessons.includes('what-is-allyship-reflection')) {
            reflectionAchievement.classList.remove('locked');
            reflectionAchievement.classList.add('unlocked');
        } else {
            reflectionAchievement.classList.remove('unlocked');
            reflectionAchievement.classList.add('locked');
        }
    }
    
    // Knowledge Achievement
    const knowledgeAchievement = document.querySelector('.allyship-knowledge');
    if (knowledgeAchievement) {
        if (completedLessons.includes('what-is-allyship-quiz')) {
            knowledgeAchievement.classList.remove('locked');
            knowledgeAchievement.classList.add('unlocked');
        } else {
            knowledgeAchievement.classList.remove('unlocked');
            knowledgeAchievement.classList.add('locked');
        }
    }
    
    // Commitment Achievement
    const commitmentAchievement = document.querySelector('.allyship-commitment');
    if (commitmentAchievement) {
        if (completedLessons.includes('what-is-allyship-commitment')) {
            commitmentAchievement.classList.remove('locked');
            commitmentAchievement.classList.add('unlocked');
        } else {
            commitmentAchievement.classList.remove('unlocked');
            commitmentAchievement.classList.add('locked');
        }
    }
    
    // Complete Module Achievement
    const completeAchievement = document.querySelector('.allyship-complete');
    if (completeAchievement) {
        const requiredLessons = [
            'what-is-allyship-intro',
            'what-is-allyship-video',
            'what-is-allyship-reflection',
            'what-is-allyship-novella',
            'what-is-allyship-quiz',
            'what-is-allyship-commitment'
        ];
        
        const allCompleted = requiredLessons.every(slug => completedLessons.includes(slug));
        
        if (allCompleted) {
            completeAchievement.classList.remove('locked');
            completeAchievement.classList.add('unlocked');
        } else {
            completeAchievement.classList.remove('unlocked');
            completeAchievement.classList.add('locked');
        }
    }
}

/**
 * Show notification
 */
function showAllyshipNotification(message) {
    // Remove any existing notifications
    const existingNotification = document.querySelector('.allyship-notification');
    if (existingNotification) {
        existingNotification.remove();
    }
    
    // Create notification
    const notification = document.createElement('div');
    notification.className = 'allyship-notification';
    notification.textContent = message;
    document.body.appendChild(notification);
    
    // Show notification
    setTimeout(() => {
        notification.classList.add('show');
        
        // Hide after delay
        setTimeout(() => {
            notification.classList.remove('show');
            
            // Remove from DOM after fade out
            setTimeout(() => {
                notification.remove();
            }, 500);
        }, 3000);
    }, 10);
}

/**
 * Initialize quiz system
 */
function initQuizSystem() {
    // Set up quiz radio buttons
    const quizOptions = document.querySelectorAll('.scenario .option input');
    
    if (quizOptions.length > 0) {
        let correctAnswers = 0;
        const totalQuestions = document.querySelectorAll('.scenario').length;
        const resultDisplay = document.querySelector('.correct-count');
        const completeMessage = document.querySelector('.quiz-complete-message');
        
        quizOptions.forEach(option => {
            option.addEventListener('change', function() {
                const scenario = this.closest('.scenario');
                const selectedOption = this.closest('.option');
                const isCorrect = selectedOption.getAttribute('data-correct') === 'true';
                
                // Hide all feedback in this scenario
                scenario.querySelectorAll('.feedback').forEach(feedback => {
                    feedback.style.display = 'none';
                });
                
                // Show appropriate feedback
                if (isCorrect) {
                    scenario.querySelector('.correct-feedback').style.display = 'block';
                    
                    // Track correct answers
                    correctAnswers++;
                    if (resultDisplay) {
                        resultDisplay.textContent = correctAnswers;
                    }
                    
                    // Check if all questions are answered correctly
                    if (correctAnswers === totalQuestions && completeMessage) {
                        completeMessage.style.display = 'block';
                    }
                } else {
                    scenario.querySelector('.incorrect-feedback').style.display = 'block';
                }
            });
        });
    }
    
    // Scroll to quiz when button clicked
    const quizButtons = document.querySelectorAll('.take-quiz-button');
    quizButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            
            // If button links to another page, navigate there
            if (this.getAttribute('href')) {
                window.location.href = this.getAttribute('href');
                return;
            }
            
            // Otherwise scroll to quiz section
            const quizSection = document.querySelector('.allyship-scenarios');
            if (quizSection) {
                quizSection.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });
}

/**
 * Initialize commitment builder
 */
function initCommitmentBuilder() {
    // Handle action selection
    const selectButtons = document.querySelectorAll('.select-action');
    selectButtons.forEach(button => {
        button.addEventListener('click', function() {
            // Reset all buttons and cards
            selectButtons.forEach(btn => {
                btn.classList.remove('selected');
                btn.closest('.commitment-card').classList.remove('selected');
            });
            
            // Select this button and card
            this.classList.add('selected');
            this.closest('.commitment-card').classList.add('selected');
            
            // Get the commitment text
            const commitmentText = this.closest('.commitment-card').querySelector('ul').textContent;
            
            // Store the selection
            localStorage.setItem('allyship_commitment', commitmentText);
        });
    });
    
    // Handle custom commitment
    const customCommitment = document.getElementById('custom-commitment');
    if (customCommitment) {
        customCommitment.addEventListener('input', function() {
            // Clear other selections
            selectButtons.forEach(btn => {
                btn.classList.remove('selected');
                btn.closest('.commitment-card').classList.remove('selected');
            });
            
            // Store the custom commitment
            localStorage.setItem('allyship_commitment', this.value);
        });
        
        // Restore any saved custom commitment
        const savedCommitment = localStorage.getItem('allyship_commitment');
        if (savedCommitment && !savedCommitment.includes('•')) {
            customCommitment.value = savedCommitment;
        }
    }
    
    // Handle commitment buttons
    const saveButton = document.getElementById('save-commitment');
    if (saveButton) {
        saveButton.addEventListener('click', function() {
            const commitment = localStorage.getItem('allyship_commitment');
            if (commitment) {
                showAllyshipNotification('Your commitment has been saved');
                
                // If this is a lesson page, auto-mark as complete
                const lessonElement = document.querySelector('.allyship-lesson-completion[data-lesson-slug="what-is-allyship-commitment"]');
                if (lessonElement) {
                    markLessonComplete('what-is-allyship-commitment');
                }
            } else {
                showAllyshipNotification('Please select or enter a commitment first');
            }
        });
    }
    
    const emailButton = document.getElementById('email-commitment');
    if (emailButton) {
        emailButton.addEventListener('click', function() {
            const commitment = localStorage.getItem('allyship_commitment');
            if (commitment) {
                showAllyshipNotification('Email feature would send: ' + commitment);
            } else {
                showAllyshipNotification('Please select or enter a commitment first');
            }
        });
    }
    
    const reminderButton = document.getElementById('set-reminder');
    if (reminderButton) {
        reminderButton.addEventListener('click', function() {
            const commitment = localStorage.getItem('allyship_commitment');
            if (commitment) {
                showAllyshipNotification('Reminder would be set for: ' + commitment);
            } else {
                showAllyshipNotification('Please select or enter a commitment first');
            }
        });
    }
}

/**
 * Initialize reflection system
 */
function initReflectionSystem() {
    const reflectionTextarea = document.getElementById('allyship-reflection');
    const saveReflectionButton = document.getElementById('save-reflection');
    
    if (reflectionTextarea && saveReflectionButton) {
        // Load any saved reflection
        const savedReflection = localStorage.getItem('allyship_reflection');
        if (savedReflection) {
            reflectionTextarea.value = savedReflection;
        }
        
        // Set up save button
        saveReflectionButton.addEventListener('click', function() {
            localStorage.setItem('allyship_reflection', reflectionTextarea.value);
            showAllyshipNotification('Your reflection has been saved');
            
            // If this is a lesson page, auto-mark as complete
            const lessonElement = document.querySelector('.allyship-lesson-completion[data-lesson-slug="what-is-allyship-reflection"]');
            if (lessonElement) {
                markLessonComplete('what-is-allyship-reflection');
            }
        });
    }
}
JS;

        // Save JS file
        $assets_dir = WP_CONTENT_DIR . '/plugins/allyship-system/assets';
        if (!file_exists($assets_dir)) {
            mkdir($assets_dir, 0755, true);
        }
        
        file_put_contents($assets_dir . '/allyship-scripts.js', $js);
        echo "Created allyship JS file\n";
    }
    
    /**
     * Create the plugin file
     */
    private function create_plugin() {
        $plugin_content = <<<PHP
<?php
/**
 * Plugin Name: Allyship System
 * Description: Complete allyship curriculum and tracking system
 * Version: 1.0
 * Author: Claude
 */

// Don't allow direct access
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Main Allyship System Plugin Class
 */
class Allyship_System_Plugin {
    /**
     * Constructor
     */
    public function __construct() {
        // Register post types and taxonomies
        add_action('init', array(\$this, 'register_post_types'));
        
        // Enqueue scripts and styles
        add_action('wp_enqueue_scripts', array(\$this, 'enqueue_assets'));
        
        // Add init action for first run
        add_action('admin_init', array(\$this, 'maybe_init_system'));
    }
    
    /**
     * Initialize the system if it's the first run
     */
    public function maybe_init_system() {
        // Only run once
        if (!get_option('allyship_system_initialized')) {
            \$this->register_post_types();
            
            // Mark as initialized
            update_option('allyship_system_initialized', true);
        }
    }
    
    /**
     * Register post types and taxonomies
     */
    public function register_post_types() {
        // Allyship Lesson post type
        register_post_type('allyship_lesson', array(
            'labels' => array(
                'name'               => 'Allyship Lessons',
                'singular_name'      => 'Allyship Lesson',
                'menu_name'          => 'Allyship',
                'add_new'            => 'Add New Lesson',
                'add_new_item'       => 'Add New Allyship Lesson',
                'edit_item'          => 'Edit Allyship Lesson',
                'new_item'           => 'New Allyship Lesson',
                'view_item'          => 'View Allyship Lesson',
                'search_items'       => 'Search Allyship Lessons',
                'not_found'          => 'No allyship lessons found',
                'not_found_in_trash' => 'No allyship lessons found in trash'
            ),
            'public'              => true,
            'has_archive'         => true,
            'publicly_queryable'  => true,
            'hierarchical'        => false,
            'supports'            => array('title', 'editor', 'thumbnail', 'excerpt', 'author'),
            'rewrite'             => array('slug' => 'allyship-lesson'),
            'show_in_rest'        => true,
            'menu_icon'           => 'dashicons-groups',
            'capability_type'     => 'post'
        ));
        
        // Module taxonomy
        register_taxonomy('allyship_module', 'allyship_lesson', array(
            'labels' => array(
                'name'          => 'Modules',
                'singular_name' => 'Module',
                'search_items'  => 'Search Modules',
                'all_items'     => 'All Modules',
                'edit_item'     => 'Edit Module',
                'update_item'   => 'Update Module',
                'add_new_item'  => 'Add New Module',
                'new_item_name' => 'New Module Name',
                'menu_name'     => 'Modules'
            ),
            'hierarchical'      => true,
            'show_ui'           => true,
            'show_admin_column' => true,
            'query_var'         => true,
            'rewrite'           => array('slug' => 'allyship-module')
        ));
    }
    
    /**
     * Enqueue assets
     */
    public function enqueue_assets() {
        // Only load on allyship pages
        if (is_singular('allyship_lesson') || is_page('allyship-curriculum')) {
            // Enqueue CSS
            wp_enqueue_style(
                'allyship-styles', 
                plugin_dir_url(__FILE__) . 'assets/allyship-styles.css',
                array(),
                '1.0'
            );
            
            // Enqueue Dashicons
            wp_enqueue_style('dashicons');
            
            // Enqueue JS
            wp_enqueue_script(
                'allyship-scripts',
                plugin_dir_url(__FILE__) . 'assets/allyship-scripts.js',
                array('jquery'),
                '1.0',
                true
            );
        }
    }
}

// Initialize the plugin
new Allyship_System_Plugin();
PHP;

        // Save plugin file
        $plugin_dir = WP_CONTENT_DIR . '/plugins/allyship-system';
        if (!file_exists($plugin_dir)) {
            mkdir($plugin_dir, 0755, true);
        }
        
        file_put_contents($plugin_dir . '/allyship-system.php', $plugin_content);
        echo "Created allyship system plugin file\n";
        
        // Activate the plugin
        activate_plugin(WP_PLUGIN_DIR . '/allyship-system/allyship-system.php');
        echo "Activated allyship system plugin\n";
    }
}

/**
 * Function to setup allyship system
 */
function setup_allyship_system() {
    // Create system
    $system = new Allyship_System();
    
    // Setup everything
    $system->setup();
    
    echo "Allyship system has been set up successfully!\n";
    return true;
}