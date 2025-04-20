#!/bin/bash
# ssl-setup.sh - Script to automate SSL certificate setup for WordPress
# For production environment on scripthammer.com

# IMPORTANT: This script MUST be run with sudo: sudo ./scripts/ssl/ssl-setup.sh [--staging]
# ROOT PERMISSION HANDLING: Throughout this script, we check whether we're running as root
# and adjust docker commands accordingly to prevent "Error: kill EPERM" permission issues.
# PATTERN: if [ "$(id -u)" -eq 0 ]; then docker-compose ...; else sudo -E docker-compose ...; fi
# Do NOT add/remove sudo commands without understanding this pattern!
# Optional flags:
#   --staging    Use Let's Encrypt staging environment (avoids production rate limits)

# Don't stop immediately on errors, but track them; also capture pipeline failures
set +e
set -o pipefail

# Log file for this run
LOG_FILE="/tmp/ssl-setup-$(date +%Y%m%d-%H%M%S).log"
echo "Starting SSL setup at $(date)" | tee $LOG_FILE
echo "All logs will be saved to $LOG_FILE" | tee -a $LOG_FILE
 
# Parse command-line flags
while (( "$#" )); do
  case "$1" in
    --staging)
      STAGING="1"
      ;;
    *)
      ;;
  esac
  shift
done

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
# Ensure we run with proper privileges
if [ "$(id -u)" -ne 0 ]; then
  error_exit "This script must be run as root (sudo)"
fi

# Load only domain and email from .env file
log "Extracting domain and email from .env file"

# Determine script and repository root to locate .env reliably
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ -f "$REPO_ROOT/.env" ]; then
  ENV_FILE="$REPO_ROOT/.env"
elif [ -f "/var/www/wp-dev/.env" ]; then
  ENV_FILE="/var/www/wp-dev/.env"
else
  error_exit "Could not locate .env file. Checked $REPO_ROOT/.env and /var/www/wp-dev/.env"
fi
log "Using .env file at $ENV_FILE"

# STAGING MODE: if STAGING env var is set (1 or true), use Let's Encrypt staging server to avoid rate limits
if [ "${STAGING}" = "1" ] || [ "${STAGING}" = "true" ]; then
  STAGING_FLAG="--staging"
  log "Certbot staging mode enabled (using Let's Encrypt staging environment)"
  # In staging mode, allow replacing existing certs
  BREAK_FLAG="--break-my-certs"
else
  STAGING_FLAG=""
  BREAK_FLAG=""
fi

# Extract domain from WP_SITE_URL or DOMAIN_NAME
WP_SITE_URL=$(grep -E "^WP_SITE_URL=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'")
if [ -n "$WP_SITE_URL" ]; then
  DOMAIN_NAME=$(echo "$WP_SITE_URL" | sed "s|https://||" | sed "s|http://||" | sed "s|/||g")
else
  DOMAIN_NAME=$(grep -E "^DOMAIN_NAME=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'")
fi

# Extract email from WP_ADMIN_EMAIL or CERTBOT_EMAIL
ADMIN_EMAIL=$(grep -E "^WP_ADMIN_EMAIL=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'")
if [ -z "$ADMIN_EMAIL" ] || [ "$ADMIN_EMAIL" = "admin@example.com" ]; then
  ADMIN_EMAIL=$(grep -E "^CERTBOT_EMAIL=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'")
fi

# Validate domain and email
if [ -z "$DOMAIN_NAME" ]; then
  error_exit "Domain name is empty. Check your .env file for WP_SITE_URL or DOMAIN_NAME."
fi

# Handle placeholder WP_ADMIN_EMAIL by falling back to CERTBOT_EMAIL if available
if [[ "$ADMIN_EMAIL" =~ @example\.com$ ]]; then
  log "WARNING: WP_ADMIN_EMAIL ('$ADMIN_EMAIL') appears to be a placeholder. Checking CERTBOT_EMAIL..."
  alt_email=$(grep -E '^CERTBOT_EMAIL=' "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'" )
  if [ -n "$alt_email" ] && ! [[ "$alt_email" =~ @example\.com$ ]]; then
    log "Using CERTBOT_EMAIL: $alt_email"
    ADMIN_EMAIL="$alt_email"
  else
    error_exit "CERTBOT_EMAIL ('$alt_email') appears to be a placeholder. Please set a valid email in your .env file and re-run."
  fi
fi

# Validate domain and email
if [ -z "$ADMIN_EMAIL" ]; then
  error_exit "Admin email is empty. Check your .env file for WP_ADMIN_EMAIL or CERTBOT_EMAIL."
fi

log "Setting up SSL for domain: $DOMAIN_NAME"
log "Using email: $ADMIN_EMAIL"

