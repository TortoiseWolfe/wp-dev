# WordPress Development Environment Guidelines

## Production Image with Security Hardening
- Security-hardened production image with Apache security configurations
- Nginx reverse proxy with SSL termination for HTTPS support
- Versioned image tagging for reliable deployment and rollback
- Container Registry: ghcr.io/tortoisewolfe/wp-dev:v0.1.0
- Reduced attack surface with minimal packages and proper permissions
- Health checks for container orchestration reliability

## Current Configuration
- COMPLETED: Gamification features for BuddyPress tutorials
- COMPLETED: Simple demo of gamification in BuddyPress with BuddyX theme  
- COMPLETED: Tutorial completion tracking and progress display
- COMPLETED: Achievements and points system for users
- COMPLETED: Documentation consolidation in readme.md
- IN PROGRESS: Allyship curriculum implementation
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

## Running Hardened Production Image with Nginx
- Version tagged, security-hardened production images are available in the GitHub Container Registry
- Production environment includes nginx reverse proxy with SSL termination
- Example configuration:
  ```bash
  # Build and tag a versioned production image
  docker build --target production -t ghcr.io/tortoisewolfe/wp-dev:v0.1.0 .
  
  # Push to GitHub Container Registry (requires authentication with write:packages permission)
  # Set GITHUB_TOKEN in .env file first
  echo $GITHUB_TOKEN | docker login ghcr.io -u tortoisewolfe --password-stdin
  docker push ghcr.io/tortoisewolfe/wp-dev:v0.1.0
  
  # Run the full production stack with nginx
  docker-compose up -d wordpress-prod wp-prod-setup db nginx
  ```
- Access the production environment through nginx at http://localhost:80 for HTTP or https://localhost:443 for HTTPS
- For production, configure proper domain names and valid SSL certificates

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

## Development Roadmap & Best Practices

### Infrastructure Improvements
- [x] Fix script permissions (`chmod +x setup.sh EnhancedBoot/enhanced-boot.sh devscripts/demo-content.sh`)
- [x] Add nginx reverse proxy with SSL termination for production
- [x] Implement versioned image tagging for better deployment management
- [ ] Add specific version pinning for dependencies in Dockerfile
- [ ] Create separate docker-compose.prod.yml for production configuration
- [ ] Consider using Docker secrets for sensitive data instead of environment variables

### Security Enhancements
- [x] Add HTTPS configuration with Let's Encrypt for production via nginx
- [x] Implement basic Apache security hardening (ServerTokens, ServerSignature, TraceEnable)
- [x] Set proper file permissions for WordPress files
- [ ] Document WordPress security plugins for production
- [ ] Implement additional PHP security configurations
- [ ] Add firewall configuration examples for production servers
- [ ] Add comprehensive security scanning in CI/CD pipeline

### DevOps & CI/CD
- [ ] Document required GitHub secrets for GitHub Actions workflow
- [ ] Add basic tests to run before deployment
- [ ] Enhance health checks for production containers
- [ ] Document recommended monitoring setup
- [ ] Implement centralized logging configuration
- [ ] Add log rotation and management

### Backup & Recovery
- [ ] Add example scripts for automated backups
- [ ] Document a complete disaster recovery procedure
- [ ] Test and document restore procedures

### Performance Optimization
- [ ] Add caching recommendations for production
- [ ] Document load testing procedures
- [ ] Evaluate and document CDN integration options
- [ ] Optimize Docker image size

### Documentation
- [ ] Add environment variable validation in scripts
- [ ] Document routine maintenance tasks
- [ ] Add WordPress core and plugin update strategy
- [ ] Create troubleshooting guide for common issues

### Multi-environment Support
- [ ] Create staging environment configuration
- [ ] Document environment-specific configurations
- [ ] Add proper environment detection in scripts

## Curricula

The environment contains two distinct curricula with separate content but shared gamification mechanics:

### 1. BuddyPress Tutorial Curriculum

A comprehensive tutorial series on building social networks with WordPress, BuddyPress, and BuddyX theme.

#### Content Structure
- **Getting Started**: Introduction, installation, and member profiles
- **Group Management**: Creating groups and setting up discussions
- **BuddyX Theme**: Theme introduction and customization

### 2. Allyship Curriculum

Educational modules focused on allyship in the workplace with interactive learning elements.

#### Content Structure
- **Defining Allyship**: Understanding what allyship means and how to practice it
- **Interactive Elements**: Video, reflection prompts, graphic novella, scenarios
- **Assessment Components**: Quiz scenarios with feedback and commitment builder
- **Action Planning**: Tools for making and tracking allyship commitments

## Gamification

### Implementation Approach: Simple Visual Gamification

Both curricula include basic gamification elements to enhance the learning experience:

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

This simple implementation provides a clear demonstration of how gamification techniques can enhance the learning experience without requiring complex plugins or database integration.