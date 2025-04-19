#!/bin/bash
set -e

#region INITIALIZATION
######################
### INITIALIZATION ###
######################

# Log file
LOG_FILE="/tmp/enhanced-boot.log"

echo "=== ENHANCED BOOT SCRIPT STARTING at $(date) ===" > $LOG_FILE
echo "Running as user: $(whoami)" >> $LOG_FILE
echo "Hostname: $(hostname)" >> $LOG_FILE

# Production setup - no user detection needed
echo "Setting up Docker for production use with sudo access" >> $LOG_FILE

# SCRIPT VARIABLES
# Uncomment variables as needed for your environment
# Name of the user to create and grant sudo privileges
# USERNAME=jane_doe

# IP Address and port for accessing SSH (security)
# IP_ADDRESS=0.0.000.000
# SSH_PORT=2222

# cidr block for accessing SSH via Virtual Private Cloud
# aws_VPC=10.0.0.0/24

# Ports for services
WP_PORT=80
WP_SECURE_PORT=443

# Ports for development
# DEV_PORT=3000
# STORY_PORT=9009

# Database settings for WordPress
# WP_DB_ROOT_PASSWORD="wordpress_db_root_password"
# WP_DB_NAME="wordpress"
# WP_DB_USER="wordpress"
# WP_DB_PASSWORD="wordpress_db_password"

# Repository settings
# REPO_DIR="/opt/repositories"
# REPO_URL="https://github.com/TortoiseWolfe/Tech_Blog.git"

# Set TimeZone
TIMEZONE="America/New_York"
echo "Setting timezone to ${TIMEZONE}" >> $LOG_FILE
timedatectl set-timezone ${TIMEZONE}
#endregion

#region SYSTEM PREPARATION
##########################
### SYSTEM PREPARATION ###
##########################

# Function to wait for apt locks to be released with extended timeout
wait_for_apt() {
    echo "Checking for apt locks..." >> $LOG_FILE
    
    # Wait up to 30 minutes on first boot (common for cloud instances to run initial updates)
    for i in $(seq 1 180); do  # 180 tries * 10 seconds = 30 minutes
        if lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || lsof /var/lib/apt/lists/lock >/dev/null 2>&1 || lsof /var/cache/apt/archives/lock >/dev/null 2>&1; then
            echo "Waiting for apt locks to be released (attempt $i/180)... waiting 10 seconds" >> $LOG_FILE
            sleep 10
        else
            echo "Apt locks released, proceeding..." >> $LOG_FILE
            return 0
        fi
    done
    
    echo "ERROR: Timed out waiting for apt locks after 30 minutes" >> $LOG_FILE
    echo "Checking which processes are holding the locks:" >> $LOG_FILE
    lsof /var/lib/dpkg/lock-frontend >> $LOG_FILE 2>&1 || true
    lsof /var/lib/apt/lists/lock >> $LOG_FILE 2>&1 || true
    lsof /var/cache/apt/archives/lock >> $LOG_FILE 2>&1 || true
    echo "Running package processes:" >> $LOG_FILE
    ps aux | grep -E 'apt|dpkg' | grep -v grep >> $LOG_FILE || true
    
    # Return failure but continue with script
    return 1
}

# Update packages with robust retry mechanism
echo "Updating package lists" >> $LOG_FILE

# Function to retry apt operations
retry_apt_operation() {
    local cmd="$1"
    local desc="$2"
    local max_attempts=5
    local wait_time=30
    
    echo "Starting $desc..." >> $LOG_FILE
    
    for attempt in $(seq 1 $max_attempts); do
        echo "Attempt $attempt/$max_attempts for $desc" >> $LOG_FILE
        
        # Wait for apt locks
        wait_for_apt || { 
            echo "WARNING: Could not acquire apt locks, but trying anyway" >> $LOG_FILE
        }
        
        # Run the command
        eval "$cmd" >> $LOG_FILE 2>&1
        
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "SUCCESS: $desc completed on attempt $attempt" >> $LOG_FILE
            return 0
        else
            echo "ERROR: $desc failed with exit code $exit_code on attempt $attempt" >> $LOG_FILE
            
            if [ $attempt -lt $max_attempts ]; then
                echo "Waiting $wait_time seconds before next attempt..." >> $LOG_FILE
                sleep $wait_time
            else
                echo "FAILED: $desc failed after $max_attempts attempts" >> $LOG_FILE
            fi
        fi
    done
    
    return 1
}

