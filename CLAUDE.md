# WordPress Development Environment Guidelines

## Current Issue Focus
- Fix tutorial post links in curriculum page
- Permalinks are set to /%postname%/ but links still show as ?p=XX
- Solution should be minimal and focused on fixing the specific issue
- The problem is only with links in the curriculum page

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