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

### Using the Production Environment in docker-compose.yml

The docker-compose.yml file contains a commented-out production section. To use it:

1. Uncomment the `wordpress-prod` service section (lines 58-84)
2. Modify the port from 8080 to 80 for a true production environment
3. You can either:
   - Keep the development section active (to run both environments simultaneously)
   - Comment out the development section (if you only want the production environment)

Note that when both environments are active, they will share the same database but use separate WordPress volumes.

### Complete Deployment Workflow

1. **Local Development**: Develop and test features locally using development environment
2. **Build Production Image**: Create a production-ready Docker image
3. **Test Production Locally**: Verify production image works correctly
4. **Push to Container Registry**: Upload image to GitHub Container Registry
5. **Server Preparation**: Set up production server with EnhancedBoot script
6. **Deploy to Production**: Pull and run the image on production server

### Building Production Image

```bash
docker build --target production -t tortoisewolfe/buddypress-allyship:latest .
```

### Testing Production Build Locally

```bash
# Start just the database
docker-compose up -d db

# Build production image
docker build --target production -t mywordpress:prod .

# Run production image with local database
docker run -d -p 8888:80 \
  --network wp-dev_default \
  -e WORDPRESS_DB_HOST=db \
  -e WORDPRESS_DB_USER=wordpress \
  -e WORDPRESS_DB_PASSWORD=wordpress \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WP_SITE_URL=http://$(hostname -I | awk '{print $1}'):8888 \
  mywordpress:prod

# Access at http://[Your-IP]:8888
```

### Deployment Options

#### 1. GitHub Container Registry (Automated)

The repository is configured with GitHub Actions to automatically build and publish Docker images to GitHub Container Registry whenever:
- You push to the main branch
- You create a new tag (v*.*.*)

To use the automatically built image:

```bash
# Pull the production image
docker pull ghcr.io/TortoiseWolfe/wp-dev:latest

# Run with your configuration
docker run -d -p 80:80 \
  -e WORDPRESS_DB_HOST=your-db-host \
  -e WORDPRESS_DB_USER=your-db-user \
  -e WORDPRESS_DB_PASSWORD=your-db-password \
  -e WORDPRESS_DB_NAME=your-db-name \
  ghcr.io/TortoiseWolfe/wp-dev:latest
```

#### 2. Manual Deployment

For manual deployment to your own registry:

```bash
# Build the production image
docker build --target production -t tortoisewolfe/buddypress-allyship:latest .

# Push to your registry
docker push tortoisewolfe/buddypress-allyship:latest
```

### Production Environment Configuration

The production environment requires the following environment variables:

```
WORDPRESS_DB_HOST=db-hostname
WORDPRESS_DB_USER=db-username
WORDPRESS_DB_PASSWORD=db-password
WORDPRESS_DB_NAME=db-name
WP_SITE_URL=https://your-domain.com
WP_SITE_TITLE=Your Site Title
WP_ADMIN_USER=admin-username
WP_ADMIN_PASSWORD=admin-password
WP_ADMIN_EMAIL=admin@example.com
```

### Upgrade Procedure

#### Automated Upgrades via GitHub

To upgrade to a new version:

1. Tag a new release in GitHub (e.g., `v1.0.1`)
2. GitHub Actions will build and publish the new image
3. Pull the new image and restart your container

#### Manual Upgrade

```bash
# Pull latest code changes
git pull

# Rebuild production image
docker build --target production -t tortoisewolfe/buddypress-allyship:latest .

# Stop existing container
docker stop your-container-name

# Start new container with updated image
docker run -d -p 80:80 \
  -e WORDPRESS_DB_HOST=your-db-host \
  -e WORDPRESS_DB_USER=your-db-user \
  -e WORDPRESS_DB_PASSWORD=your-db-password \
  -e WORDPRESS_DB_NAME=your-db-name \
  tortoisewolfe/buddypress-allyship:latest
```

### Backup Strategy

Always backup before upgrading:

```bash
# Database backup
docker exec -it db_container mysqldump -u root -p wordpress > backup.sql

# WordPress files backup
docker cp wordpress_container:/var/www/html/wp-content ./wp-content-backup
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

## Additional Resources

- [WordPress Codex](https://codex.wordpress.org/)
- [BuddyPress Documentation](https://codex.buddypress.org/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)