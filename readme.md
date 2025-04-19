# WordPress Development Environment

This repository provides a Docker-based WordPress development environment with BuddyPress installed, supporting both local development and production deployment.

## Development Environment Setup

### Node.js 22

```bash
# Create directory for user-local packages
mkdir -p ~/.npm-global

# Configure npm to use the new directory path
npm config set prefix '~/.npm-global'

# Add npm path to .bashrc
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc

# Apply the changes without logging out and back in
export PATH=~/.npm-global/bin:$PATH

# Install Node.js 22 using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Source nvm without closing the terminal
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js 22
nvm install 22

# Verify installation
node -v
npm -v
```

### Claude Code CLI

```bash
# Install Claude Code (after Node.js is installed)
npm install -g @anthropic-ai/claude-code

# Create Claude Code config directory
mkdir -p ~/.config/claude-code

# Verify Claude Code installation
which claude
```

### Verify Setup

```bash
# Check system and swap configuration
uname -a
free -h
swapon --show

# Check Docker installation
docker --version
systemctl status docker
docker-compose --version

# Check if Node.js is installed
node -v
npm -v
which node

# Check if Claude Code is installed
which claude
```

## Hardened Production Image

The v0.1.1 release includes a security-hardened production image with:
- Nginx reverse proxy with SSL termination
- Apache security hardening
- Proper file permissions
- Docker health checks
- Container-based Let's Encrypt integration

To use the hardened production image:
```bash
# Build the versioned production image locally
docker build --target production -t ghcr.io/tortoisewolfe/wp-dev:v0.1.1 .

# Push to GitHub Container Registry (requires proper token setup)
# 1. Create a GitHub PAT with write:packages and read:packages permissions
# 2. Save token in .env file: GITHUB_TOKEN=your_token_here
# 3. Login with: 
# IMPORTANT: You need to run these commands directly in your terminal, they won't work through Claude Code
echo $GITHUB_TOKEN | docker login ghcr.io -u tortoisewolfe --password-stdin
# 4. Push: docker push ghcr.io/tortoisewolfe/wp-dev:v0.1.1

# Run the complete hardened production stack
docker-compose up -d   # Starts all services including nginx and certbot
```

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

## Directory Structure

The repository is organized as follows:

```
wp-dev/
├── devscripts/         # WordPress content scripts and PHP files
├── docs/               # Documentation files
│   ├── CLAUDE.md       # Claude AI instructions and project documentation
│   └── pull-log.txt    # Log of GitHub pulls
├── nginx/              # Nginx configuration
│   ├── conf/           # Server configuration files
│   └── ssl/            # SSL certificates
├── scripts/            # Shell scripts for setup and maintenance
│   ├── dev/            # Development-specific scripts
│   │   ├── setup-local-dev.sh       # Local development setup
│   │   └── setup-secrets-local.sh   # Local secrets management
│   ├── db/             # Database management scripts
│   ├── prod/           # Production-specific scripts
│   ├── ssl/            # SSL setup and debugging
│   │   ├── ssl-debug.sh   # Debugging SSL issues
│   │   └── ssl-setup.sh   # Setup SSL certificates
│   ├── enhanced-boot.sh   # Enhanced container boot script
│   ├── setup.sh           # Main WordPress setup script
│   └── setup-secrets.sh   # Production secrets management
├── docker-compose.yml  # Docker Compose configuration
├── Dockerfile          # Multi-stage Dockerfile
└── .env                # Environment variables (populated by setup scripts)
```

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/TortoiseWolfe/wp-dev
cd wp-dev
```

### 2. Setting Up SSH Keys

Generate and configure SSH keys for both GitHub repository access and remote development:

```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Start the SSH agent
eval "$(ssh-agent -s)"

# Add the key to the agent (skip passphrase by pressing enter)
ssh-add ~/.ssh/id_ed25519

# Display the public key (add this to your GitHub account)
cat ~/.ssh/id_ed25519.pub

# Test SSH connection to GitHub
ssh -T git@github.com
# You should see: "Hi username! You've successfully authenticated..."

# For GCP VM remote development
# Option A: Using ssh-copy-id
ssh-copy-id -i ~/.ssh/id_ed25519.pub YOUR_USERNAME@YOUR_GCP_EXTERNAL_IP

# Option B: Manual method
cat ~/.ssh/id_ed25519.pub | ssh YOUR_USERNAME@YOUR_GCP_EXTERNAL_IP "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Option C: Via Google Cloud Console - UI steps

