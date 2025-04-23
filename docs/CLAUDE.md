# WordPress Development Environment Guidelines

## ⚠️ ATTENTION CLAUDE: CHECK MEMORY LOG FIRST! ⚠️
When starting a new session, IMMEDIATELY check `/memory_log.txt` first to restore context. DO NOT GIVE UP due to system load - the system can handle it despite high load and limited RAM. Follow the critical sequence in memory_log.txt completely.

## ⚠️ CLAUDE CRASH RECOVERY PROCEDURE ⚠️
If Claude crashes with "Error: kill EPERM" or similar errors:
1. Check `memory_log.txt` to see what you were working on
2. Continue from where you left off, following the "NEXT STEPS" section
3. Update `memory_log.txt` with your current progress after making significant changes
4. Document any errors encountered with their solutions

## ✅ ENVIRONMENT VARIABLE SOLUTION IMPLEMENTED ✅
The issue with environment variables not being passed to containers has been fixed by modifying the setup-secrets.sh script to update the .env file with actual secret values. Docker Compose prioritizes .env file over shell environment variables, which was causing the issue.

## ⚠️ DOCKER PERMISSIONS FIX ⚠️
The "Error: kill EPERM" Docker permission error has been fixed in SSL setup script by implementing a consistent root-context detection pattern:

### Root Cause of EPERM Errors
The error occurred when scripts already running with sudo privileges internally tried to use sudo again. This created a "sudo within sudo" situation causing permission conflicts, resulting in "Error: kill EPERM" errors when Docker tried to manage containers.

### Solution Implemented
1. Running the script with sudo: `sudo ./scripts/ssl/ssl-setup.sh` (required)
2. Inside the script, detecting root context with `if [ "$(id -u)" -eq 0 ]` checks before ALL docker commands
3. Using appropriate command form based on context:
   - Using `docker-compose` directly when running as root (prevents sudo inside sudo)
   - Using `sudo -E docker-compose` when not running as root (ensures proper permissions)
4. This pattern has been applied consistently to ALL docker/docker-compose commands in the script
5. The same handling is applied to docker inspect and related commands

### Pattern Example
```bash
# Example of the pattern used throughout the script
if [ "$(id -u)" -eq 0 ]; then
  # Running as root (via sudo), use docker commands directly
  docker-compose command
else
  # Not running as root, use sudo -E with docker commands
  sudo -E docker-compose command
fi
```

### Important Usage Notes
- The script MUST still be run with sudo: `sudo ./scripts/ssl/ssl-setup.sh`
- Do NOT add additional sudo commands inside scripts already run with sudo
- When adding new docker commands to any script, always use this pattern
- Use sudo -E (not just sudo) when environment variables need to be preserved

## ✅ WP-CLI AUTOMATION OPTIMIZED ✅
WP-CLI auto-installation now uses a streamlined approach:
1. Direct WordPress install commands in docker-compose.yml
2. Using the versioned v0.1.1 image from GitHub Container Registry
3. Consistent setup with proper MySQL database configuration
4. Setup completes automatically with proper environment variables

## ✅ WSL COMPATIBILITY IMPROVED ✅
The WordPress setup in WSL (Windows Subsystem for Linux) has been enhanced:
1. Apache mod_rewrite now properly enabled for permalink functionality
2. Automatic IP detection for proper site URL configuration
3. WordPress configured with correct site URL for permalinks to work
4. Proper .htaccess file creation for WordPress rewrite rules
5. Note: Demo content creation is still in progress after initial setup

## ⚠️ CRITICAL REQUIREMENT: ALWAYS FOLLOW THIS SEQUENCE ⚠️

### For Production Environment:
1. Run `source ./scripts/setup-secrets.sh` first (this updates .env file automatically with GSM secrets)
2. Run `sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"` 
3. Run `sudo -E docker-compose up -d [services]` to start containers
4. Always use sudo with Docker commands to avoid permission errors ("Error: kill EPERM")

### For Local Development Environment:
1. Run `source ./scripts/dev/setup-local-dev.sh` to generate secure local development credentials
   - GamiPress plugin is always installed automatically
   - You'll be asked if you want to skip demo content installation
   - In WSL, the script automatically detects and uses your WSL IP address for proper permalink functionality
