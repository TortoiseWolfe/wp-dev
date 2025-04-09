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

Generate and configure an SSH key for repository access:

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub  # Copy this to GitHub → Settings → SSH keys
ssh -T git@github.com      # Verify connection
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

This will populate the site with sample users, posts, BuddyPress content, and messages.

### Modifying Script Files

When modifying scripts in `devscripts/` or `setup.sh`, you MUST rebuild from scratch:

```bash
docker-compose down -v && docker image prune -a -f && docker-compose build && docker-compose up -d
```

## Production Deployment

### Automated CI/CD Deployment 

This repository is configured with GitHub Actions to automatically build and publish Docker images to GitHub Container Registry whenever:
- You push to the `main` branch
- You create a new tag (`v*.*.*`)

### Complete Deployment Workflow

1. **On your local machine**:
   - Make your changes and push to main
   ```bash
   git add .
   git commit -m "Your meaningful commit message"
   git push origin main
   ```
   - GitHub Actions automatically builds and pushes the Docker image
   - Monitor the build in the "Actions" tab of your GitHub repository

2. **On your production server**:
   - Pull the image and deploy it (see "Production Server Deployment" below)

### Testing Production Setup Locally

Before deploying to production, verify that the production setup works correctly on your local machine:

```bash
# On your LOCAL MACHINE
# Run both development and production environments locally
docker-compose up -d

# Access dev site at http://localhost:8000
# Access production site at http://localhost:80
```

### GitHub Token for Pulling Images

Create a GitHub Personal Access Token for accessing the Container Registry:

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Generate a new token named "Container Registry Access" (90 day expiration)
3. Repository access: "Only select repositories" → select wp-dev repository
4. Permissions: Set "Packages" to "Read"
5. **IMPORTANT**: Copy the token immediately after generation

Add the token to your production server:

```bash
# Add to .env file (recommended)
nano /var/www/wp-dev/.env
GITHUB_TOKEN=ghp_your_personal_access_token_here

# Secure the file
chmod 600 /var/www/wp-dev/.env
```

### Production Server Deployment

Deploy to production after GitHub Actions builds the image:

```bash
# First-time setup
git clone https://github.com/TortoiseWolfe/wp-dev.git /var/www/wp-dev
cd /var/www/wp-dev

# OR update existing deployment
git fetch origin && git checkout main && git pull origin main

# Configure environment
cp .env.example .env && nano .env  # Edit with production values

# Deploy containers
echo $GITHUB_TOKEN | docker login ghcr.io -u tortoisewolfe --password-stdin
docker pull ghcr.io/tortoisewolfe/buddypress-allyship:latest
docker-compose up -d wordpress-prod wp-prod-setup db
docker-compose ps  # Verify status
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

# Step 3: Get GitHub token from .env file or environment
# Load from .env file
if [ -f "${PROJECT_DIR}/.env" ]; then
    log "Loading GitHub token from .env file..."
    GITHUB_TOKEN=$(grep GITHUB_TOKEN "${PROJECT_DIR}/.env" | cut -d= -f2)
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set."
    echo "Please add your GitHub token to your .env file:"
    echo "GITHUB_TOKEN=your_personal_access_token"
    echo "Or export it in your environment: export GITHUB_TOKEN=your_token"
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

# Restore files
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

Use versioned tags for better rollback capability:

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

### Setting Up VS Code with Remote SSH for GCP

This guide walks you through connecting VS Code to a GCP Linux VM for seamless remote development.

#### 1. Install Required Software

- Download and install [VS Code](https://code.visualstudio.com/)
- Install the **Remote - SSH** extension (or full Remote Development pack) via the Extensions sidebar (`Ctrl+Shift+X`)

#### 2. Prepare SSH Key

If you don't have an SSH key for GCP:

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

#### 3. Configure SSH Access

Create/edit `~/.ssh/config`:

```ssh-config
Host my-gcp-instance
    HostName YOUR_GCP_EXTERNAL_IP
    User YOUR_SSH_USERNAME
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

- Replace placeholders with your GCP instance IP and username
- Secure your config with `chmod 600 ~/.ssh/config`

#### 4. Connect VS Code to GCP

