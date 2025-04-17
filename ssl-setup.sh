#!/bin/bash
# ssl-setup.sh - Script to automate SSL certificate setup for WordPress
# For production environment on scripthammer.com

# Don't stop immediately on errors, but track them
set +e

# Log file for this run
LOG_FILE="/tmp/ssl-setup-$(date +%Y%m%d-%H%M%S).log"
echo "Starting SSL setup at $(date)" | tee $LOG_FILE
echo "All logs will be saved to $LOG_FILE" | tee -a $LOG_FILE

# Function to log messages
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Function to log errors
log_error() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a $LOG_FILE
}

# Function to exit on error
error_exit() {
  log_error "$1"
  log_error "Check log file at $LOG_FILE for details"
  log_error "Exiting"
  exit 1
}

# Ensure we run with proper privileges
if [ "$(id -u)" -ne 0 ]; then
  error_exit "This script must be run as root (sudo)"
fi

# Load only domain and email from .env file to avoid issues with special characters
log "Extracting domain and email from .env file"
if [ -f .env ]; then
  # Use grep with safe pattern extraction to avoid issues with special characters
  # Extract domain from WP_SITE_URL or DOMAIN_NAME
  WP_SITE_URL=$(grep -E "^WP_SITE_URL=" .env | cut -d= -f2 | tr -d '"' | tr -d "'")
  if [ -n "$WP_SITE_URL" ]; then
    DOMAIN_NAME=$(echo "$WP_SITE_URL" | sed "s|https://||" | sed "s|http://||" | sed "s|/||g")
  else
    DOMAIN_NAME=$(grep -E "^DOMAIN_NAME=" .env | cut -d= -f2 | tr -d '"' | tr -d "'")
  fi

  # Extract email from WP_ADMIN_EMAIL or CERTBOT_EMAIL
  ADMIN_EMAIL=$(grep -E "^WP_ADMIN_EMAIL=" .env | cut -d= -f2 | tr -d '"' | tr -d "'")
  if [ -z "$ADMIN_EMAIL" ] || [ "$ADMIN_EMAIL" = "admin@example.com" ]; then
    ADMIN_EMAIL=$(grep -E "^CERTBOT_EMAIL=" .env | cut -d= -f2 | tr -d '"' | tr -d "'")
  fi
else
  error_exit ".env file not found. Are you in the correct directory?"
fi

# Validate domain and email
if [ -z "$DOMAIN_NAME" ]; then
  error_exit "Domain name is empty. Check your .env file for WP_SITE_URL or DOMAIN_NAME."
fi

if [ -z "$ADMIN_EMAIL" ]; then
  error_exit "Admin email is empty. Check your .env file for WP_ADMIN_EMAIL or CERTBOT_EMAIL."
fi

log "Setting up SSL for domain: $DOMAIN_NAME"
log "Using email: $ADMIN_EMAIL"

# Ensure the domain and email are set in .env
sed -i "s|DOMAIN_NAME=.*|DOMAIN_NAME=$DOMAIN_NAME|" .env
sed -i "s|CERTBOT_EMAIL=.*|CERTBOT_EMAIL=$ADMIN_EMAIL|" .env

# Create directories
mkdir -p ./nginx/ssl/live/$DOMAIN_NAME
mkdir -p ./nginx/conf

# Generate temporary self-signed certificate
echo "Generating temporary self-signed certificate for $DOMAIN_NAME..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ./nginx/ssl/live/$DOMAIN_NAME/privkey.pem \
  -out ./nginx/ssl/live/$DOMAIN_NAME/fullchain.pem \
  -subj "/CN=$DOMAIN_NAME/O=Example/C=US"

# Create Nginx configuration
cat > ./nginx/conf/default.conf << EOF
# HTTP server for certificate validation
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # Redirect HTTP to HTTPS except for certbot challenges
    location / {
        return 301 https://\$host\$request_uri;
    }
    
    # For Let's Encrypt certificate validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