# Configure SSH config example
# Host my-gcp-instance
#     HostName YOUR_GCP_EXTERNAL_IP
#     User YOUR_SSH_USERNAME
#     IdentityFile ~/.ssh/id_ed25519
#     IdentitiesOnly yes

# Secure config
chmod 600 ~/.ssh/config
```

```bash
# Copy example environment variables
cp .env.example .env

# For local development (without Google Secret Manager)
source ./scripts/dev/setup-local-dev.sh

# For production (with Google Secret Manager)
source ./scripts/setup-secrets.sh

# Start containers
docker-compose up -d
```

This will:
- Start WordPress at http://localhost:8000 (or your WSL IP address)
- Set up a MySQL database
- Run the setup script to configure WordPress and BuddyPress

## Development Workflow

### WSL Development Notes

When developing using Windows Subsystem for Linux (WSL), note that:

1. **Accessing WordPress**: The WordPress site won't be accessible via `localhost` from Windows browsers
2. **Use WSL IP Address**: Use the IP address of your WSL instance instead:
   ```
   http://<WSL-IP-ADDRESS>:8000
   ```
3. **Finding WSL IP**: Run `hostname -I` in your WSL terminal to get the IP address
4. **Automatic Detection**: The setup script automatically detects WSL and displays the correct URL

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

```bash
docker-compose exec wordpress wp --allow-root plugin list
```

```bash
docker-compose exec wordpress /usr/local/bin/devscripts/demo-content.sh
```

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

The GitHub token is stored in Google Secret Manager and accessed via the setup-secrets.sh script. If you need to update the token:

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Generate a new token named "Container Registry Access" (90 day expiration)
3. Repository access: "Only select repositories" → select wp-dev repository
4. Permissions: Set "Packages" to "Read" (this permission is CRITICAL)
5. **IMPORTANT**: Copy the token immediately after generation
6. Update in Google Secret Manager:

```bash
# Update token in Google Secret Manager
echo -n "your_new_token" | gcloud secrets versions add GITHUB_TOKEN --data-file=-
```

### Docker Image Authentication Workflow

To properly authenticate and pull images, ALWAYS follow this exact sequence:

```bash
# 1. Verify Secret Manager access (secrets should already exist)
gcloud secrets list --project=scripthammer

# 2. Source secrets script to get token from Google Secret Manager
source ./scripts/setup-secrets.sh

# 3. Login to GitHub Container Registry with the token
# CRITICAL: This step must be run EVERY TIME before pulling images
sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"

# 4. Pull the production image
sudo -E docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.1

# 5. Start the database first, then other containers
sudo -E docker-compose up -d db

# 6. Wait for database to initialize (important for reliability)
sleep 30  # Wait 30 seconds for database to fully initialize

# 7. Start the remaining containers
sudo -E docker-compose up -d wordpress-prod wp-prod-setup nginx certbot

# 8. Set up SSL certificates
# The SSL setup script automatically locates your .env file at the repository root.
# For detailed logs or debugging, run with Bash debugging and tee:
sudo bash -x scripts/ssl/ssl-setup.sh | tee ssl-setup-$(date +%Y%m%d-%H%M%S).log

# 9. (Optional) Restart Nginx to apply certificates (the script restarts Nginx by default):
sudo docker-compose restart nginx
```

⚠️ **IMPORTANT**: Skipping any of these steps will result in authentication errors!

### Production Server Deployment

Follow this exact sequence for a reliable production deployment:

```bash
# First-time setup
git clone git@github.com:TortoiseWolfe/wp-dev.git /var/www/wp-dev
cd /var/www/wp-dev

# OR update existing deployment
git fetch origin && git checkout main && git pull origin main

# Configure environment
cp .env.example .env && nano .env  # Edit with production values

# 1. Verify Secret Manager access (secrets should already exist)
gcloud secrets list --project=scripthammer

# 2. Source secrets script to get token from Google Secret Manager
source ./scripts/setup-secrets.sh

# 3. Login to GitHub Container Registry with the token
sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"

# 4. Pull the production image
sudo -E docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.1

# 5. Start the database first, then other containers
sudo -E docker-compose up -d db

# 6. Wait for database to initialize (important for reliability)
echo "Waiting 30 seconds for database to initialize..."
sleep 30

# 7. Start the remaining containers
sudo -E docker-compose up -d wordpress-prod wp-prod-setup nginx certbot

# 8. Verify all containers are running
sudo docker-compose ps

# 9. Set up SSL certificates
# The SSL setup script automatically locates your .env file at the repository root.
# You can capture detailed logs for future reference:
sudo bash -x scripts/ssl/ssl-setup.sh | tee ssl-setup-$(date +%Y%m%d-%H%M%S).log