2. Run `sudo -E docker-compose up -d wordpress wp-setup db` to start dev containers
3. Access WordPress at:
   - When running in WSL, you MUST use the IP address: http://172.x.x.x:8000 (exact IP shown during setup)
   - WARNING: Using "localhost" in WSL will cause broken links and connection failures
   - From Windows host, also use the WSL IP address shown during setup
   - The setup automatically configures WordPress with the correct WSL IP for proper functionality
4. Always use sudo with Docker commands to avoid permission errors
5. All permalinks should work automatically - no manual configuration needed
6. The demo content creation process continues in the background after initial setup - wait for it to complete before testing all site functionality

## ⚠️ GITHUB AUTHENTICATION ERROR RESOLUTION ⚠️
If you encounter "Error response from daemon: Head: unauthorized" or "Error response from daemon: denied" when pulling Docker images:

1. **Verify Service Account Permissions**: Ensure your GCP service account has Secret Manager Secret Accessor role
2. **Check GitHub PAT Permissions**: Your GitHub token MUST have `read:packages` scope for the specific repository
3. **Generate New Token if Needed**:
   ```bash
   # 1. Create new token at https://github.com/settings/tokens with read:packages permission
   # 2. Save new token in Google Secret Manager
   gcloud secrets versions add GITHUB_TOKEN --data-file=<(echo -n "your_new_token")
   # 3. Follow complete authentication sequence below
   ```
4. **Complete Authentication Sequence**:
   ```bash
   # ALWAYS run these steps in sequence:
   source ./setup-secrets.sh
   sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"
   sudo -E docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.1
   ```

## Production Image with Security Hardening
- Security-hardened production image with Apache security configurations
- Nginx reverse proxy with SSL termination for HTTPS support
- Versioned image tagging for reliable deployment and rollback
- Container Registry: ghcr.io/tortoisewolfe/wp-dev:v0.1.1
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

## ⚠️ DEBUGGER NOTES: ScriptHammer Issues ⚠️

### Band Group Member Display Issue

The ScriptHammer band group shows "0 members" in the UI even though the backend database shows members exist. Key findings:

### Post Category Display Issues

Two category display issues have been fixed:

1. **Numeric Category IDs**: Previously, categories sometimes displayed as a numeric ID (e.g., "3") instead of their proper name ("Tour"). Fixed by:
   - Creating categories first with proper slugs before assigning to posts
   - Using `term list` to get category IDs by slug reliably 
   - Assigning categories during post creation with the `--post_category` parameter

2. **BuddyX Theme Limitation**: BuddyX theme only shows the first category in posts with multiple categories. Fixed by:
   - Adding a CSS/JS fix to `simple-gamification.php` plugin
   - The fix ensures all categories in a post are displayed, not just the first one
   - This plugin-based approach survives theme updates (following WordPress best practices)

Note: The second issue is a limitation in the BuddyX theme's template, specifically in `entry_categories.php` which contains a `break` after displaying the first category.

1. Script `/devscripts/scripthammer.sh` creates users and adds them to a BuddyPress group
2. Backend verification shows 12 confirmed members in database table `wp_bp_groups_members`
3. UI still shows "0 members" at `http://172.26.72.153:8000/members/ivory/groups/`
4. Attempted fixes:
   - Added direct database entries with `is_confirmed=1`
   - Updated user metadata with `bp_confirmed_member_of_group_*`
   - Manually updated member count in database
   - Cleared WordPress and BuddyPress caches
   - Rewritten script to handle both existing and new groups correctly

Debug steps:
1. Check the BuddyPress version - there might be differences in how member counts are stored/calculated between versions
2. Examine BuddyPress theme templates that display group members
3. Look for any group-member count transients in the wp_options table that need clearing
4. Test on a totally fresh install by running `docker-compose down -v` then `docker-compose up -d`
5. Check for any group member status other than `is_confirmed=1` that might be needed
6. Examine BuddyPress REST API responses for group member data
7. Verify if this is just a display issue or if functionality is also affected

## Google Secret Manager Configuration
The following secrets are stored in Google Secret Manager and should NOT be duplicated in .env:
- GITHUB_TOKEN - GitHub personal access token
- MYSQL_PASSWORD - Database user password
- MYSQL_ROOT_PASSWORD - Database root password
- WP_ADMIN_EMAIL - WordPress admin email
- WP_ADMIN_PASSWORD - WordPress admin password

