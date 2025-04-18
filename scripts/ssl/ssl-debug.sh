#!/bin/bash

# SSL Debug Script - Logs certificate status and renewal attempts
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="$BASE_DIR/logs"
NGINX_DIR="$BASE_DIR/nginx"

# Load domain from .env
ENV_FILE="$BASE_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  DOMAIN_NAME=$(grep -E "^DOMAIN_NAME=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'")
  if [ -z "$DOMAIN_NAME" ]; then
    WP_SITE_URL=$(grep -E "^WP_SITE_URL=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'")
    if [ -n "$WP_SITE_URL" ]; then
      DOMAIN_NAME=$(echo "$WP_SITE_URL" | sed "s|https://||" | sed "s|http://||" | sed "s|/||g")
    fi
  fi
else
  echo "Error: .env file not found at $ENV_FILE"
  exit 1
fi

if [ -z "$DOMAIN_NAME" ]; then
  DOMAIN_NAME="scripthammer.com" # Default fallback
  echo "Warning: No domain name found in .env, using default: $DOMAIN_NAME"
fi

LOG_FILE="$LOG_DIR/ssl-debug.log"
CERT_DIR="$NGINX_DIR/ssl/live/$DOMAIN_NAME"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo "[$(date)] ===== SSL DEBUG LOG =====" >> $LOG_FILE

# Check current certificate info
echo "[$(date)] Current certificate details:" >> $LOG_FILE
openssl x509 -in $CERT_DIR/fullchain.pem -text -noout | grep -E "Issuer:|Subject:|Not Before:|Not After:" >> $LOG_FILE 2>&1

# Check if certificate is self-signed
ISSUER=$(openssl x509 -in $CERT_DIR/fullchain.pem -issuer -noout | sed 's/^issuer=//')
SUBJECT=$(openssl x509 -in $CERT_DIR/fullchain.pem -subject -noout | sed 's/^subject=//')
echo "[$(date)] Checking if self-signed..." >> $LOG_FILE
if [ "$ISSUER" = "$SUBJECT" ]; then
    echo "[$(date)] Certificate IS self-signed. Needs renewal with Let's Encrypt." >> $LOG_FILE
else
    echo "[$(date)] Certificate is NOT self-signed. Issued by valid CA." >> $LOG_FILE
fi

# Test domain DNS resolution
echo "[$(date)] Testing domain DNS resolution:" >> $LOG_FILE
dig +short $DOMAIN_NAME >> $LOG_FILE 2>&1
dig +short www.$DOMAIN_NAME >> $LOG_FILE 2>&1

# Test port 80 accessibility (important for Let's Encrypt HTTP validation)
echo "[$(date)] Testing port 80 accessibility:" >> $LOG_FILE
curl -s -I -m 10 http://$DOMAIN_NAME/.well-known/acme-challenge/test >> $LOG_FILE 2>&1

# Check Nginx configuration
echo "[$(date)] Checking Nginx configuration:" >> $LOG_FILE
docker-compose -f "$BASE_DIR/docker-compose.yml" exec -T nginx nginx -t >> $LOG_FILE 2>&1

# Log information about docker containers
echo "[$(date)] Docker container status:" >> $LOG_FILE
docker-compose -f "$BASE_DIR/docker-compose.yml" ps nginx certbot >> $LOG_FILE 2>&1

echo "[$(date)] ===== END DEBUG LOG =====" >> $LOG_FILE
echo "" >> $LOG_FILE

# Run certbot renewal attempt directly
echo "[$(date)] Running certbot renewal attempt:" >> $LOG_FILE
cd "$BASE_DIR"
sudo -E docker-compose exec -T certbot certbot certonly --webroot --webroot-path /var/www/certbot -d $DOMAIN_NAME -d www.$DOMAIN_NAME --register-unsafely-without-email --non-interactive --agree-tos --force-renewal >> $LOG_FILE 2>&1

echo "[$(date)] Debug script completed" >> $LOG_FILE