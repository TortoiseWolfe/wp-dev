#!/bin/bash

# SSL Debug Script - Logs certificate status and renewal attempts
LOG_FILE="/home/jonpohlner/wp-dev/logs/ssl-debug.log"
CERT_DIR="/home/jonpohlner/wp-dev/nginx/ssl/live/scripthammer.com"

# Create logs directory if it doesn't exist
mkdir -p /home/jonpohlner/wp-dev/logs

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
dig +short scripthammer.com >> $LOG_FILE 2>&1
dig +short www.scripthammer.com >> $LOG_FILE 2>&1

# Test port 80 accessibility (important for Let's Encrypt HTTP validation)
echo "[$(date)] Testing port 80 accessibility:" >> $LOG_FILE
curl -s -I -m 10 http://scripthammer.com/.well-known/acme-challenge/test >> $LOG_FILE 2>&1

# Check Nginx configuration
echo "[$(date)] Checking Nginx configuration:" >> $LOG_FILE
docker exec wp-dev-nginx-1 nginx -t >> $LOG_FILE 2>&1

# Log information about docker containers
echo "[$(date)] Docker container status:" >> $LOG_FILE
docker ps | grep -E "nginx|certbot" >> $LOG_FILE 2>&1

echo "[$(date)] ===== END DEBUG LOG =====" >> $LOG_FILE
echo "" >> $LOG_FILE

# Run certbot renewal attempt directly
cd /home/jonpohlner/wp-dev
echo "[$(date)] Running certbot renewal attempt:" >> $LOG_FILE
sudo -E docker-compose exec certbot certbot certonly --webroot --webroot-path /var/www/certbot -d scripthammer.com -d www.scripthammer.com --register-unsafely-without-email --non-interactive --agree-tos --force-renewal >> $LOG_FILE 2>&1

echo "[$(date)] Debug script completed" >> $LOG_FILE