# WordPress Development Environment Guidelines

## Build & Run Commands
- `docker-compose up -d`: Start WordPress environment
- `docker-compose down`: Stop WordPress environment
- `docker-compose exec wordpress wp --allow-root [command]`: Run WP-CLI commands
- `docker-compose exec wordpress bash`: Access WordPress container shell

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