To use these secrets with Docker Compose, run the setup-secrets.sh script:
```bash
# Load secrets from Google Secret Manager into environment variables
source ./setup-secrets.sh

# Run Docker Compose with the exported environment variables
sudo -E docker-compose up -d
```

## 📝 Dev Notes for Pair Programming

- Validate presence of `GITHUB_TOKEN` early in `setup-secrets.sh` and deployment scripts; fail fast with a clear error if missing.
- Add `set -euo pipefail` at the top of all Bash scripts to enforce strict error handling.
- Create a unified helper script (e.g., `scripts/deploy.sh`) or Makefile target encapsulating:
  - `source ./scripts/setup-secrets.sh`
  - GHCR login via `docker login`
  - `docker-compose pull` and `docker-compose up --no-build`
- Automate image updating logic in CI/CD, ensuring fresh pulls and no unintended rebuilds.
- Structure `.env` variables by category (database, WordPress, SSL, GHCR) in `.env.example` and `readme.md`.
- Support environment-specific `.env` files (`.env.development`, `.env.production`) and switch via an `ENV` variable.
- Leverage Docker Compose profiles (`dev`, `prod`) to conditionally include services.
- Document secret rotation procedures in Google Secret Manager and how to update deployed secrets.
- Integrate GitHub Actions workflows for build, push, pull, and deploy steps, including secret injection.
- Add service health checks (Nginx, DB) in documentation to verify readiness before routing traffic.
- Ensure `.gitignore` explicitly excludes production `.env` files to avoid leaking secrets.
- Provide example GitHub Actions YAML snippets for common automation tasks.

⚠️ **CRITICAL: ALWAYS run setup-secrets.sh before starting containers (especially wordpress-prod)!** ⚠️
If you see "The MYSQL_PASSWORD variable is not set" errors, you forgot this step!

### Testing Production Image
For testing the production image with scripthammer.com domain, ALWAYS use this full sequence:
```bash
# 1. Load secrets first
source ./setup-secrets.sh

# 2. Log in to GitHub Container Registry (CRITICAL STEP - NEVER SKIP)
sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"

# 3. Start all required production containers
sudo -E docker-compose up -d wordpress-prod wp-prod-setup db nginx
```

## Local .env Configuration
The local .env file should ONLY contain non-sensitive values not stored in Google Secret Manager:
- MYSQL_DATABASE=wordpress
- WORDPRESS_DB_HOST=db:3306
- WORDPRESS_DB_NAME=wordpress
- MYSQL_USER=wordpress
- WORDPRESS_DB_USER=wordpress
- WP_SITE_URL=https://scripthammer.com
- WP_SITE_TITLE="Allyship Learning Portal"
- WP_ADMIN_USER=admin
- DOMAIN_NAME=scripthammer.com
- CERTBOT_EMAIL=admin@example.com

## Build & Run Commands

### Before Running ANY Command:
- **ALWAYS** run `source ./setup-secrets.sh` BEFORE docker-compose commands
- **ALWAYS** run GitHub Container Registry login `sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"` BEFORE image pulls
- Skipping either step will result in authentication errors or empty passwords

### Common Commands:
- `source ./setup-secrets.sh && sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN" && sudo -E docker-compose up -d`: Start WordPress environment (CORRECT full sequence)
- `sudo docker-compose down`: Stop WordPress environment
- `sudo docker-compose build`: Rebuild Docker images (REQUIRED after script changes)
- `source ./setup-secrets.sh && sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN" && sudo docker-compose down && sudo docker-compose build && sudo -E docker-compose up -d`: Full rebuild workflow
- `sudo docker-compose exec wordpress wp --allow-root [command]`: Run WP-CLI commands
- `sudo docker-compose exec wordpress bash`: Access WordPress container shell
- `sudo docker-compose exec wordpress /usr/local/bin/devscripts/demo-content.sh`: Populate site with demo content

**CRITICAL: ALWAYS use sudo with Docker commands. Use sudo -E when environment variables need to be preserved. ALWAYS login to GitHub Container Registry AFTER sourcing secrets but BEFORE pulling images.**

## Running Hardened Production Image with Nginx
- Version tagged, security-hardened production images are available in the GitHub Container Registry
- Production environment includes nginx reverse proxy with SSL termination

### ✅ STREAMLINED WORDPRESS SETUP ✅
The setup process has been optimized by directly executing WordPress installation commands in docker-compose.yml:

