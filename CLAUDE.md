# WordPress Development Environment Guidelines

## ATTENTION CLAUDE: CHECK MEMORY LOG FIRST!
When starting a new session, IMMEDIATELY check `/home/jonpohlner/memory_log.txt` to restore context from previous sessions. This helps maintain continuity when sessions are interrupted.

## ✅ ENVIRONMENT VARIABLE SOLUTION IMPLEMENTED ✅
The issue with environment variables not being passed to containers has been fixed by modifying the setup-secrets.sh script to update the .env file with actual secret values. Docker Compose prioritizes .env file over shell environment variables, which was causing the issue.

## ✅ WP-CLI AUTOMATION ISSUES RESOLVED ✅
WP-CLI commands initially failed with "Undefined array key HTTP_HOST" error, but this has been resolved by:
1. Complete removal of all containers and volumes (`docker compose down -v`)
2. Fresh start with clean volumes
3. The issue appears to have been related to corrupted state in the persisted volumes
4. Despite HTTP_HOST warnings, the setup runs successfully with a clean environment

## ⚠️ CRITICAL REQUIREMENT: ALWAYS FOLLOW THIS SEQUENCE ⚠️
1. Run `source ./setup-secrets.sh` first (this now updates .env file automatically)
2. Run `echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe -p $GITHUB_TOKEN` 
3. Run `sudo -E docker-compose up -d [services]` to start containers
4. Always use sudo with Docker commands to avoid permission errors ("Error: kill EPERM")

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
   echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe -p $GITHUB_TOKEN
   sudo -E docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.0
   ```

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

⚠️ **CRITICAL: ALWAYS run setup-secrets.sh before starting containers (especially wordpress-prod)!** ⚠️
If you see "The MYSQL_PASSWORD variable is not set" errors, you forgot this step!

### Testing Production Image
For testing the production image with scripthammer.com domain, ALWAYS use this full sequence:
```bash
# 1. Load secrets first
source ./setup-secrets.sh

# 2. Log in to GitHub Container Registry (CRITICAL STEP - NEVER SKIP)
echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe -p $GITHUB_TOKEN

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
- **ALWAYS** run GitHub Container Registry login `echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe -p $GITHUB_TOKEN` BEFORE image pulls
- Skipping either step will result in authentication errors or empty passwords

### Common Commands:
- `source ./setup-secrets.sh && echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe -p $GITHUB_TOKEN && sudo -E docker-compose up -d`: Start WordPress environment (CORRECT full sequence)
- `sudo docker-compose down`: Stop WordPress environment
- `sudo docker-compose build`: Rebuild Docker images (REQUIRED after script changes)
- `source ./setup-secrets.sh && echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe -p $GITHUB_TOKEN && sudo docker-compose down && sudo docker-compose build && sudo -E docker-compose up -d`: Full rebuild workflow
- `sudo docker-compose exec wordpress wp --allow-root [command]`: Run WP-CLI commands
- `sudo docker-compose exec wordpress bash`: Access WordPress container shell
- `sudo docker-compose exec wordpress /usr/local/bin/devscripts/demo-content.sh`: Populate site with demo content

**CRITICAL: ALWAYS use sudo with Docker commands. Use sudo -E when environment variables need to be preserved. ALWAYS login to GitHub Container Registry AFTER sourcing secrets but BEFORE pulling images.**

## Running Hardened Production Image with Nginx
- Version tagged, security-hardened production images are available in the GitHub Container Registry
- Production environment includes nginx reverse proxy with SSL termination

### ⚠️ TROUBLESHOOTING WP-CLI ISSUES ⚠️
If the WP-CLI setup fails with "Undefined array key HTTP_HOST" or other errors:

1. **Complete Reset Solution**:
   ```bash
   # Stop all containers and remove volumes
   sudo -E docker compose down -v
   
   # Run setup sequence from scratch
   source ./setup-secrets.sh
   echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe -p $GITHUB_TOKEN
   sudo -E docker compose up -d
   ```

2. **Monitor Setup Logs**:
   ```bash
   # Check logs from wp-setup container
   sudo -E docker compose logs wp-setup
   ```

3. **Verify WordPress Installation**:
   ```bash
   # Check if WordPress is installed
   sudo -E docker compose exec wordpress wp core is-installed
   
   # Check BuddyPress components activation
   sudo -E docker compose exec wordpress wp bp component list
   ```

Non-critical HTTP_HOST warnings can be ignored as long as the setup completes successfully.

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
   echo $GITHUB_TOKEN | docker login ghcr.io -u tortoisewolfe --password-stdin
   ```

3. **Pull the hardened production image**:
   ```bash
   docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.0
   ```

4. **Create and configure environment with secrets from Google Secret Manager**:
   ```bash
   # Create directory structure if needed
   mkdir -p /var/www/wp-dev
   
   # Create .env file populated with secrets from Google Secret Manager
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
sudo docker build --target production -t ghcr.io/tortoisewolfe/wp-dev:v0.1.0 .

# Get GitHub token from Google Secret Manager
GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="GITHUB_TOKEN")

# Push to GitHub Container Registry
echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe --password-stdin
sudo -E docker push ghcr.io/tortoisewolfe/wp-dev:v0.1.0
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
echo $GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe --password-stdin
sudo -E docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.0

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