# HTTPS server for main site
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # SSL configuration
    ssl_certificate /etc/nginx/ssl/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/live/$DOMAIN_NAME/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # Production WordPress proxy
    location / {
        proxy_pass http://wordpress-prod:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Allow large uploads
    client_max_body_size 100M;
    
    # Deny access to sensitive files
    location ~ /\\. {
        deny all;
    }
    
    # Deny access to WordPress configuration
    location ~* wp-config.php {
        deny all;
    }
}

# Development server (only used locally)
server {
    listen 80;
    listen [::]:80;
    server_name localhost 127.0.0.1;
    
    # Development WordPress proxy
    location / {
        proxy_pass http://wordpress:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Stop and restart containers
log "Restarting containers to apply SSL configuration..."
sudo -E docker-compose down
sudo -E docker-compose up -d

# Wait for Nginx to start
log "Waiting for Nginx to start..."
sleep 10
MAX_ATTEMPTS=12
ATTEMPT=0

# Check if Nginx is running with retry
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT+1))
  nginx_container=$(sudo -E docker-compose ps -q nginx)
  if [ -n "$nginx_container" ]; then
    nginx_status=$(sudo docker inspect --format='{{.State.Status}}' $nginx_container)
    if [ "$nginx_status" = "running" ]; then
      log "Nginx container is running (attempt $ATTEMPT/$MAX_ATTEMPTS)"
      break
    else
      log "Nginx container status: $nginx_status (attempt $ATTEMPT/$MAX_ATTEMPTS), waiting..."
    fi
  else
    log "Nginx container not found (attempt $ATTEMPT/$MAX_ATTEMPTS), waiting..."
  fi
  
  if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    log_error "Nginx container failed to start after $MAX_ATTEMPTS attempts"
    log "Dumping container logs:"
    sudo -E docker-compose logs --tail=100 nginx >> $LOG_FILE 2>&1
    error_exit "Nginx container failed to start. Check the logs for details."
  fi
  
  sleep 5
done

# Check if certbot container is running with retry
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT+1))
  certbot_container=$(sudo -E docker-compose ps -q certbot)
  if [ -n "$certbot_container" ]; then
    certbot_status=$(sudo docker inspect --format='{{.State.Status}}' $certbot_container)
    if [ "$certbot_status" = "running" ]; then
      log "Certbot container is running (attempt $ATTEMPT/$MAX_ATTEMPTS)"
      break
    else
      log "Certbot container status: $certbot_status (attempt $ATTEMPT/$MAX_ATTEMPTS), waiting..."
    fi
  else
    log "Certbot container not found (attempt $ATTEMPT/$MAX_ATTEMPTS), waiting..."
  fi
  
  if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    log_error "Certbot container failed to start after $MAX_ATTEMPTS attempts"
    log "Dumping container logs:"
    sudo -E docker-compose logs --tail=100 certbot >> $LOG_FILE 2>&1
    error_exit "Certbot container failed to start. Check the logs for details."
  fi
  
  sleep 5
done

# Verify DNS resolution for domain
log "Verifying DNS resolution for $DOMAIN_NAME..."
host_result=$(host $DOMAIN_NAME 2>&1)
if [ $? -ne 0 ]; then
  log_error "DNS resolution for $DOMAIN_NAME failed: $host_result"
  log_error "Make sure DNS is properly configured to point to this server's IP address"
  log "Continuing anyway, but certificate issuance may fail if DNS is not properly configured"