# 10. (Optional) Restart Nginx to apply certificates (the script restarts Nginx by default):
sudo docker-compose restart nginx

# 11. Verify installation
sudo -E docker-compose exec wordpress-prod wp core is-installed --allow-root
sudo -E docker-compose exec wordpress-prod wp plugin status buddypress --allow-root
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
GHCR_IMAGE="ghcr.io/tortoisewolfe/wp-dev:v0.1.1"  # Production image with versioned tag
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
# IMPORTANT: You need to run these commands directly in your terminal, they won't work through Claude Code
echo "$GITHUB_TOKEN" | docker login ghcr.io -u tortoisewolfe --password-stdin

# Step 4: Pull the latest production image from GHCR
log "Pulling the latest image ${GHCR_IMAGE}..."
docker pull "${GHCR_IMAGE}"

# Step 5: Deploy the complete hardened production stack
log "Updating production services using Docker Compose..."
docker-compose -f "$DOCKER_COMPOSE_FILE" pull
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d  # Deploy all services including nginx and certbot

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

1. Build and push a new versioned image (from your local development machine):
```bash
# ON YOUR LOCAL MACHINE
# Update your code, then build and push a new versioned image
# IMPORTANT: Always use specific version tags, not 'latest'
docker build --target production -t ghcr.io/tortoisewolfe/wp-dev:v0.1.1 .
docker push ghcr.io/tortoisewolfe/wp-dev:v0.1.1
```

2. On the production server, either:
```bash
# ON YOUR PRODUCTION SERVER
# Option 1: Run the deployment script (make sure to update version in the script first)
./deploy-prod.sh

# Option 2: Or manually pull and restart with the versioned image
cd /var/www/wp-dev
git pull  # Update docker-compose.yml and scripts if needed

# Update the image version in docker-compose.yml:
# image: ghcr.io/tortoisewolfe/wp-dev:v0.1.1

docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.1
docker-compose down    # Stop all services
docker-compose up -d   # Start all services with the updated image
```

```bash
# ON YOUR PRODUCTION SERVER
# Database backup
docker-compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > backup-$(date +%Y%m%d).sql

# WordPress files backup
docker-compose exec wordpress-prod tar -czf /tmp/wp-content-backup-$(date +%Y%m%d).tar.gz /var/www/html/wp-content
docker cp wp-dev_wordpress-prod_1:/tmp/wp-content-backup-$(date +%Y%m%d).tar.gz ./wp-content-backup-$(date +%Y%m%d).tar.gz
```

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
- Retrieves secrets from Google Secret Manager
- Creates logs at `/tmp/enhanced-boot.log`

#### Google Secret Manager Setup

For the script to access secrets from Google Secret Manager:

1. **Set up Google Cloud SDK and authenticate**:
```bash
# Install Google Cloud SDK if not already installed
# Visit: https://cloud.google.com/sdk/docs/install for instructions

# Authenticate with Google Cloud
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

2. **Create the necessary secrets in Google Secret Manager**:
```bash
# Create secrets (run these commands from a machine with gcloud installed)
gcloud secrets create MYSQL_ROOT_PASSWORD --replication-policy="automatic"
gcloud secrets create MYSQL_PASSWORD --replication-policy="automatic"
gcloud secrets create WP_ADMIN_PASSWORD --replication-policy="automatic"
gcloud secrets create WP_ADMIN_EMAIL --replication-policy="automatic"
gcloud secrets create GITHUB_TOKEN --replication-policy="automatic"

# Add secret values
echo -n "your-secure-root-password" | gcloud secrets versions add MYSQL_ROOT_PASSWORD --data-file=-
echo -n "your-secure-db-password" | gcloud secrets versions add MYSQL_PASSWORD --data-file=-
echo -n "your-secure-admin-password" | gcloud secrets versions add WP_ADMIN_PASSWORD --data-file=-
echo -n "admin@yourdomain.com" | gcloud secrets versions add WP_ADMIN_EMAIL --data-file=-
echo -n "ghp_your_github_token" | gcloud secrets versions add GITHUB_TOKEN --data-file=-
```

3. **Access secrets from Google Secret Manager**:
```bash
# List available secrets
gcloud secrets list

# Access a specific secret
gcloud secrets versions access latest --secret="GITHUB_TOKEN"