1. **Production Environment Setup**:
   ```bash
   # ALWAYS USE THIS SEQUENCE (in order):
   source ./scripts/setup-secrets.sh
   sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"
   sudo -E docker compose down -v
   sudo -E docker compose up -d
   ```

2. **Verify Installation Success**:
   ```bash
   # Check if WordPress is installed
   sudo -E docker compose exec wordpress-prod wp core is-installed --allow-root
   
   # Verify BuddyPress plugin
   sudo -E docker compose exec wordpress-prod wp plugin list --allow-root
   ```

The system now uses the v0.1.1 versioned image from the container registry with core installation automated in the docker-compose configuration. No manual troubleshooting of WP-CLI should be needed.

### ⚠️ TROUBLESHOOTING SSL ISSUES ⚠️
If you encounter SSL/HTTPS configuration issues:

1. **Check SSL Certificate Status**:
   ```bash
   # Verify if certificates exist
   sudo -E docker-compose exec certbot certbot certificates
   
   # Check if certificate files exist in the volume
   sudo ls -la ./nginx/ssl/live/yourdomain.com/
   ```

2. **Manually Generate SSL Certificates**:
   ```bash
   # Generate SSL certificates using the included script
   sudo ./ssl-setup.sh
   
   # OR manually request certificates with certbot
   sudo -E docker-compose exec certbot certbot certonly \
     --webroot \
     --webroot-path=/var/www/certbot \
     --email your.email@example.com \
     --agree-tos \
     --no-eff-email \
     -d yourdomain.com \
     -d www.yourdomain.com
   ```

3. **Verify Nginx Configuration**:
   ```bash
   # Check Nginx configuration
   sudo cat ./nginx/conf/default.conf
   
   # Test Nginx configuration (from inside container)
   sudo -E docker-compose exec nginx nginx -t
   
   # Restart Nginx after changes
   sudo -E docker-compose restart nginx
   ```

4. **Troubleshoot Domain Resolution**:
   ```bash
   # Check if domain resolves to your server
   dig yourdomain.com
   
   # Check site URL in WordPress
   sudo -E docker-compose exec wordpress-prod wp option get siteurl --allow-root
   ```

### DevOps Workflow From Development to Production

1. **Authenticate with Google Secret Manager** to access GitHub token:
   ```bash
   # Log into Google Cloud
   gcloud auth login
   
   # Set your project ID
   gcloud config set project YOUR_PROJECT_ID
   
   # List available secrets
   gcloud secrets list
   
   # Get the GitHub token
   GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="GITHUB_TOKEN")
   ```

2. **Authenticate with GitHub Container Registry**:
   ```bash
   # Log into GitHub Container Registry using the token
   docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"
   ```

3. **Pull the hardened production image**:
   ```bash
   docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.1
   ```

4. **Create and configure environment with secrets from Google Secret Manager**:
   ```bash
   # Create directory structure if needed
   mkdir -p /var/www/wp-dev
   
   # Clone the repository if needed
   git clone https://github.com/TortoiseWolfe/wp-dev.git /var/www/wp-dev
   cd /var/www/wp-dev
   
   # Run the secrets setup script (which populates .env automatically)
   source ./scripts/setup-secrets.sh
   
   # Alternatively, create .env file manually with secrets from Google Secret Manager
   cat > /var/www/wp-dev/.env << EOF
   # MySQL credentials
   MYSQL_ROOT_PASSWORD=$(gcloud secrets versions access latest --secret="MYSQL_ROOT_PASSWORD")
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wordpress
   MYSQL_PASSWORD=$(gcloud secrets versions access latest --secret="MYSQL_PASSWORD")
   
   # WordPress database connection
   WORDPRESS_DB_HOST=db:3306
   WORDPRESS_DB_USER=wordpress
   WORDPRESS_DB_PASSWORD=$(gcloud secrets versions access latest --secret="MYSQL_PASSWORD")
   WORDPRESS_DB_NAME=wordpress
   
   # WordPress installation settings
   WP_SITE_URL=https://your-domain.com
   WP_SITE_TITLE="Your WordPress Site"
   WP_ADMIN_USER=admin
   WP_ADMIN_PASSWORD=$(gcloud secrets versions access latest --secret="WP_ADMIN_PASSWORD")
   WP_ADMIN_EMAIL=$(gcloud secrets versions access latest --secret="WP_ADMIN_EMAIL")
   
   # GitHub Container Registry access
   GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="GITHUB_TOKEN")
   EOF
   
   # Secure the .env file
   chmod 600 /var/www/wp-dev/.env
   ```