else
  domain_ip=$(echo "$host_result" | grep "has address" | head -n1 | awk '{print $NF}')
  server_ip=$(curl -s http://checkip.amazonaws.com/ || wget -q -O - http://checkip.amazonaws.com/)
  
  log "Domain $DOMAIN_NAME resolves to: $domain_ip"
  log "Server public IP appears to be: $server_ip"
  
  if [ "$domain_ip" != "$server_ip" ]; then
    log_error "WARNING: Domain IP ($domain_ip) does not match server IP ($server_ip)"
    log_error "DNS may not be properly configured, which could cause certificate issuance to fail"
    log "Continuing anyway, but certificate issuance may fail if DNS is not properly configured"
  else
    log "DNS resolution confirmed: $DOMAIN_NAME correctly points to this server"
  fi
fi

# Request real Let's Encrypt certificate
log "Requesting Let's Encrypt certificates for $DOMAIN_NAME..."
log "This may take a minute or two..."
sudo -E docker-compose exec -T certbot certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email "$ADMIN_EMAIL" \
  --agree-tos \
  --no-eff-email \
  --force-renewal \
  -d "$DOMAIN_NAME" \
  -d "www.$DOMAIN_NAME" \
  2>&1 | tee -a $LOG_FILE

# Check if certificate was obtained
CERT_RESULT=$?
if [ $CERT_RESULT -ne 0 ]; then
  log_error "Certificate request failed with exit code $CERT_RESULT"
  log_error "Checking if port 80 is publicly accessible for ACME challenges..."
  
  # Check if port 80 is publicly accessible
  curl -sI "http://$DOMAIN_NAME/.well-known/acme-challenge/test" > /tmp/acme_test.log 2>&1
  if [ $? -ne 0 ]; then
    log_error "Port 80 does not appear to be publicly accessible at http://$DOMAIN_NAME/.well-known/acme-challenge/test"
    log_error "This is required for Let's Encrypt to verify domain ownership"
    cat /tmp/acme_test.log >> $LOG_FILE
  else
    log "Port 80 appears to be publicly accessible"
  fi
  
  log "Manual certificate issuance command for troubleshooting:"
  log "sudo -E docker-compose exec certbot certbot certonly --webroot --webroot-path=/var/www/certbot --email $ADMIN_EMAIL --agree-tos --no-eff-email --force-renewal -d $DOMAIN_NAME -d www.$DOMAIN_NAME"
  
  # Check if we can use self-signed instead for now
  log "Using self-signed certificates for now until domain verification issues are resolved"
else
  log "Certificate successfully obtained!"
fi

# Restart Nginx to apply new certificates
log "Restarting Nginx to apply Let's Encrypt certificates..."
sudo -E docker-compose restart nginx
if [ $? -ne 0 ]; then
  log_error "Failed to restart Nginx"
  log "Dumping Nginx logs:"
  sudo -E docker-compose logs --tail=50 nginx >> $LOG_FILE 2>&1
else
  log "Nginx restarted successfully"
fi

# Check if Nginx config is valid
sudo -E docker-compose exec -T nginx nginx -t 2>&1 | tee -a $LOG_FILE
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  log_error "Nginx configuration test failed"
  log "Dumping Nginx configuration:"
  sudo -E docker-compose exec -T nginx nginx -T >> $LOG_FILE 2>&1
else
  log "Nginx configuration is valid"
fi

# Verify certificate is accessible
log "Verifying HTTPS access..."
curl -sILk https://$DOMAIN_NAME > /tmp/https_test.log 2>&1
if [ $? -ne 0 ]; then
  log_error "HTTPS connection failed"
  cat /tmp/https_test.log >> $LOG_FILE
  log_error "This may be due to network issues or firewall settings"
else
  https_status=$(grep "HTTP/" /tmp/https_test.log | tail -1 | awk '{print $2}')
  log "HTTPS connection successful (status: $https_status)"
  cat /tmp/https_test.log >> $LOG_FILE
fi

# List certificates for verification
log "Listing installed certificates:"
sudo -E docker-compose exec -T certbot certbot certificates 2>&1 | tee -a $LOG_FILE

log "SSL setup complete for $DOMAIN_NAME!"
log "Your site should now be accessible at: https://$DOMAIN_NAME"
log "You can verify certificate status with: sudo -E docker-compose exec certbot certbot certificates"
log "Certificates will be automatically renewed by the certbot container."
log "If you encounter SSL issues, check the log file at: $LOG_FILE"

# Summary of commands for troubleshooting
log "=== Troubleshooting commands ==="
log "Check certificate status: sudo -E docker-compose exec certbot certbot certificates"
log "Test Nginx config: sudo -E docker-compose exec nginx nginx -t"
log "View Nginx config: sudo -E docker-compose exec nginx nginx -T"
log "Check SSL certificates: sudo ls -la $(pwd)/nginx/ssl/live/$DOMAIN_NAME/"
log "Verify HTTP access: curl -sI http://$DOMAIN_NAME/.well-known/acme-challenge/test"
log "Force Nginx reload: sudo -E docker-compose exec nginx nginx -s reload"