# WordPress Development Environment

This repository provides a Docker-based WordPress development environment with BuddyPress installed, supporting both local development and production deployment.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- Git
- SSH key for repository access
- GitHub account (for using GitHub Container Registry)

## Table of Contents

- [Initial Setup](#initial-setup)
- [Development Workflow](#development-workflow)
- [Production Deployment](#production-deployment)
- [Server Setup](#server-setup)
- [Git Workflow](#git-workflow)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/TortoiseWolfe/wp-dev
cd wp-dev
```

### 2. Setting Up SSH Keys

To access the repository:

1. Generate an Ed25519 SSH key (GitHub's current security best practice):
   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   ```

2. Start the ssh-agent in the background and add your key:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. Add the SSH key to your GitHub account:
   - Copy your public key:
     ```bash
     cat ~/.ssh/id_ed25519.pub
     ```
   - Go to GitHub → Settings → SSH and GPG keys → New SSH key
   - Paste your key and save

4. Verify your connection:
   ```bash
   ssh -T git@github.com
   ```

### 3. Configure Environment Variables

```bash
cp .env.example .env
```

Edit the `.env` file to customize:
- Database credentials
- WordPress admin account
- Site URL and title

### 4. Start the Development Environment

```bash
docker-compose up -d
```

This will:
- Start WordPress at http://localhost:8000
- Set up a MySQL database
- Run the setup script to configure WordPress and BuddyPress

## Development Workflow

### Running the Environment

- Start: `docker-compose up -d`
- Stop: `docker-compose down`
- View logs: `docker-compose logs -f`

### Accessing WordPress

- Admin Dashboard: http://localhost:8000/wp-admin/
  - Default username: `admin`
  - Default password: See docker-compose.yml for WORDPRESS_ADMIN_PASSWORD

### Executing WP-CLI Commands

```bash
docker-compose exec wordpress wp --allow-root [command]
```

Example:
```bash
docker-compose exec wordpress wp --allow-root plugin list
```

### Populating Demo Content

To add example users, posts, comments, pages, and BuddyPress content:

```bash
docker-compose exec wordpress /usr/local/bin/devscripts/demo-content.sh
```

**Important Note**: The script must be run from inside the container using the path above. It will not work if you try to run it directly from your host machine.

This will create:
- 20 example users with Latin names
- 20 sample posts with comments and replies
- 5 BuddyPress groups with members and activities (if BuddyPress is active)
- 5 sample pages with philosophical content
- Example messages to admin (if BuddyPress Messages is active)

### Modifying Script Files

When modifying scripts in `devscripts/` or `setup.sh`, you MUST rebuild from scratch:

```bash
docker-compose down -v && docker image prune -a -f && docker-compose build && docker-compose up -d
```

## Production Deployment

### Complete Deployment Workflow Overview

The deployment process involves two main environments:
1. **Local Development Machine**: Where you develop, test, and build the Docker image
2. **Production Server**: Where your WordPress site will be publicly hosted

Here's the complete workflow:
1. On your **local machine**: Build and test the application
2. On your **local machine**: Build and push the production Docker image to GitHub Container Registry
3. On your **production server**: Clone the repository and configure the environment
4. On your **production server**: Pull the image and launch the production services

### Building and Testing Locally

Before deploying to production, you should verify that the production setup works correctly on your local machine:

```bash
# On your LOCAL MACHINE
# Run both development and production environments locally
docker-compose up -d

# Access dev site at http://localhost:8000
# Access production site at http://localhost:80
```

### GitHub Personal Access Token Setup

Before deploying to production, you need to create a GitHub Personal Access Token for accessing the Container Registry:

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Click "Generate new token"
3. Give it a descriptive name like "Container Registry Access"
4. Set an expiration date (recommend 90 days)
5. Under Repository access, select "Only select repositories" and choose your wp-dev repository
6. Under Permissions → Repository permissions:
   - Find "Packages" and set to "Read and write"
7. Click "Generate token"
8. **IMPORTANT**: Copy the token immediately (you won't be able to see it again)

You'll need to set up this token on both your local machine and production server:

#### On your local machine (choose one method):

```bash
# Method 1: Set token for current session only
export GITHUB_TOKEN=ghp_your_personal_access_token_here

# Method 2: Add to your shell profile for persistence
echo 'export GITHUB_TOKEN=ghp_your_personal_access_token_here' >> ~/.bashrc
source ~/.bashrc
```

#### On your production server (choose one method):

```bash
# Method 1: Set token for current session only
export GITHUB_TOKEN=ghp_your_personal_access_token_here

# Method 2: Save to a secure environment file
echo 'export GITHUB_TOKEN=ghp_your_personal_access_token_here' > /var/www/wp-dev/.env.deploy
chmod 600 /var/www/wp-dev/.env.deploy  # Restrict permissions for security

# Then in your deploy script, add:
if [ -f /var/www/wp-dev/.env.deploy ]; then
    source /var/www/wp-dev/.env.deploy
fi
```

### Production Deployment Steps

#### 1. Build and Push Production Image (On Local Machine)

These steps are performed on your local development machine:

```bash
# ON YOUR LOCAL MACHINE
# Navigate to your project directory
cd /path/to/your/wp-dev

# Make sure you have set up your GitHub token (see above)
# Then authenticate with GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u tortoisewolfe --password-stdin

# Build the Docker image targeting the production stage
docker build --target production -t ghcr.io/tortoisewolfe/buddypress-allyship:latest .

# Push the image to GitHub Container Registry
docker push ghcr.io/tortoisewolfe/buddypress-allyship:latest
```

#### 2. Server Setup and Deployment (On Production Server)

These steps are performed on your production server:

```bash
# ON YOUR PRODUCTION SERVER
# Clone the repository (if this is the first deployment)
git clone https://github.com/TortoiseWolfe/wp-dev.git /var/www/wp-dev
cd /var/www/wp-dev

# If already cloned, update to the latest version
git fetch origin
git checkout main
git pull origin main

# Create and configure the .env file for production
cp .env.example .env
nano .env  # Edit with production values

# Make sure you have set up your GitHub token (see above)
# Then authenticate with GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u tortoisewolfe --password-stdin

# Pull the latest production image 
docker pull ghcr.io/tortoisewolfe/buddypress-allyship:latest

# Launch production services using Docker Compose
docker-compose up -d wordpress-prod wp-prod-setup db

# Verify everything is running correctly
docker-compose ps
```

### Automated Deployment Script (For Production Server)

For a more streamlined deployment process, you can use this deployment script (`deploy-prod.sh`) on your production server:

```bash
#!/bin/bash
# deploy-prod.sh - PLACE THIS ON YOUR PRODUCTION SERVER
#
# Production Deployment Script for wp-dev

set -e  # Exit immediately if a command fails
set -o pipefail

# ----------------------
# CONFIGURATION
# ----------------------
PROJECT_DIR="/var/www/wp-dev"                           # Path to your project
BRANCH="main"                                           # Branch to deploy
GHCR_IMAGE="ghcr.io/tortoisewolfe/buddypress-allyship:latest"  # Production image
DOCKER_COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml" # Docker Compose file path

# ----------------------
# FUNCTIONS
# ----------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ----------------------
# DEPLOYMENT STEPS
# ----------------------
log "Starting production deployment of wp-dev..."

# Step 1: Navigate to the project directory
cd "$PROJECT_DIR" || { echo "Error: Project directory not found at $PROJECT_DIR"; exit 1; }

# Step 2: Update the codebase from the Git repository
log "Updating codebase from Git (branch: ${BRANCH})..."
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

# Step 3: Authenticate with GitHub Container Registry
if [ -f /var/www/wp-dev/.env.deploy ]; then
    log "Loading GitHub token from .env.deploy file..."
    source /var/www/wp-dev/.env.deploy
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set in the environment."
    echo "Please set it up using one of these methods:"
    echo "1. export GITHUB_TOKEN=your_token"
    echo "2. Create a /var/www/wp-dev/.env.deploy file with: export GITHUB_TOKEN=your_token"
    exit 1
fi

log "Authenticating with GitHub Container Registry..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u tortoisewolfe --password-stdin

# Step 4: Pull the latest production image from GHCR
log "Pulling the latest image ${GHCR_IMAGE}..."
docker pull "${GHCR_IMAGE}"

# Step 5: Deploy services using Docker Compose
log "Updating production services using Docker Compose..."
docker-compose -f "$DOCKER_COMPOSE_FILE" pull
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d wordpress-prod wp-prod-setup db

# Step 6: Verify deployment status
log "Deployment complete. Verifying running containers..."
docker-compose -f "$DOCKER_COMPOSE_FILE" ps

log "Production deployment finished successfully."
```

To use this script:
1. Upload it to your production server in `/var/www/wp-dev`
2. Make it executable: `chmod +x deploy-prod.sh`
3. Run it: `./deploy-prod.sh`

### Upgrade Procedure

To upgrade your production environment:

1. Build and push a new image (from your local development machine):
   ```bash
   # ON YOUR LOCAL MACHINE
   # Update your code, then build and push a new image
   docker build --target production -t ghcr.io/tortoisewolfe/buddypress-allyship:latest .
   docker push ghcr.io/tortoisewolfe/buddypress-allyship:latest
   ```

2. On the production server, either:
   ```bash
   # ON YOUR PRODUCTION SERVER
   # Option 1: Run the deployment script
   ./deploy-prod.sh
   
   # Option 2: Or manually pull and restart
   cd /var/www/wp-dev
   git pull  # Update docker-compose.yml and scripts if needed
   docker pull ghcr.io/tortoisewolfe/buddypress-allyship:latest
   docker-compose down wordpress-prod wp-prod-setup
   docker-compose up -d wordpress-prod wp-prod-setup
   ```

For major updates that require data migration, always create a backup first (see [Backup Strategy](#backup-strategy)).

### Backup Strategy

Always backup before upgrading:

```bash
# ON YOUR PRODUCTION SERVER
# Database backup
docker-compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > backup-$(date +%Y%m%d).sql

# WordPress files backup
docker-compose exec wordpress-prod tar -czf /tmp/wp-content-backup-$(date +%Y%m%d).tar.gz /var/www/html/wp-content
docker cp wp-dev_wordpress-prod_1:/tmp/wp-content-backup-$(date +%Y%m%d).tar.gz ./wp-content-backup-$(date +%Y%m%d).tar.gz
```

To restore from backup:

```bash
# ON YOUR PRODUCTION SERVER
# Restore database
cat backup-20250408.sql | docker-compose exec -T db mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}

# Restore files (if needed)
docker cp ./wp-content-backup-20250408.tar.gz wp-dev_wordpress-prod_1:/tmp/
docker-compose exec wordpress-prod bash -c "cd / && tar -xzf /tmp/wp-content-backup-20250408.tar.gz"
```

### Important Production Environment Variables

```bash
# ON YOUR PRODUCTION SERVER
# Edit these in your production .env file
WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_USER=your_db_user                # Use a strong username
WORDPRESS_DB_PASSWORD=strong_unique_password  # Use a very strong password
WORDPRESS_DB_NAME=your_db_name
WP_SITE_URL=https://your-domain.com           # Use your actual domain with https
WP_SITE_TITLE=Your Site Title
WP_ADMIN_USER=admin_username                  # Use a non-default admin username
WP_ADMIN_PASSWORD=strong_admin_password       # Use a very strong password
WP_ADMIN_EMAIL=admin@your-domain.com          # Use your domain email
```

### Version Control for Production

For better control and rollback capability, use versioned tags:

```bash
# ON YOUR LOCAL MACHINE
# Tag a specific version
docker build --target production -t ghcr.io/tortoisewolfe/buddypress-allyship:v1.2.3 .
docker push ghcr.io/tortoisewolfe/buddypress-allyship:v1.2.3

# ON YOUR PRODUCTION SERVER
# Use a specific version
docker pull ghcr.io/tortoisewolfe/buddypress-allyship:v1.2.3
# Update docker-compose.yml to use the specific version:
# image: ghcr.io/tortoisewolfe/buddypress-allyship:v1.2.3
```

## Server Setup

### Server Preparation with EnhancedBoot

For production environments, use the comprehensive server bootstrap script to:
- Update system packages with robust retry mechanisms
- Install and configure Docker with proper security settings
- Configure swap space for better performance
- Add security hardening measures
- Prepare optimal WordPress environment settings

To use the script on a new server:

```bash
# Copy the script to the server
scp EnhancedBoot/enhanced-boot.sh user@server:/tmp/

# Connect to the server and run the script
ssh user@server
sudo bash /tmp/enhanced-boot.sh
```

The script creates detailed logs at `/tmp/enhanced-boot.log` for troubleshooting.

### Security Considerations

The production image includes:
- Minimal installed packages
- Proper file permissions
- Non-root user operation
- Apache security configuration
- Health checks

The EnhancedBoot script provides additional server-level security:
- Package update and management system
- Controlled Docker installation procedure
- Robust error handling and logging
- Swap space configuration for performance
- Server timezone and environment configuration

Additional security measures to implement:
- UFW firewall configuration
- SSH hardening
- Password policies
- Regular security updates

## Git Workflow

### Branching Strategy

1. Always create feature branches from main:
   ```bash
   git checkout main
   git pull
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "Descriptive commit message"
   ```

3. Push your branch to remote:
   ```bash
   git push -u origin feature/your-feature-name
   ```

### Creating Pull Requests

1. Go to the repository on GitHub
2. Click "Pull Requests" → "New Pull Request"
3. Select your branch and the target branch (main)
4. Fill in the PR template with:
   - Description of changes
   - Testing instructions
   - Screenshots (if applicable)
5. Request reviews from team members

### Reviewing and Merging

1. Address any feedback from reviewers
2. Once approved, merge the PR on GitHub
3. Delete the feature branch after merging:
   ```bash
   git checkout main
   git pull
   git branch -d feature/your-feature-name
   ```

## Troubleshooting

- **Container issues**: Try `docker-compose down -v` followed by `docker-compose up -d`
- **Database connection errors**: 
  - Check that MYSQL_PASSWORD and WORDPRESS_DB_PASSWORD match in the .env file
  - Verify all environment variables are properly set in docker-compose.yml
  - Check logs with `docker-compose logs db` and `docker-compose logs wordpress`
- **WordPress configuration**: Examine setup.sh for the installation process
- **Missing plugins or themes**: Check logs with `docker logs [container-id]`
- **Performance issues**: Consider implementing a caching solution
- **Docker installation problems**: Check detailed logs at `/tmp/enhanced-boot.log`
- **"Access denied for user" errors**: Ensure that password values match between MySQL and WordPress settings
- **Docker permission denied errors**:
  - Error: `permission denied while trying to connect to the Docker daemon socket`
  - Solution: Either use `sudo` with Docker commands or add your user to the docker group:
    ```bash
    sudo usermod -aG docker $USER && newgrp docker
    ```
- **GitHub Container Registry access denied**:
  - Error: `denied: denied` when pulling images
  - Solution: Authenticate with a personal access token as described in the [GitHub Container Registry section](#1-github-container-registry-automated)

## Additional Resources

- [WordPress Codex](https://codex.wordpress.org/)
- [BuddyPress Documentation](https://codex.buddypress.org/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)