5. **Deploy the production stack**:
   ```bash
   cd /var/www/wp-dev
   docker-compose up -d
   ```

6. **Verify deployment**:
   ```bash
   # Check running containers
   docker-compose ps
   
   # Check logs
   docker-compose logs -f
   ```

### Complete DevOps Workflow (From Development to Production)

#### Local Development:
```bash
# Start development environment
sudo -E docker-compose up -d wordpress wp-setup db
```

#### Build Production Image:
```bash
# Build and tag a versioned production image
sudo docker build --target production -t ghcr.io/tortoisewolfe/wp-dev:v0.1.1 .

# Get GitHub token from Google Secret Manager
GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="GITHUB_TOKEN")

# Push to GitHub Container Registry
sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"
sudo -E docker push ghcr.io/tortoisewolfe/wp-dev:v0.1.1
```

#### Test Production Image Locally:
```bash
# IMPORTANT: You MUST run setup-secrets.sh before starting production containers!
source ./setup-secrets.sh

# Run the full production stack with nginx locally
sudo -E docker-compose up -d wordpress-prod wp-prod-setup db nginx
```

#### Deploy to Production Server:
```bash
# On production server:

# 1. Clone repository (first time only)
git clone https://github.com/TortoiseWolfe/wp-dev.git /var/www/wp-dev
cd /var/www/wp-dev

# 2. Pull latest code (for updates)
git pull origin main

# 3. Set up environment with secrets 
# (see step 4 in "DevOps Workflow From Development to Production" above)

# 4. Pull latest image using GitHub token from Google Secret Manager
GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="GITHUB_TOKEN")
sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"
sudo -E docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.1

# 5. Deploy with docker-compose
sudo -E docker-compose up -d

# CRITICAL: ALWAYS use sudo with ALL Docker commands
# Use sudo -E when environment variables need to be preserved
```

- Access the production environment through nginx at http://localhost:80 for HTTP or https://localhost:443 for HTTPS
- For production, configure proper domain names and valid SSL certificates

## IMPORTANT: Changes to Script Files
- Script files are copied into the container during build time
- When you modify scripts in devscripts/ or setup.sh, you MUST rebuild from scratch:
  1. Make changes to scripts
  2. Run `docker-compose down -v` to stop containers and remove volumes
  3. Run `docker image prune -a` to delete all unused images
  4. Run `sudo docker-compose build` to rebuild the image with your changes
  5. Run `sudo -E docker-compose up -d` to start containers with updated image
  6. Complete one-line command: `sudo docker-compose down -v && sudo docker image prune -a -f && sudo docker-compose build && sudo -E docker-compose up -d`
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
- WordPress with BuddyPress and GamiPress using Docker
- Database credentials stored in environment variables
- WordPress configuration managed via wp-config.php
- Plugins installed automatically:
  - BuddyPress: Social networking features
  - GamiPress: Gamification system with achievements, points, and ranks
  - GamiPress-BuddyPress Integration: Connects both systems for social gamification

## Development Roadmap & Best Practices

### Roadmap (2025-2026)

#### Phase 1: Infrastructure and Security 
- [x] Fix script permissions (`chmod +x setup.sh EnhancedBoot/enhanced-boot.sh devscripts/demo-content.sh`)
- [x] Add nginx reverse proxy with SSL termination for production
- [x] Implement versioned image tagging for better deployment management
- [ ] Add specific version pinning for dependencies in Dockerfile
- [ ] Create separate docker-compose.prod.yml for production configuration
- [ ] Consider using Docker secrets for sensitive data instead of environment variables
- [x] Add HTTPS configuration with Let's Encrypt for production via nginx
- [x] Implement basic Apache security hardening (ServerTokens, ServerSignature, TraceEnable)
- [x] Set proper file permissions for WordPress files
- [x] Create automated SSL certificate setup script (get-certificates.sh)
- [x] Document SSL configuration procedure in README
- [ ] Implement additional PHP security configurations
- [ ] Add firewall configuration examples for production servers
- [ ] Add comprehensive security scanning in CI/CD pipeline

#### Phase 2: Performance and Content Improvement
- [ ] **Demo Content Refinement**
  - [ ] Expand tutorial content with more real-world examples
  - [ ] Create specialized curriculum paths for different learning needs
  - [ ] Add interactive code examples
