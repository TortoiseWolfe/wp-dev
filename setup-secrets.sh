#!/bin/bash
# Script to export secret values as environment variables for Docker

# Export secret values from Google Secret Manager
export MYSQL_ROOT_PASSWORD=$(gcloud secrets versions access latest --secret="MYSQL_ROOT_PASSWORD")
export MYSQL_PASSWORD=$(gcloud secrets versions access latest --secret="MYSQL_PASSWORD") 
export WORDPRESS_DB_PASSWORD=$(gcloud secrets versions access latest --secret="MYSQL_PASSWORD")
export WP_ADMIN_PASSWORD=$(gcloud secrets versions access latest --secret="WP_ADMIN_PASSWORD")
export WP_ADMIN_EMAIL=$(gcloud secrets versions access latest --secret="WP_ADMIN_EMAIL")
export GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="GITHUB_TOKEN")

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