# Update package lists with retries
retry_apt_operation "apt-get update -y" "package list update" || {
    echo "WARNING: Package update failed, will continue anyway" >> $LOG_FILE
}

# Install essential packages with retries
echo "Installing essential packages" >> $LOG_FILE
retry_apt_operation "apt-get -y install apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release" "essential packages installation" || {
    echo "WARNING: Essential package installation failed, will continue anyway" >> $LOG_FILE
    echo "Available packages:" >> $LOG_FILE
    apt-cache policy apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release >> $LOG_FILE 2>&1
}
#endregion

#region SWAP CONFIGURATION
##########################
### SWAP CONFIGURATION ###
##########################

# Create and optimize swap file
SWAP_SIZE=8  # Increased to 8GB for better performance
echo "Creating ${SWAP_SIZE}GB swap file" >> $LOG_FILE
if [ ! -f /swapfile ]; then
    echo "Creating new swap file..." >> $LOG_FILE
    fallocate -l ${SWAP_SIZE}G /swapfile >> $LOG_FILE 2>&1 || {
        echo "ERROR: fallocate failed with exit code $?" >> $LOG_FILE
        echo "Trying dd method instead" >> $LOG_FILE
        dd if=/dev/zero of=/swapfile bs=1G count=${SWAP_SIZE} >> $LOG_FILE 2>&1 || {
            echo "ERROR: dd swap creation failed with exit code $?" >> $LOG_FILE
            ls -la / >> $LOG_FILE
            df -h >> $LOG_FILE
        }
    }
    
    echo "Setting swap file permissions" >> $LOG_FILE
    chmod 600 /swapfile >> $LOG_FILE 2>&1 || echo "ERROR: chmod on swapfile failed with $?" >> $LOG_FILE
    
    echo "Setting up swap" >> $LOG_FILE
    mkswap /swapfile >> $LOG_FILE 2>&1 || echo "ERROR: mkswap failed with $?" >> $LOG_FILE
    swapon /swapfile >> $LOG_FILE 2>&1 || echo "ERROR: swapon failed with $?" >> $LOG_FILE
    
    echo "Adding swap to fstab" >> $LOG_FILE
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
else
    echo "Swap file already exists, checking if resizing is needed..." >> $LOG_FILE
    CURRENT_SWAP_SIZE=$(du -h /swapfile | awk '{print $1}' | tr -d 'G')
    if (( $(echo "$CURRENT_SWAP_SIZE < $SWAP_SIZE" | bc -l) )); then
        echo "Resizing swap file from ${CURRENT_SWAP_SIZE}GB to ${SWAP_SIZE}GB" >> $LOG_FILE
        swapoff /swapfile
        rm /swapfile
        fallocate -l ${SWAP_SIZE}G /swapfile || dd if=/dev/zero of=/swapfile bs=1G count=${SWAP_SIZE}
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
    else
        echo "Current swap size is adequate, no resize needed" >> $LOG_FILE
    fi
fi

# Optimize swap settings for better performance
echo "Optimizing swap settings for memory-intensive operations" >> $LOG_FILE
# Lower swappiness for server workloads
echo "vm.swappiness=5" > /etc/sysctl.d/99-swap-settings.conf
# Reduce cache pressure
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-swap-settings.conf
# Add additional memory management settings
echo "vm.dirty_background_ratio=5" >> /etc/sysctl.d/99-swap-settings.conf
echo "vm.dirty_ratio=10" >> /etc/sysctl.d/99-swap-settings.conf
# Increase max map count for high memory operations
echo "vm.max_map_count=262144" >> /etc/sysctl.d/99-swap-settings.conf

# Apply settings
sysctl -p /etc/sysctl.d/99-swap-settings.conf >> $LOG_FILE 2>&1 || echo "ERROR: sysctl failed with $?" >> $LOG_FILE

echo "Swap status:" >> $LOG_FILE
swapon --show >> $LOG_FILE 2>&1
free -h >> $LOG_FILE 2>&1
#endregion

#region DOCKER INSTALLATION
###########################
### DOCKER INSTALLATION ###
###########################