# Use the GitHub token to authenticate with GitHub
GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="GITHUB_TOKEN")
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Clone the repository using the token
git clone https://github.com/TortoiseWolfe/wp-dev.git
```

2. **Grant VM access to Secret Manager**:
   
   **Option A: When creating a new VM**:
```bash
# Create VM with Secret Manager access
gcloud compute instances create wordpress-vm \
  --service-account=YOUR_SERVICE_ACCOUNT_EMAIL \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```

   **Option B: For existing VM**:
```bash
# Set permissions on Google Cloud Console
# 1. Go to: IAM & Admin > Service Accounts
# 2. Find your VM's service account (or create a new one)
# 3. Grant it the 'Secret Manager Secret Accessor' role

# Then attach this service account to your VM:
gcloud compute instances set-service-account wordpress-vm \
  --service-account=YOUR_SERVICE_ACCOUNT_EMAIL \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```

3. **Verify Permissions**: Test secret access before running the full script
```bash
# SSH into your VM and verify access
gcloud auth login
gcloud config set project YOUR_PROJECT
gcloud secrets versions access latest --secret="MYSQL_ROOT_PASSWORD"
```

#### Environment Configuration for Production

The script creates a `.env` file in `/var/www/wp-dev/` populated with values from Secret Manager. If needed, you can manually configure it:

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

## Troubleshooting

### Common Container Issues

```bash
# Container issues
sudo docker-compose down -v && sudo docker-compose up -d

# Database errors
sudo docker-compose logs db

# Docker permission denied
sudo usermod -aG docker $USER && newgrp docker
```

### GitHub Authentication Errors

If you see `Error: Head: unauthorized` or similar:

```bash
# Always use this full sequence - order matters!
source ./scripts/setup-secrets.sh
sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN" 
sudo -E docker pull ghcr.io/tortoisewolfe/wp-dev:v0.1.1
```

### WordPress Setup Issues

If WordPress setup fails:

```bash
# Check logs
sudo docker-compose logs wordpress-prod

# Verify database connection
sudo -E docker-compose exec wordpress-prod wp db check --allow-root

# Manually trigger setup
sudo -E docker-compose exec wordpress-prod /usr/local/bin/scripts/setup.sh
```

### Other Common Issues
- **GitHub Registry access denied**: Authenticate with token from [GitHub Token section](#github-token-for-pulling-images)
- **Docker installation issues**: Check logs at `/tmp/enhanced-boot.log`
- **Installation always seems to fail**: Try starting database first, waiting 30 seconds, then starting other containers

## SSL Configuration

To set up SSL with Let's Encrypt for your WordPress site:

1. **Prerequisites:**
   - A domain name pointing to your server's IP address (DNS A record)
   - Port 80 and 443 open on your firewall

2. **Configuration Steps:**
   - Update your `.env` file with:
     ```
     WP_SITE_URL=https://yourdomain.com
     DOMAIN_NAME=yourdomain.com
     CERTBOT_EMAIL=your.email@example.com
     ```

3. **Certificate Generation:**
   ```bash
   # From the project root, run the SSL setup script
   sudo bash -x scripts/ssl/ssl-setup.sh | tee ssl-setup-$(date +%Y%m%d-%H%M%S).log
   ```

   # Note:
   # - The script auto-detects the .env file in the repository root.
   # - Detailed logs are written to /tmp/ssl-setup-*.log by default.
   # - If Let's Encrypt rate limits are reached, it will fall back to a self-signed certificate.
   # - For repeated end-to-end testing without hitting production rate limits, you can enable staging mode:
   #     export STAGING=1
   #     sudo bash -x scripts/ssl/ssl-setup.sh | tee ssl-setup-staging-$(date +%Y%m%d-%H%M%S).log
   #   These certs are signed by the Let's Encrypt staging CA and not trusted by browsers but allow full workflow testing.

   The script automatically:
   - Configures Nginx with HTTPS support
   - Creates temporary self-signed certificates
   - Obtains official Let's Encrypt certificates
   - Sets up automatic certificate renewal (every 12 hours)

4. **Verify SSL Configuration:**
   ```bash
   # Check if certificates were generated
   sudo -E docker-compose exec certbot certbot certificates

   # Test HTTPS connection
   curl -I https://yourdomain.com
   ```

5. **Troubleshooting:**
   - If certificate generation fails, check:
     - That your domain resolves to your server (dig yourdomain.com)
     - That ports 80/443 are accessible from the internet
     - Certbot logs: `sudo -E docker-compose logs certbot`


## Additional Resources

- [WordPress Codex](https://codex.wordpress.org/)
- [BuddyPress Documentation](https://codex.buddypress.org/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)