# Ensure the domain and email are set in .env
sed -i "s|DOMAIN_NAME=.*|DOMAIN_NAME=$DOMAIN_NAME|" "$ENV_FILE"
sed -i "s|CERTBOT_EMAIL=.*|CERTBOT_EMAIL=$ADMIN_EMAIL|" "$ENV_FILE"

 # Create directories under the repo root
 NGINX_DIR="$REPO_ROOT/nginx"
mkdir -p "$NGINX_DIR/ssl/live/$DOMAIN_NAME"
mkdir -p "$NGINX_DIR/conf"

# Generate temporary self-signed certificate
echo "Generating temporary self-signed certificate for $DOMAIN_NAME..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout $NGINX_DIR/ssl/live/$DOMAIN_NAME/privkey.pem \
  -out $NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem \
  -subj "/CN=$DOMAIN_NAME/O=Example/C=US"

# Check if we should update Nginx configuration
NGINX_CONF="$NGINX_DIR/conf/default.conf"
SHOULD_UPDATE_CONF=0

# Determine if we need to update the configuration
if [ ! -f "$NGINX_CONF" ]; then
    log "Nginx configuration file doesn't exist. Creating it."
    SHOULD_UPDATE_CONF=1
else
    # Check if domain in config matches current domain
    DOMAIN_IN_CONFIG=$(grep -o "server_name [^;]*;" "$NGINX_CONF" | head -1 | sed 's/server_name //g' | sed 's/www\.//g' | sed 's/ .*//g' | sed 's/;//g')
    
    if [ "$DOMAIN_IN_CONFIG" != "$DOMAIN_NAME" ]; then
        log "Domain in config ($DOMAIN_IN_CONFIG) doesn't match current domain ($DOMAIN_NAME). Updating."
        SHOULD_UPDATE_CONF=1
    else
        # Check if the certificate is self-signed
        if [ -f "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem" ]; then
            ISSUER=$(openssl x509 -in "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem" -issuer -noout | sed 's/^issuer=//')
            SUBJECT=$(openssl x509 -in "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem" -subject -noout | sed 's/^subject=//')
            
            if [ "$ISSUER" = "$SUBJECT" ]; then
                log "Using self-signed certificate. Will try to obtain Let's Encrypt certificate."
            else
                log "Using valid CA-issued certificate. No need to update configuration."
                # Check certificate expiration
                EXPIRY_DATE=$(openssl x509 -in "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem" -enddate -noout | cut -d= -f2)
                EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
                CURRENT_EPOCH=$(date +%s)
                DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
                
                log "Certificate expires in $DAYS_LEFT days."
                if [ $DAYS_LEFT -lt 30 ]; then
                    log "Certificate expires soon. Will attempt renewal."
                    # We'll try renewal but don't need to update config
                fi
            fi
        else
            log "SSL certificates not found. Generating new configuration."
            SHOULD_UPDATE_CONF=1
        fi
    fi
fi

# Create Nginx configuration if needed
if [ $SHOULD_UPDATE_CONF -eq 1 ]; then
    log "Creating new Nginx configuration for $DOMAIN_NAME"
    cat > $NGINX_DIR/conf/default.conf << EOF
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
    log "Nginx configuration created."
else
    log "Keeping existing Nginx configuration."
fi

# Stop and restart containers
log "Restarting containers to apply SSL configuration..."
# Use docker-compose directly when running as root, otherwise use sudo
if [ "$(id -u)" -eq 0 ]; then
  docker-compose down
  docker-compose up -d
else
  sudo -E docker-compose down
  sudo -E docker-compose up -d
fi

# Wait for Nginx to start
log "Waiting for Nginx to start..."
sleep 10
MAX_ATTEMPTS=12
ATTEMPT=0

# Check if Nginx is running with retry
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT+1))
  if [ "$(id -u)" -eq 0 ]; then
    nginx_container=$(docker-compose ps -q nginx)
  else
    nginx_container=$(sudo -E docker-compose ps -q nginx)
  fi
  if [ -n "$nginx_container" ]; then
    if [ "$(id -u)" -eq 0 ]; then
      nginx_status=$(docker inspect --format='{{.State.Status}}' $nginx_container)
    else
      nginx_status=$(sudo docker inspect --format='{{.State.Status}}' $nginx_container)
    fi
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
    if [ "$(id -u)" -eq 0 ]; then
      docker-compose logs --tail=100 nginx >> $LOG_FILE 2>&1
    else
      sudo -E docker-compose logs --tail=100 nginx >> $LOG_FILE 2>&1
    fi
    error_exit "Nginx container failed to start. Check the logs for details."
  fi
  
  sleep 5
done

