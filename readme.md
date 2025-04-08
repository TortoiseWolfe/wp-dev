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

### Complete Deployment Workflow

1. **Local Development**: Develop and test features locally using development environment
2. **Test Production Locally**: Verify production setup works correctly
3. **Build & Push Production Image**: Build and push the image to GitHub Container Registry
4. **Server Preparation**: Set up production server with EnhancedBoot script
5. **Deploy to Production**: Set up docker-compose and pull the image from GHCR

### Testing Production Setup Locally

The docker-compose.yml file already contains a production section with a wordpress-prod service:

```bash
# Run both development and production environments locally
docker-compose up -d

# Access dev site at http://localhost:8000
# Access production site at http://[Your-IP]:80
```

### Production Deployment Steps

#### 1. Build and Push Production Image to GitHub Container Registry

1. Authenticate with GitHub Container Registry:
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

2. Build and tag the production image:
   ```bash
   docker build --target production -t ghcr.io/tortoisewolfe/buddypress-allyship:latest .
   ```

3. Push the image to GitHub Container Registry:
   ```bash
   docker push ghcr.io/tortoisewolfe/buddypress-allyship:latest
   ```

#### 2. Server Setup

1. Set up your production server using the EnhancedBoot script (see [Server Setup](#server-setup))
2. Install Docker and Docker Compose on the server

#### 3. Configure Production Environment

1. Clone the repository on your production server:
   ```bash
   git clone https://github.com/TortoiseWolfe/wp-dev.git
   cd wp-dev
   ```

2. Create and configure your .env file for production:
   ```bash
   cp .env.example .env
   nano .env  # Edit with production values
   ```

3. Make sure these environment variables are properly set for production:
   ```
   WORDPRESS_DB_HOST=db:3306
   WORDPRESS_DB_USER=your_db_user
   WORDPRESS_DB_PASSWORD=your_db_password
   WORDPRESS_DB_NAME=your_db_name
   WP_SITE_URL=https://your-domain.com
   WP_SITE_TITLE=Your Site Title
   WP_ADMIN_USER=admin_username
   WP_ADMIN_PASSWORD=strong_admin_password
   WP_ADMIN_EMAIL=admin@example.com
   ```

4. Update docker-compose.yml for production:
   - You might want to comment out the development services
   - Make sure the wordpress-prod image points to your GHCR image:
     ```yaml
     wordpress-prod:
       image: ghcr.io/tortoisewolfe/buddypress-allyship:latest
     ```

5. Authenticate with GitHub Container Registry on the production server:
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

#### 4. Launch Production Environment

```bash
# Pull the latest image
docker pull ghcr.io/tortoisewolfe/buddypress-allyship:latest

# Start the production environment
docker-compose up -d wordpress-prod wp-prod-setup db

# Verify everything is running
docker-compose ps
```

### Upgrade Procedure

To upgrade your production environment:

1. Build and push a new image (from your development machine):
   ```bash
   # Update your code, then build and push a new image
   docker build --target production -t ghcr.io/tortoisewolfe/buddypress-allyship:latest .
   docker push ghcr.io/tortoisewolfe/buddypress-allyship:latest
   ```

2. On the production server, pull the new image and restart:
   ```bash
   cd /path/to/wp-dev
   git pull  # Update docker-compose.yml and scripts if needed
   docker pull ghcr.io/tortoisewolfe/buddypress-allyship:latest
   docker-compose down wordpress-prod wp-prod-setup
   docker-compose up -d wordpress-prod wp-prod-setup
   ```

For major updates that require data migration:

1. Create a backup first (see [Backup Strategy](#backup-strategy))
2. Follow the standard upgrade procedure
3. If needed, run database migrations:
   ```bash
   docker-compose exec wordpress-prod wp core update-db --allow-root
   ```

You can tag specific versions to maintain rollback capability:
```bash
# Tag a specific version
docker build --target production -t ghcr.io/tortoisewolfe/buddypress-allyship:v1.2.3 .
docker push ghcr.io/tortoisewolfe/buddypress-allyship:v1.2.3

# On production, use a specific version
docker pull ghcr.io/tortoisewolfe/buddypress-allyship:v1.2.3
# Update docker-compose.yml to use the specific version
```

### Backup Strategy

Always backup before upgrading:

```bash
# Database backup
docker-compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > backup.sql

# WordPress files backup
docker-compose exec wordpress-prod tar -czf /tmp/wp-content-backup.tar.gz /var/www/html/wp-content
docker cp wp-dev_wordpress-prod_1:/tmp/wp-content-backup.tar.gz ./wp-content-backup.tar.gz
```

To restore from backup:

```bash
# Restore database
cat backup.sql | docker-compose exec -T db mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}

# Restore files (if needed)
docker cp ./wp-content-backup.tar.gz wp-dev_wordpress-prod_1:/tmp/
docker-compose exec wordpress-prod bash -c "cd / && tar -xzf /tmp/wp-content-backup.tar.gz"
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