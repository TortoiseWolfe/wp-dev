#!/bin/bash
# Local development version of setup-secrets.sh that uses mock values

# Mock values for local development only
export MYSQL_ROOT_PASSWORD=localdevroot
export MYSQL_PASSWORD=localdevpass
export WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
export WP_ADMIN_PASSWORD=localdevadmin
export WP_ADMIN_EMAIL=localdev@example.com
export GITHUB_TOKEN="mock-github-token-for-local-dev"

# Update .env file with the secrets
sed -i.bak "/# Added automatically by setup-secrets.sh/d" .env
sed -i.bak "/# These will be overwritten by setup-secrets.sh each time/d" .env
sed -i.bak "/^MYSQL_ROOT_PASSWORD=/d" .env
sed -i.bak "/^MYSQL_PASSWORD=/d" .env
sed -i.bak "/^WORDPRESS_DB_PASSWORD=/d" .env
sed -i.bak "/^WP_ADMIN_PASSWORD=/d" .env
sed -i.bak "/^WP_ADMIN_EMAIL=/d" .env

# Add the new values
echo "" >> .env
echo "# Added automatically by setup-secrets-local.sh - Do not edit" >> .env
echo "# These will be overwritten by setup-secrets.sh each time" >> .env
echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" >> .env
echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> .env
echo "WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD" >> .env
echo "WP_ADMIN_PASSWORD=$WP_ADMIN_PASSWORD" >> .env
echo "WP_ADMIN_EMAIL=$WP_ADMIN_EMAIL" >> .env

echo "MOCK SECRET VALUES have been set for LOCAL DEVELOPMENT ONLY."
echo "⚠️  WARNING: These credentials are not secure. Only use for local development."
echo "Usage: sudo -E docker-compose up -d"
echo "NOTE: For local development testing only, GitHub image authentication will fail."
echo "You'll need to build the image locally with 'sudo docker-compose build'."