# Install Docker
echo "Installing Docker" >> $LOG_FILE
if ! command -v docker &> /dev/null; then
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        echo "Detected OS: $OS" >> $LOG_FILE
    else
        OS="unknown"
        echo "Could not detect OS, defaulting to unknown" >> $LOG_FILE
    fi
    
    # Add Docker official GPG key
    echo "Adding Docker GPG key" >> $LOG_FILE
    curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>> $LOG_FILE || {
        echo "ERROR: Docker GPG key installation failed with exit code $?" >> $LOG_FILE
    }
    
    # Set up the stable repository based on OS
    echo "Setting up Docker repository for $OS" >> $LOG_FILE
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    echo "Updating package lists for Docker" >> $LOG_FILE
    wait_for_apt || { echo "ERROR: Could not acquire apt locks, continuing anyway" >> $LOG_FILE; }
    apt-get update >> $LOG_FILE 2>&1 || {
        echo "ERROR: apt-get update for Docker failed with exit code $?" >> $LOG_FILE
        cat /var/log/apt/term.log >> $LOG_FILE 2>/dev/null || echo "Could not read apt term log" >> $LOG_FILE
    }
    
    echo "Installing Docker packages" >> $LOG_FILE
    wait_for_apt || { echo "ERROR: Could not acquire apt locks, continuing anyway" >> $LOG_FILE; }
    
    # Try installing Docker with multiple attempts
    for attempt in {1..3}; do
        echo "Attempting to install Docker (attempt $attempt/3)" >> $LOG_FILE
        if apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin >> $LOG_FILE 2>&1; then
            echo "Docker installation succeeded on attempt $attempt" >> $LOG_FILE
            break
        else
            echo "ERROR: Docker installation failed with exit code $? on attempt $attempt" >> $LOG_FILE
            cat /var/log/apt/term.log >> $LOG_FILE 2>/dev/null || echo "Could not read apt term log" >> $LOG_FILE
            if [ $attempt -eq 3 ]; then
                echo "ERROR: Docker installation failed after 3 attempts" >> $LOG_FILE
            else
                echo "Waiting 30 seconds before next attempt..." >> $LOG_FILE
                sleep 30
                wait_for_apt || { echo "ERROR: Could not acquire apt locks, continuing anyway" >> $LOG_FILE; }
            fi
        fi
    done
    
    # Start and enable Docker
    echo "Starting and enabling Docker service" >> $LOG_FILE
    systemctl enable docker >> $LOG_FILE 2>&1 || echo "ERROR: Docker enable failed with $?" >> $LOG_FILE
    systemctl start docker >> $LOG_FILE 2>&1 || echo "ERROR: Docker start failed with $?" >> $LOG_FILE
    
    # Create docker group but don't add users (production security practice)
    echo "Creating docker group (but not adding users for security)" >> $LOG_FILE
    groupadd -f docker >> $LOG_FILE 2>&1 || echo "Docker group already exists" >> $LOG_FILE
    
    # Install Docker Compose
    echo "Installing Docker Compose" >> $LOG_FILE
    wait_for_apt || { echo "ERROR: Could not acquire apt locks, continuing anyway" >> $LOG_FILE; }
    apt-get -y install docker-compose-plugin >> $LOG_FILE 2>&1 || echo "ERROR: Docker Compose installation failed with $?" >> $LOG_FILE
    
    # Create a symlink for backwards compatibility
    ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose 2>> $LOG_FILE || echo "ERROR: Docker Compose symlink failed with $?" >> $LOG_FILE
    
    echo "Docker status:" >> $LOG_FILE
    systemctl status docker | head -20 >> $LOG_FILE 2>&1
    docker --version >> $LOG_FILE 2>&1 || echo "ERROR: Docker version check failed with $?" >> $LOG_FILE
fi
#endregion

#region SECURITY HARDENING
#########################
### SECURITY HARDENING ###
#########################

# TO BE IMPLEMENTED
# This section should include:
# - Installing PAM (Pluggable Authentication Modules)
# - Configure password policies
# - Configure SSH group and settings
# - Disable root SSH login
# - Turn off the Message of the Day
# - Reload SSH service if configuration is valid

echo "Security hardening section needs implementation" >> $LOG_FILE

# Example implementations (commented out for future use):
# Install PAM (Pluggable Authentication Modules)
# apt-get -y install libpam-cracklib