- [ ] **Performance Optimization**
  - [ ] Add Redis or Memcached caching for WordPress
  - [ ] Optimize image handling and database queries
  - [ ] Implement CDN integration for static assets
  - [ ] Reduce Docker image size
- [ ] Document load testing procedures
- [ ] Add caching recommendations for production

#### Phase 3: DevOps & Monitoring
- [x] Document Google Secret Manager workflow for accessing GitHub tokens
- [x] Document workflow from development to production deployment
- [ ] **CI/CD Pipeline**
  - [ ] Create GitHub Actions workflows for automated testing and deployment
  - [ ] Implement blue/green deployments for zero-downtime updates
  - [ ] Document required GitHub secrets for GitHub Actions workflow
- [ ] **Monitoring and Logging**
  - [ ] Add centralized logging with ELK or similar stack
  - [ ] Implement monitoring with Prometheus and Grafana
  - [ ] Create alerting for critical system events
- [ ] Enhance health checks for production containers

#### Phase 4: Scaling & Recovery
- [ ] **Multi-environment Support**
  - [ ] Create staging environment configuration
  - [ ] Document environment-specific configurations
  - [ ] Add proper environment detection in scripts
- [ ] **Backup & Recovery**
  - [ ] Add example scripts for automated backups
  - [ ] Document a complete disaster recovery procedure
  - [ ] Test and document restore procedures
- [ ] **Documentation**
  - [ ] Add environment variable validation in scripts
  - [ ] Document routine maintenance tasks
  - [ ] Add WordPress core and plugin update strategy
  - [ ] Create troubleshooting guide for common issues
  - [ ] Create architecture diagrams

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
- [x] Create automated SSL certificate setup script (get-certificates.sh)
- [x] Document SSL configuration procedure in README 
- [ ] Document WordPress security plugins for production
- [ ] Implement additional PHP security configurations
- [ ] Add firewall configuration examples for production servers
- [ ] Add comprehensive security scanning in CI/CD pipeline

### DevOps & CI/CD
- [x] Document Google Secret Manager workflow for accessing GitHub tokens
- [x] Document workflow from development to production deployment
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
- [x] Document automated environment setup using Google Secret Manager
- [x] Document complete DevOps workflow from development to production
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

### Implementation Approaches

The environment supports two different approaches to gamification:

#### 1. Simple Visual Gamification (Original Implementation)

A lightweight client-side implementation that enhances the learning experience:

- **Visual Progress Tracking**: Progress bar showing completion status (dynamically calculated)
- **Completed Tutorial Indicators**: Visual markers (checkmarks, color changes) for completed tutorials
- **Achievement Badges**: Multiple achievements for different tutorial completions
- **Points System**: Basic points with bonuses for section completion
- **Achievement Tracking**: Both unlocked and locked achievements displayed
- **Implementation Method**: JavaScript and cookie-based tracking

#### 2. GamiPress Integration (Enhanced Implementation)

A more robust plugin-based implementation that offers advanced gamification features:

- **Achievement System**: Configurable achievements based on user actions
- **Points Management**: Multiple point types with automatic tracking
- **Ranks and Levels**: Progressive user ranks based on points and achievements
- **Leaderboards**: Competitive displays of user progress and achievements 
- **Rewards**: Ability to unlock content or features based on achievements
- **BuddyPress Integration**: Activity updates when users earn points or achievements
- **Implementation Method**: WordPress plugin with database storage

### Gamification Features

Both implementations support these core features:

- **Progress Tracking**: Visual indicators of tutorial completion progress
- **Achievement Unlocks**: Special rewards for completing tutorial milestones
- **Points System**: Accumulation of points for completed activities
- **Visual Indicators**: Interface elements showing completion status
- **Continuity**: Progress persists between sessions
- **Tutorial Navigation**: "Continue to Next Tutorial" links for seamless progression

### Implementation Details

The environment automatically installs GamiPress and its BuddyPress integration for all development and production builds, providing a foundation for either implementation approach:

- Simple implementation uses JavaScript and cookies for client-side tracking
- GamiPress implementation uses WordPress database for server-side tracking
- Both implementations can coexist to demonstrate different approaches
- Default tutorial content works with both approaches out of the box

This dual approach allows demonstration of both simple client-side gamification techniques and more complex plugin-based implementations.