# Check if certbot container is running with retry
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT+1))
  if [ "$(id -u)" -eq 0 ]; then
    certbot_container=$(docker-compose ps -q certbot)
  else
    certbot_container=$(sudo -E docker-compose ps -q certbot)
  fi
  if [ -n "$certbot_container" ]; then
    if [ "$(id -u)" -eq 0 ]; then
      certbot_status=$(docker inspect --format='{{.State.Status}}' $certbot_container)
    else
      certbot_status=$(sudo docker inspect --format='{{.State.Status}}' $certbot_container)
    fi
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
    if [ "$(id -u)" -eq 0 ]; then
      docker-compose logs --tail=100 certbot >> $LOG_FILE 2>&1
    else
      sudo -E docker-compose logs --tail=100 certbot >> $LOG_FILE 2>&1
    fi
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
log "Checking if we should request Let's Encrypt certificates for $DOMAIN_NAME..."

# Check if we should request a new certificate
SHOULD_REQUEST_CERT=0

# Check if the certificate exists and is self-signed
if [ -f "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem" ]; then
    ISSUER=$(openssl x509 -in "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem" -issuer -noout | sed 's/^issuer=//')
    SUBJECT=$(openssl x509 -in "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem" -subject -noout | sed 's/^subject=//')
    
    if [ "$ISSUER" = "$SUBJECT" ]; then
        log "Current certificate is self-signed. Will request Let's Encrypt certificate."
        SHOULD_REQUEST_CERT=1
    elif echo "$ISSUER" | grep -q "(STAGING)"; then
        log "Current certificate is a staging certificate. Forcing production issuance."
        SHOULD_REQUEST_CERT=1
    else
        # Check expiration time
        EXPIRY_DATE=$(openssl x509 -in "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem" -enddate -noout | cut -d= -f2)
        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
        CURRENT_EPOCH=$(date +%s)
        DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
        
        log "Certificate expires in $DAYS_LEFT days."
        if [ $DAYS_LEFT -lt 30 ]; then
            log "Certificate expires in less than 30 days. Will attempt renewal."
            SHOULD_REQUEST_CERT=1
        else
            log "Certificate is valid and not expiring soon. Skipping certificate request."
        fi
    fi
else
    log "No certificate found. Will request Let's Encrypt certificate."
    SHOULD_REQUEST_CERT=1
fi

if [ $SHOULD_REQUEST_CERT -eq 1 ]; then
    log "Requesting Let's Encrypt certificates for $DOMAIN_NAME..."
    log "This may take a minute or two..."
    # Use non-interactive mode for automated certificate issuance
    if [ "$(id -u)" -eq 0 ]; then
      docker-compose exec -T certbot certbot certonly $STAGING_FLAG $BREAK_FLAG \
      --non-interactive \
      --webroot \
      --webroot-path=/var/www/certbot \
      --email "$ADMIN_EMAIL" \
      --agree-tos \
      --no-eff-email \
      --force-renewal \
      -d "$DOMAIN_NAME" \
      -d "www.$DOMAIN_NAME" \
      2>&1 | tee -a $LOG_FILE
    else
      sudo -E docker-compose exec -T certbot certbot certonly $STAGING_FLAG $BREAK_FLAG \
      --non-interactive \
      --webroot \
      --webroot-path=/var/www/certbot \
      --email "$ADMIN_EMAIL" \
      --agree-tos \
      --no-eff-email \
      --force-renewal \
      -d "$DOMAIN_NAME" \
      -d "www.$DOMAIN_NAME" \
      2>&1 | tee -a $LOG_FILE
    fi
else
    log "Skipping Let's Encrypt certificate request."
fi

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
  log "sudo -E docker-compose exec certbot certbot certonly $STAGING_FLAG $BREAK_FLAG --webroot --webroot-path=/var/www/certbot --email $ADMIN_EMAIL --agree-tos --no-eff-email --force-renewal -d $DOMAIN_NAME -d www.$DOMAIN_NAME"
  
  # Check if we can use self-signed instead for now
  log "Using self-signed certificates for now until domain verification issues are resolved"
else
  log "Certificate successfully obtained!"
# End of certificate issuance block
fi

# Update Nginx SSL directory with new certificates
log "Updating Nginx SSL directory with new certificates..."
LATEST_CERT_DIR=$(ls -1d "$NGINX_DIR/ssl/live/${DOMAIN_NAME}"* | sort | tail -n1)
cp -L "$LATEST_CERT_DIR/fullchain.pem" "$NGINX_DIR/ssl/live/$DOMAIN_NAME/fullchain.pem"
cp -L "$LATEST_CERT_DIR/privkey.pem" "$NGINX_DIR/ssl/live/$DOMAIN_NAME/privkey.pem"

# Restart Nginx to apply new certificates
log "Restarting Nginx to apply Let's Encrypt certificates..."
if [ "$(id -u)" -eq 0 ]; then
  docker-compose restart nginx
  RESTART_RESULT=$?
  if [ $RESTART_RESULT -ne 0 ]; then
    log_error "Failed to restart Nginx"
    log "Dumping Nginx logs:"
    docker-compose logs --tail=50 nginx >> $LOG_FILE 2>&1
  else
    log "Nginx restarted successfully"
  fi
