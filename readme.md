# WordPress Development Environment

A Docker-based WordPress environment with BuddyPress for development and production.

## Prerequisites

- Docker & Docker Compose
- Git
- Node.js v22 (via nvm)
- npm
- (Optional) Google Cloud SDK (for secrets)
- (Optional) GitHub Personal Access Token (PAT) with read:packages, write:packages, repo scopes (for GHCR)
  
### Node.js v22 Installation

We recommend using nvm to install Node.js v22:
```bash
# Install or update nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# Load nvm in current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js v22 and set as default
nvm install 22
nvm alias default 22

# Verify installation
node -v
npm -v
```

## Local Development

```bash
git clone https://github.com/TortoiseWolfe/wp-dev.git
cd wp-dev
```

### 2. Setting Up SSH Keys

Generate and configure SSH keys for both GitHub repository access and remote development:

```bash
# Generate SSH key (if you don't have one already)
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519

# For GitHub repository access
cat ~/.ssh/id_ed25519.pub  # Copy this to GitHub → Settings → SSH keys
ssh -T git@github.com      # Verify connection

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
# Copy example environment variables (only if .env does not already exist)
if [ ! -f .env ]; then
  cp .env.example .env
  echo ".env file created from .env.example"
else
  echo ".env already exists; skipping copy. Please backup and update it manually if needed."
fi

# For local development (without Google Secret Manager)
source ./scripts/dev/setup-local-dev.sh

# For production (with Google Secret Manager)
source ./scripts/setup-secrets.sh

# Start containers
docker-compose up -d
```

Access the site: http://localhost:8000

WP-CLI example:
```bash
docker-compose exec wordpress wp --allow-root plugin list
```

## Production

### Build & Push
```bash
docker build --target production -t ghcr.io/tortoisewolfe/wp-dev:v0.1.2 .
echo $GITHUB_TOKEN | docker login ghcr.io -u tortoisewolfe --password-stdin
docker push ghcr.io/tortoisewolfe/wp-dev:v0.1.2
```

### Deploy
```bash
git pull origin main
# Load secrets (including GITHUB_TOKEN for GHCR)
./scripts/setup-secrets.sh
# Log in to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u your_github_username --password-stdin
# Pull latest images (avoid local rebuilds)
docker-compose pull
# Start containers without rebuilding images
docker-compose up -d --no-build
```

Or use the deploy script:
```bash
chmod +x deploy-prod.sh
./deploy-prod.sh
```

## Directory Structure

```text
wp-dev/
├── devscripts/
├── docs/
│   └── CLAUDE.md
├── nginx/
├── scripts/
│   ├── dev/
│   └── ssl/
├── docker-compose.yml
├── Dockerfile
└── .env.example
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

### Docker Permission Errors

If you see `Error: kill EPERM` when running Docker commands:

```bash
# This error occurs when scripts running with sudo try to use sudo commands internally.
# To fix this, always follow this pattern in your scripts:

if [ "$(id -u)" -eq 0 ]; then
  # Running as root (via sudo), use docker commands directly
  docker-compose command
else
  # Not running as root, use sudo -E with docker commands
  sudo -E docker-compose command
fi
```

Important guidelines:
- Always run scripts with sudo first: `sudo ./scripts/ssl/ssl-setup.sh`
- Never add additional sudo commands inside scripts already run with sudo
- Use sudo -E (not just sudo) when environment variables need to be preserved
- Apply this pattern to ALL docker/docker-compose commands in scripts

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
   # - For repeated end-to-end testing without hitting production rate limits, you can enable staging mode with the new flag:
   #     sudo bash -x scripts/ssl/ssl-setup.sh --staging | tee ssl-setup-staging-$(date +%Y%m%d-%H%M%S).log
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

See `docs/CLAUDE.md` and the `scripts/` directory for advanced instructions.