# Configure password policies
# if ! grep -q "pam_pwhistory.so remember=99" /etc/pam.d/common-password; then
#     echo 'password required pam_pwhistory.so remember=99 use_authok' >> /etc/pam.d/common-password
# fi

# Configure SSH group and settings
# groupadd -f sshusers
# usermod -aG sshusers "${USERNAME}"

# Update SSH configuration
# if ! grep -q "^Port ${SSH_PORT}" /etc/ssh/sshd_config; then
#     echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
# fi
#endregion

#region FIREWALL SETUP
#####################
### FIREWALL SETUP ###
#####################

# TO BE IMPLEMENTED
# This section should include:
# - Configure and enable UFW firewall
# - Clear existing rules
# - Add firewall rules for SSH, web services
# - Enable firewall
# - Install and configure Fail2Ban

echo "Firewall setup section needs implementation" >> $LOG_FILE

# Example implementations (commented out for future use):
# Configure and enable UFW firewall
# sed --in-place 's/IPV6=no/IPV6=yes/' /etc/default/ufw

# Clear existing rules
# ufw --force reset

# Add firewall rules
# ufw allow proto tcp from "${IP_ADDRESS}" to any port "${SSH_PORT}"
# ufw allow proto tcp from "${aws_VPC}" to any port "${SSH_PORT}"
# ufw allow "${WP_PORT}"/tcp
# ufw allow "${WP_SECURE_PORT}"/tcp
#endregion

#region USER CONFIGURATION
#########################
### USER CONFIGURATION ###
#########################

# Customize TTY prompt for all users
echo "Customizing TTY prompt" >> $LOG_FILE
sed -i 's/#force_color_prompt=yes/ force_color_prompt=yes/' /etc/skel/.bashrc
sed -i 's/\\\[\\033\[01;32m\\\]\\u@\\h\\\[\\033\[00m\\\]:\\\[\\033\[01;34m\\\]\\w\\\[\\033\[00m\\\]\\\$ /\\n\\@ \\\[\\e\[32;40m\\\]\\u\\\[\\e\[m\\\] \\\[\\e\[32;40m\\\]@\\\[\\e\[m\\\]\\n \\\[\\e\[32;40m\\\]\\H\\\[\\e\[m\\\] \\\[\\e\[36;40m\\\]\\w\\\[\\e\[m\\\] \\\[\\e\[33m\\\]\\\\\$\\\[\\e\[m\\\] /' /etc/skel/.bashrc

# Apply to current users' .bashrc files as well
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        if [ -f "$user_home/.bashrc" ]; then
            echo "Updating prompt for user $username" >> $LOG_FILE
            sed -i 's/#force_color_prompt=yes/ force_color_prompt=yes/' "$user_home/.bashrc"
            sed -i 's/\\\[\\033\[01;32m\\\]\\u@\\h\\\[\\033\[00m\\\]:\\\[\\033\[01;34m\\\]\\w\\\[\\033\[00m\\\]\\\$ /\\n\\@ \\\[\\e\[32;40m\\\]\\u\\\[\\e\[m\\\] \\\[\\e\[32;40m\\\]@\\\[\\e\[m\\\]\\n \\\[\\e\[32;40m\\\]\\H\\\[\\e\[m\\\] \\\[\\e\[36;40m\\\]\\w\\\[\\e\[m\\\] \\\[\\e\[33m\\\]\\\\\$\\\[\\e\[m\\\] /' "$user_home/.bashrc"
            chown $username:$username "$user_home/.bashrc"
        fi
    fi
done

# TO BE IMPLEMENTED
# Additional user configuration:
# - Add sudo user and grant privileges
# - Set up SSH keys
# - Configure user permissions
#endregion

#region WORDPRESS SETUP
######################
### WORDPRESS SETUP ###
######################

# TO BE IMPLEMENTED
# This section should include:
# - Create directory structure for WordPress
# - Create a sample docker-compose.yml for WordPress
# - Create PHP configuration for uploads
# - Set permissions

echo "WordPress setup section needs implementation" >> $LOG_FILE

# Example implementations (commented out for future use):
# Create directory structure for WordPress
# echo "Setting up WordPress directory structure..."
# mkdir -p ${WP_DIR}/{data,config,logs}
# chown -R "${USERNAME}":docker ${WP_DIR}