else
  sudo -E docker-compose restart nginx
  RESTART_RESULT=$?
  if [ $RESTART_RESULT -ne 0 ]; then
    log_error "Failed to restart Nginx"
    log "Dumping Nginx logs:"
    sudo -E docker-compose logs --tail=50 nginx >> $LOG_FILE 2>&1
  else
    log "Nginx restarted successfully"
  fi
fi

# Check if Nginx config is valid
if [ "$(id -u)" -eq 0 ]; then
  docker-compose exec -T nginx nginx -t 2>&1 | tee -a $LOG_FILE
else
  sudo -E docker-compose exec -T nginx nginx -t 2>&1 | tee -a $LOG_FILE
fi
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  log_error "Nginx configuration test failed"
  log "Dumping Nginx configuration:"
  if [ "$(id -u)" -eq 0 ]; then
    docker-compose exec -T nginx nginx -T >> $LOG_FILE 2>&1
  else
    sudo -E docker-compose exec -T nginx nginx -T >> $LOG_FILE 2>&1
  fi
else
  log "Nginx configuration is valid"
fi

# Verify certificate is accessible with retry support
log "Verifying HTTPS access to https://${DOMAIN_NAME}..."
HTTPS_TEST_LOG="/tmp/https_test.log"
curl -sILk https://${DOMAIN_NAME} > "$HTTPS_TEST_LOG" 2>&1
# Extract last HTTP status code
https_status=$(grep "HTTP/" "$HTTPS_TEST_LOG" | tail -1 | awk '{print $2}')
if [[ ! "$https_status" =~ ^2[0-9]{2}$ ]]; then
  log_error "Initial HTTPS request returned status: $https_status"
  cat "$HTTPS_TEST_LOG" >> $LOG_FILE
  log "Retrying: restarting Nginx and testing again..."
  # Restart Nginx
  if [ "$(id -u)" -eq 0 ]; then
    docker-compose restart nginx
  else
    sudo -E docker-compose restart nginx
  fi
  sleep 5
  curl -sILk https://${DOMAIN_NAME} > "$HTTPS_TEST_LOG" 2>&1
  https_status=$(grep "HTTP/" "$HTTPS_TEST_LOG" | tail -1 | awk '{print $2}')
  if [[ ! "$https_status" =~ ^2[0-9]{2}$ ]]; then
    log_error "Retry HTTPS request failed with status: $https_status"
    cat "$HTTPS_TEST_LOG" >> $LOG_FILE
    log "Gathering logs for diagnosis..."
    if [ "$(id -u)" -eq 0 ]; then
      docker-compose logs --tail=100 nginx >> $LOG_FILE 2>&1
      docker-compose logs --tail=100 wordpress-prod >> $LOG_FILE 2>&1
    else
      sudo -E docker-compose logs --tail=100 nginx >> $LOG_FILE 2>&1
      sudo -E docker-compose logs --tail=100 wordpress-prod >> $LOG_FILE 2>&1
    fi
    error_exit "HTTPS test failed after retry: status $https_status"
  else
    log "HTTPS connection successful after retry (status: $https_status)"
    cat "$HTTPS_TEST_LOG" >> $LOG_FILE
  fi
else
  log "HTTPS connection successful (status: $https_status)"
  cat "$HTTPS_TEST_LOG" >> $LOG_FILE
fi

# List certificates for verification
log "Listing installed certificates:"
if [ "$(id -u)" -eq 0 ]; then
  docker-compose exec -T certbot certbot certificates 2>&1 | tee -a $LOG_FILE
else
  sudo -E docker-compose exec -T certbot certbot certificates 2>&1 | tee -a $LOG_FILE
fi

log "SSL setup complete for $DOMAIN_NAME!"
log "Your site should now be accessible at: https://$DOMAIN_NAME"
log "You can verify certificate status with: docker-compose exec certbot certbot certificates"
log "Certificates will be automatically renewed by the certbot container."
log "If you encounter SSL issues, check the log file at: $LOG_FILE"

# Summary of commands for troubleshooting
log "=== Troubleshooting commands ==="
log "Check certificate status: docker-compose exec certbot certbot certificates"
log "Test Nginx config: docker-compose exec nginx nginx -t"
log "View Nginx config: docker-compose exec nginx nginx -T"
log "Check SSL certificates: ls -la $(pwd)/nginx/ssl/live/$DOMAIN_NAME/"
log "Verify HTTP access: curl -sI http://$DOMAIN_NAME/.well-known/acme-challenge/test"
log "Force Nginx reload: docker-compose exec nginx nginx -s reload"