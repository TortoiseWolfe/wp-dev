#!/usr/bin/env bash
# show-admin-creds.sh - Read WP admin credentials from .env
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. Please copy .env.example to .env and run setup-local-dev.sh first."
  exit 1
fi

# Extract credentials
ADMIN_USER=$(grep -E '^WP_ADMIN_USER=' "$ENV_FILE" | head -n1 | cut -d'=' -f2-)
ADMIN_PW=$(grep -E '^WP_ADMIN_PASSWORD=' "$ENV_FILE" | head -n1 | cut -d'=' -f2-)

if [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_PW" ]; then
  echo "Error: WP_ADMIN_USER or WP_ADMIN_PASSWORD not set in $ENV_FILE"
  exit 1
fi

echo "WordPress Admin Credentials:"
echo "  Username: $ADMIN_USER"
echo "  Password: $ADMIN_PW"