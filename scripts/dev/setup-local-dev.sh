#!/bin/bash
# Local development setup script

# Generate secure random passwords for local development
ROOT_PW=$(openssl rand -base64 20 | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
DB_PW=$(openssl rand -base64 20 | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
ADMIN_PW=$(openssl rand -base64 20 | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

# Set mock values for local development
export MYSQL_ROOT_PASSWORD="$ROOT_PW"
export MYSQL_PASSWORD="$DB_PW"
export WORDPRESS_DB_PASSWORD="$DB_PW"
export WP_ADMIN_PASSWORD="$ADMIN_PW"
export WP_ADMIN_EMAIL="admin@example.com"

# Always install GamiPress by default
INSTALL_GAMIPRESS=true
export INSTALL_GAMIPRESS="true"

# Ask if demo content should be skipped
read -p "Skip demo content installation? (y/n): " skip_demo
if [[ "$skip_demo" =~ ^[Yy] ]]; then
  SKIP_DEMO=true
  export SKIP_DEMO_CONTENT="true"
else
  SKIP_DEMO=false
  export SKIP_DEMO_CONTENT="false"
fi

# Update .env file with the development secrets
sed -i.bak "/# Added automatically by/d" .env
sed -i.bak "/# These will be overwritten by/d" .env
sed -i.bak "/^MYSQL_ROOT_PASSWORD=/d" .env
sed -i.bak "/^MYSQL_PASSWORD=/d" .env
sed -i.bak "/^WORDPRESS_DB_PASSWORD=/d" .env
sed -i.bak "/^WP_ADMIN_PASSWORD=/d" .env
sed -i.bak "/^WP_ADMIN_EMAIL=/d" .env
sed -i.bak "/^SKIP_DEMO_CONTENT=/d" .env
sed -i.bak "/^INSTALL_GAMIPRESS=/d" .env

# Add the new values to .env
cat >> .env << EOF

# Added automatically by setup-local-dev.sh - Do not edit
# These will be overwritten each time
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD
WP_ADMIN_PASSWORD=$WP_ADMIN_PASSWORD
WP_ADMIN_EMAIL=$WP_ADMIN_EMAIL
SKIP_DEMO_CONTENT=$SKIP_DEMO
INSTALL_GAMIPRESS=$INSTALL_GAMIPRESS
EOF

echo "----------------------------------------"
echo "🔐 Local development passwords generated:"
echo "----------------------------------------"
echo "MySQL Root Password: $MYSQL_ROOT_PASSWORD"
echo "MySQL WordPress Password: $MYSQL_PASSWORD"
echo "WordPress Admin Password: $WP_ADMIN_PASSWORD"
echo "WordPress Admin Email: $WP_ADMIN_EMAIL"
echo "Demo Content: $(if [[ "$SKIP_DEMO_CONTENT" == "true" ]]; then echo "Disabled"; else echo "Enabled"; fi)"
echo "GamiPress: Enabled (always installed)"
echo "----------------------------------------"
echo "Save these passwords somewhere safe!"
echo "----------------------------------------"
echo ""
echo "To start the development environment, run:"
echo "sudo -E docker-compose up -d wordpress wp-setup db"
echo ""

# Always get the current IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')
if [ -z "$LOCAL_IP" ]; then
  LOCAL_IP=$(ip addr show | grep -E "inet .* scope global" | head -1 | awk '{print $2}' | cut -d/ -f1)
fi

if [ -z "$LOCAL_IP" ]; then
  # If we can't detect the IP, use localhost
  echo "Could not detect IP address, using localhost"
  LOCAL_IP="localhost"
  export WP_SITE_URL="http://localhost:8000"
else
  echo "===== IP ADDRESS DETECTED: $LOCAL_IP ====="
  echo "WordPress will be available at:"
  echo "- From this machine: http://localhost:8000"
  echo "- From other machines: http://$LOCAL_IP:8000"
  
  # Set WP_SITE_URL to the detected IP address
  export WP_SITE_URL="http://$LOCAL_IP:8000"
  # Update .env with the IP address
  sed -i.bak "/^WP_SITE_URL=/d" .env
  echo "WP_SITE_URL=http://$LOCAL_IP:8000" >> .env
  echo "IMPORTANT: Site URL set to http://$LOCAL_IP:8000 for proper functionality"
fi

echo "Admin login: ${WP_ADMIN_USER:-admin} / $WP_ADMIN_PASSWORD"