1. Press `F1` (or `Ctrl+Shift+P`) and select **Remote-SSH: Connect to Host**
2. Choose your configured host (`my-gcp-instance`)
3. Select the appropriate Linux distribution if prompted
4. Wait for VS Code server installation on the remote host

#### 5. Work with Remote Files

- Use File Explorer to navigate to your project folder on GCP
- Edit files directly on the remote system
- Use the integrated terminal (`` Ctrl+` ``) to run commands on the GCP instance

#### 6. Managing Your Connection

- **Disconnect**: Close the VS Code window
- **Reconnect**: Use the Remote-SSH command again

### Server Preparation with EnhancedBoot

Use this bootstrap script for new production servers:

```bash
# Copy and run the script
scp EnhancedBoot/enhanced-boot.sh user@server:/tmp/
ssh user@server
sudo bash /tmp/enhanced-boot.sh
```

The script automatically:
- Updates system packages
- Installs Docker with security settings
- Configures swap space
- Sets up WordPress environment
- Creates logs at `/tmp/enhanced-boot.log`

#### Environment Configuration for Production

The script creates a default `.env` file in `/var/www/wp-dev/`. Configure it:

```bash
# Edit environment variables
sudo nano /var/www/wp-dev/.env

# Load variables in your session
source /var/www/wp-dev/.env

# Launch with environment variables
docker-compose --env-file /var/www/wp-dev/.env up -d

# In automation scripts
if [ -f "/var/www/wp-dev/.env" ]; then
    source /var/www/wp-dev/.env
fi
```

Always update passwords, credentials, and site URL before deployment.

### Security Considerations

The production environment includes:
- **Container security**: Minimal packages, proper permissions, non-root operation
- **Server security**: Automated updates, controlled Docker installation, error handling
- **Recommended additions**: UFW firewall, SSH hardening, password policies

#### Security Monitoring Commands

Key commands for monitoring server security:

```bash
# Check login activity
sudo grep "Accepted" /var/log/auth.log | awk '{print $9,$11}' | sort | uniq -c | sort -nr  # Successful logins
sudo grep "Failed password" /var/log/auth.log | awk '{print $9,$11}' | sort | uniq -c | sort -nr  # Failed attempts
who  # Current logged-in users
last | head -20  # Recent login history

# Comprehensive security summary
echo "=== SECURITY LOGIN SUMMARY ===" && \
echo "Total successful logins: $(sudo grep "Accepted" /var/log/auth.log | wc -l)" && \
echo "Total failed attempts: $(sudo grep "Failed password" /var/log/auth.log | wc -l)" && \
echo -e "\nTop 5 successful logins by user/IP:" && \
sudo grep "Accepted" /var/log/auth.log | awk '{print $9,$11}' | sort | uniq -c | sort -nr | head -5 && \
echo -e "\nTop 5 failed logins by user/IP:" && \
sudo grep "Failed password" /var/log/auth.log | awk '{print $9,$11}' | sort | uniq -c | sort -nr | head -5
```

## Git Workflow

```bash
# Create feature branch
git checkout main && git pull
git checkout -b feature/your-feature-name

# Make changes and commit
git add .
git commit -m "Descriptive commit message"
git push -u origin feature/your-feature-name

# After PR approval and merge
git checkout main && git pull
git branch -d feature/your-feature-name
```

For PRs:
1. GitHub → Pull Requests → New Pull Request
2. Select your branch → main
3. Include: description, testing instructions, screenshots
4. Request reviews

## Troubleshooting

- **Container issues**: `docker-compose down -v && docker-compose up -d`
- **Database errors**: 
  - Verify passwords match in .env
  - Check logs: `docker-compose logs db`
- **WordPress errors**: Examine setup.sh and `docker logs [container-id]`
- **Docker permission denied**: 
  ```bash
  sudo usermod -aG docker $USER && newgrp docker
  ```
- **GitHub Registry access denied**: Authenticate with token from [GitHub Token section](#github-token-for-pulling-images)
- **Docker installation issues**: Check logs at `/tmp/enhanced-boot.log`

## Additional Resources

- [WordPress Codex](https://codex.wordpress.org/)
- [BuddyPress Documentation](https://codex.buddypress.org/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)