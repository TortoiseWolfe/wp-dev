#!/bin/bash
# Script to generate and export secret values as environment variables for Docker

# Generate random passwords
export MYSQL_ROOT_PASSWORD=$(tr -dc 'A-Za-z0-9!#$%&*+-' < /dev/urandom | head -c 12)
export MYSQL_PASSWORD=$(tr -dc 'A-Za-z0-9!#$%&*+-' < /dev/urandom | head -c 12)
export WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
export WP_ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9!#$%&*+-' < /dev/urandom | head -c 12)
export WP_ADMIN_EMAIL="admin@example.com"
export GITHUB_TOKEN="ghp_dummy_token_for_local_dev"

# Update .env file with the secrets - Docker Compose will use these values
sed -i.bak "/# Added automatically by setup-secrets.sh/d" .env
sed -i.bak "/# These will be overwritten by setup-secrets.sh each time/d" .env
sed -i.bak "/^MYSQL_ROOT_PASSWORD=/d" .env
sed -i.bak "/^MYSQL_PASSWORD=/d" .env
sed -i.bak "/^WORDPRESS_DB_PASSWORD=/d" .env
sed -i.bak "/^WP_ADMIN_PASSWORD=/d" .env
sed -i.bak "/^WP_ADMIN_EMAIL=/d" .env

# Add the new values
echo "" >> .env
echo "# Added automatically by setup-secrets.sh - Do not edit" >> .env
echo "# These will be overwritten by setup-secrets.sh each time" >> .env
echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" >> .env
echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> .env
echo "WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD" >> .env
echo "WP_ADMIN_PASSWORD=$WP_ADMIN_PASSWORD" >> .env
echo "WP_ADMIN_EMAIL=$WP_ADMIN_EMAIL" >> .env

# Configure SSH for Git with persistent key management
SSH_KEY_PATH=~/.ssh/github_wp_dev
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate key only if it doesn't exist
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "No persistent SSH key found. Generating one at $SSH_KEY_PATH..."
  ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "wp-dev-persistent-key"
  echo "New SSH key generated."
else
  echo "Using existing SSH key at $SSH_KEY_PATH"
fi

# Add GitHub to known hosts if not already there
if ! grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null; then
  ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
fi

# Create or update SSH config file
if ! grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
  cat >> ~/.ssh/config << EOF

# WP-Dev GitHub configuration
Host github.com
  User git
  IdentityFile $SSH_KEY_PATH
  IdentitiesOnly yes
EOF
  echo "SSH configuration added to ~/.ssh/config"
fi

chmod 600 ~/.ssh/config
chmod 600 "$SSH_KEY_PATH"

# Display public key information
echo "Your persistent SSH public key (add to GitHub if not already):"
cat "${SSH_KEY_PATH}.pub"

# Add key to SSH agent if not already added
if ! ssh-add -l | grep -q "$(ssh-keygen -lf "$SSH_KEY_PATH" | awk '{print $2}')"; then
  echo "Adding key to SSH agent..."
  ssh-add "$SSH_KEY_PATH" 2>/dev/null || echo "Could not add key to agent (agent may not be running)"
fi

echo "Secret values exported to environment variables. You can now run Docker Compose."
echo "Usage: sudo -E docker-compose up -d"
echo "⚠️  CRITICAL REMINDER: You MUST log in to Docker registry AFTER sourcing this script:"
echo "echo \$GITHUB_TOKEN | sudo -E docker login ghcr.io -u tortoisewolfe -p \$GITHUB_TOKEN"