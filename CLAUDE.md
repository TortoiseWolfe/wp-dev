# WordPress Development Environment Guidelines

## Current Configuration
- COMPLETED: Gamification features for BuddyPress tutorials
- COMPLETED: Simple demo of gamification in BuddyPress with BuddyX theme  
- COMPLETED: Tutorial completion tracking and progress display
- COMPLETED: Achievements and points system for users
- Permalinks set to /%postname%/ format for clean URLs
- All gamification elements embedded directly into the curriculum page

## Build & Run Commands
- `docker-compose up -d`: Start WordPress environment
- `docker-compose down`: Stop WordPress environment
- `docker-compose build`: Rebuild Docker images (REQUIRED after script changes)
- `docker-compose down && docker-compose build && docker-compose up -d`: Full rebuild workflow
- `docker-compose exec wordpress wp --allow-root [command]`: Run WP-CLI commands
- `docker-compose exec wordpress bash`: Access WordPress container shell
- `docker-compose exec wordpress /usr/local/bin/devscripts/demo-content.sh`: Populate site with demo content

## IMPORTANT: Changes to Script Files
- Script files are copied into the container during build time
- When you modify scripts in devscripts/ or setup.sh, you MUST rebuild from scratch:
  1. Make changes to scripts
  2. Run `docker-compose down -v` to stop containers and remove volumes
  3. Run `docker image prune -a` to delete all unused images
  4. Run `docker-compose build` to rebuild the image with your changes
  5. Run `docker-compose up -d` to start containers with updated image
  6. Complete one-line command: `docker-compose down -v && docker image prune -a -f && docker-compose build && docker-compose up -d`
- Skipping image deletion will cause your changes to be lost or inconsistent
- NEVER use the 'latest' tag for production images

## Testing
- No specific testing framework implemented
- Manual testing via WordPress admin interface at http://localhost:8000
- Consider phpunit for unit testing if needed

## Code Style Guidelines
- Follow WordPress Coding Standards: https://developer.wordpress.org/coding-standards/
- Use 4 spaces for indentation (not tabs)
- Class and function names should use lowercase with underscores
- Hook names should use lowercase with underscores
- Prioritize security: sanitize inputs, validate data, escape outputs
- Add appropriate docblocks for functions and classes
- Use prefix for custom functions to avoid conflicts

## Environment
- WordPress with BuddyPress using Docker
- Database credentials stored in environment variables
- WordPress configuration managed via wp-config.php

## Gamification

### Implementation Approach: Simple Visual Gamification

The BuddyPress tutorial system includes basic gamification elements to demonstrate the concept:

#### Core Features
- **Visual Progress Tracking**: Progress bar showing completion status (dynamically calculated)
- **Completed Tutorial Indicators**: Visual markers (checkmarks, color changes) for completed tutorials
- **Achievement Badges**: Multiple achievements for different tutorial completions
- **Points System**: Basic points with bonuses for section completion
- **Achievement Tracking**: Both unlocked and locked achievements displayed

#### Visual Implementation
- **Progress Bar**: Shows overall tutorial completion percentage dynamically based on cookie data
- **Checkmarks**: Green checkmarks next to completed tutorials appear automatically
- **Color Coding**: Green left borders for completed tutorials appear automatically
- **Achievements Section**: Color-coded achievement cards unlock based on tutorial completion
- **Locked Achievements**: Greyed-out achievements that indicate what's needed to unlock them
- **Per-Tutorial Gamification**: Each individual tutorial page has:
  - Tutorial progress tracking at the top and bottom
  - Completion status indicators
  - Working "Mark as Complete" buttons that store progress in browser cookies
  - "Continue to Next Tutorial" links that appear after completion
  - Navigation back to the curriculum page

#### Gamification Mechanics
- Base points (100) awarded for each completed tutorial
- Bonus points (150) awarded for completing a section
- Major achievement (500 bonus points) for completing all tutorials
- Visual progress tracking with dynamic percentage calculation
- Achievement unlocks tied to specific tutorial completions
- Browser cookie storage for tracking completed tutorials
- Progress persists between page loads and can be reset
- No database storage needed - client-side implementation
- Progress is tracked per browser, not per user account

This simple implementation provides a clear demonstration of how gamification techniques can enhance the learning experience in BuddyPress without requiring complex plugins or database integration.