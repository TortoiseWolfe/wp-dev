# ScriptHammer WordPress Implementation Guide

This guide outlines the architectural principles and roadmap for the ScriptHammer WordPress project, focusing on separating content creation from system automation.

## First Principles

1. **Content vs. Code Separation**
   - Content should be created once, then managed through WordPress
   - Code should handle system setup and infrastructure, not content creation
   - Database should be the source of truth for content

2. **Container Architecture**
   - Containers are ephemeral ("cattle not pets")
   - System should be fully rebuildable without manual intervention
   - Each component should have a single responsibility

3. **Automation First**
   - All operations should be automatable
   - Manual steps should be eliminated where possible
   - Infrastructure should be defined as code

## Current Issues

The current implementation has several architectural issues:

1. **Content embedded in automation scripts**
   - Large blocks of content in bash scripts (`scripthammer.sh`, `demo-content.sh`)
   - Content is recreated on each container rebuild
   - Hard-coded post IDs in templates that break during rebuilds

2. **Tightly coupled components**
   - Band content mixed with system initialization
   - Bots operating directly within WordPress container
   - Template files with hard-coded dependencies

3. **Inefficient rebuild process**
   - Full content recreation on each rebuild
   - No separation between first-run and subsequent runs
   - Brittle dependencies between components

## Refactoring Roadmap

### Phase 1: Content Separation (IMPLEMENTED)

1. **Content Export** ✅
   - WordPress export (WXR) files created for all band content
   - Content safely preserved in `/exports` directory 
   - Export happens automatically at the end of content creation

2. **Content Preservation** ✅
   - Setup script now checks if content exists before recreating
   - If band member posts exist, script skips creation
   - Preserves database content across rebuilds

3. **Future Improvements**
   - Implement slug-based navigation instead of post ID-based navigation
   - Create a dynamic band navigation plugin
   - Further separate content from automation logic

### Phase 2: Bot Independence

1. **Separate Bot Container**
   - Create dedicated container for automation bots
   - Interact with WordPress via API/WP-CLI
   - Maintain clear separation of responsibilities

2. **API-first Approach**
   - Implement REST API endpoints for bot operations
   - Replace direct database access with API calls
   - Document API surface for future extensibility

3. **Event-based Architecture**
   - Replace direct manipulations with event listeners
   - Implement webhook triggers for automation tasks
   - Create logging and monitoring for bot activities

### Phase 3: Infrastructure Improvements

1. **Volume Management**
   - Implement proper data volume strategy
   - Separate configuration from data
   - Implement backup and restore procedures

2. **Environment Parity**
   - Ensure development and production environments match
   - Implement environment-specific configurations
   - Document differences between environments

3. **CI/CD Pipeline**
   - Automate testing and deployment
   - Implement container image versioning
   - Set up blue/green deployments

## Implementation Priorities

1. **Content Extraction (Immediate)**
   - Move content from scripts to WordPress exports
   - Set up content import process
   - Test rebuild with content import

2. **Band Navigation Fix (Short-term)**
   - Implement slug-based navigation instead of ID-based
   - Update templates to use dynamic ID lookup
   - Fix image display issues in templates

3. **Bot Separation (Medium-term)**
   - Create bot container specification
   - Implement API-based communication
   - Move automation scripts to dedicated container

4. **Infrastructure Refinement (Ongoing)**
   - Improve volume management
   - Enhance backup and recovery
   - Document operational procedures

## Technical Specifications

### Content Export/Import

We've successfully implemented a robust content preservation and recovery system using WordPress WXR (WordPress eXtended RSS) format. The solution includes:

#### Content Export
The system automatically exports band content to the `/exports` directory after creation:

- `band-members-000.xml` - Posts in the band-members category
- `music-posts-000.xml` - Posts in the music category
- `pages-000.xml` - Pages including the metronome page

#### Content Preservation
The script checks for existing content before recreating it:

```bash
# Check if band content exists (e.g., check for specific post by slug)
if wp post list --name=meet-ivory-the-melody-master-of-scripthammer --post_type=post --format=count | grep -q "1"; then
  echo "✅ Band content already exists - using existing content"
  # Skip creation and exit
fi
```

#### Content Recovery
If content is accidentally deleted, it can be recovered using new flags:

```bash
# Automatically locate and restore from exports
scripthammer.sh --recover

# Import from a specific file
scripthammer.sh --import=/path/to/export-file.xml
```

These features ensure content survives rebuilds and can be restored if accidentally deleted.

### Dynamic ID Resolution

```php
// Instead of hard-coded IDs:
$band_navigation = array(
    9 => array('prev' => 15, 'next' => 10), // Crash: prev=Ivory, next=Chops
    // ...
);

// Use slug-based lookup:
function get_band_member_by_slug($slug) {
    $posts = get_posts([
        'name' => $slug,
        'post_type' => 'post',
        'category_name' => 'band-members',
        'numberposts' => 1
    ]);
    return !empty($posts) ? $posts[0]->ID : null;
}

$band_navigation = array(
    get_band_member_by_slug('crash') => array(
        'prev' => get_band_member_by_slug('ivory'), 
        'next' => get_band_member_by_slug('chops')
    ),
    // ...
);
```

### Bot Container Specification

```yaml
# Docker Compose excerpt
services:
  automation-bot:
    build:
      context: ./bot
      dockerfile: Dockerfile
    volumes:
      - ./bot/scripts:/scripts
      - ./bot/exports:/exports
    environment:
      - WP_URL=http://wordpress
      - WP_USER=${WP_ADMIN_USER}
      - WP_PASSWORD=${WP_ADMIN_PASSWORD}
    depends_on:
      - wordpress
```

## Success Criteria

1. **Rebuild Resilience**
   - System can be completely rebuilt without content loss
   - No manual intervention required during rebuilds
   - Navigation and relationships preserved across rebuilds

2. **Clean Separation**
   - Content managed through WordPress, not scripts
   - Automation bots operate independently of WordPress
   - Clear interfaces between components

3. **Maintainability**
   - Documentation of all automation processes
   - Simplified onboarding for new developers
   - Reduced complexity in scripts and templates

By following this guide, the ScriptHammer WordPress project will achieve a cleaner architecture with proper separation of concerns, making it more maintainable and resilient to changes.