# Create a sample docker-compose.yml for WordPress
# cat > ${WP_DIR}/docker-compose.yml << EOF
# version: '3'
#
# services:
#   db:
#     image: mariadb:10.11
#     volumes:
#       - ./data/db:/var/lib/mysql
#     restart: always
#     environment:
#       MYSQL_ROOT_PASSWORD: ${WP_DB_ROOT_PASSWORD}
#       MYSQL_DATABASE: ${WP_DB_NAME}
#       MYSQL_USER: ${WP_DB_USER}
#       MYSQL_PASSWORD: ${WP_DB_PASSWORD}
#     networks:
#       - wordpress-network
#
#   wordpress:
#     image: wordpress:latest
#     depends_on:
#       - db
#     volumes:
#       - ./data/wp-content:/var/www/html/wp-content
#       - ./config/uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
#     restart: always
#     environment:
#       WORDPRESS_DB_HOST: db
#       WORDPRESS_DB_USER: ${WP_DB_USER}
#       WORDPRESS_DB_PASSWORD: ${WP_DB_PASSWORD}
#       WORDPRESS_DB_NAME: ${WP_DB_NAME}
#     ports:
#       - "${WP_PORT}:80"
#     networks:
#       - wordpress-network
#
# networks:
#   wordpress-network:
#     external: true
# EOF
#endregion

#region GIT REPOSITORY SETUP
##########################
### GIT REPOSITORY SETUP ###
##########################

# TO BE IMPLEMENTED
# This section should include:
# - Install Git
# - Configure basic Git settings for the user
# - Create directory for repository
# - Create a note about Git configuration

echo "Git repository setup section needs implementation" >> $LOG_FILE

# Example implementations (commented out for future use):
# Install Git
# echo "Installing Git..."
# apt-get -y install git
#endregion

#region COMPLETION
#################
### COMPLETION ###
#################

echo "=== ENHANCED BOOT SCRIPT COMPLETED at $(date) ===" >> $LOG_FILE
echo "Final system status:" >> $LOG_FILE
df -h >> $LOG_FILE
free -h >> $LOG_FILE

# Verify Docker installation
if command -v docker &> /dev/null; then
    echo "Docker installation SUCCESSFUL" >> $LOG_FILE
    docker --version >> $LOG_FILE 2>&1
    systemctl status docker --no-pager >> $LOG_FILE 2>&1 || true
else
    echo "WARNING: Docker command not available after installation" >> $LOG_FILE
    echo "Attempting to fix..." >> $LOG_FILE
    
    # Final attempt to install Docker directly
    wait_for_apt || { echo "ERROR: Could not acquire apt locks, continuing anyway" >> $LOG_FILE; }
    apt-get update >> $LOG_FILE 2>&1
    wait_for_apt || { echo "ERROR: Could not acquire apt locks, continuing anyway" >> $LOG_FILE; }
    apt-get install -y docker.io >> $LOG_FILE 2>&1
    
    # Check again
    if command -v docker &> /dev/null; then
        echo "Docker installation SUCCESSFUL with fallback method" >> $LOG_FILE
        docker --version >> $LOG_FILE 2>&1
    else
        echo "ERROR: Docker installation FAILED even after fallback" >> $LOG_FILE
    fi
fi

# Create .env file in /var/www/wp-dev directory
echo "Creating .env file for production" >> $LOG_FILE

# Create directory if it doesn't exist
mkdir -p /var/www/wp-dev
cat > /var/www/wp-dev/.env << 'EOF'
# MySQL credentials
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress

# WordPress database connection
WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=wordpress
WORDPRESS_DB_NAME=wordpress

# WordPress installation settings
WP_SITE_URL=http://localhost:80
WP_SITE_TITLE="My WordPress Site"
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com

# GitHub Container Registry access
# Generate a token with 'read:packages' permission at:
# https://github.com/settings/tokens/new
GITHUB_TOKEN=your_github_personal_access_token_here
EOF

# Set proper permissions
chmod 600 /var/www/wp-dev/.env
echo "Created .env file with default values in /var/www/wp-dev/" >> $LOG_FILE
echo "Note: Users can edit this file with: sudo nano /var/www/wp-dev/.env" >> $LOG_FILE

# Create a marker file to indicate completion
touch /tmp/enhanced-boot-completed

# Simple completion message 
echo "Script completed successfully at $(date). Check $LOG_FILE for details."
#endregion
