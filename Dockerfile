# Multi-stage Dockerfile for development and production

###################
# Production stage - FIRST for better caching
###################
FROM wordpress:6.4-apache AS production

# Labels for maintainability
LABEL maintainer="YourName <your.email@example.com>"
LABEL description="WordPress with BuddyPress and BuddyX theme - Production Ready"
LABEL version="1.0"

# Run as root for setup
USER root

# Install only the minimal required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget unzip && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Install WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp && \
    # Verify the download
    wp --info

# Download and extract BuddyPress plugin and BuddyX theme
RUN mkdir -p /usr/src/wordpress/wp-content/plugins /usr/src/wordpress/wp-content/themes && \
    wget https://downloads.wordpress.org/plugin/buddypress.latest-stable.zip -O buddypress.zip && \
    unzip buddypress.zip -d /usr/src/wordpress/wp-content/plugins && \
    rm buddypress.zip && \
    wget https://downloads.wordpress.org/theme/buddyx.latest-stable.zip -O buddyx.zip && \
    unzip buddyx.zip -d /usr/src/wordpress/wp-content/themes && \
    rm buddyx.zip

# Copy only production scripts
COPY setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Copy only production scripts from devscripts
COPY devscripts/ally-content /usr/local/bin/devscripts/ally-content
COPY devscripts/simple-gamification.css /usr/local/bin/devscripts/simple-gamification.css
COPY devscripts/simple-gamification.js /usr/local/bin/devscripts/simple-gamification.js
COPY devscripts/simple-gamification.php /usr/local/bin/devscripts/simple-gamification.php

# Set proper ownership for WordPress files
RUN chown -R www-data:www-data /var/www/html /usr/src/wordpress

# Security hardening
RUN \
    # Remove default Apache configs that could be security issues
    a2dismod -f autoindex && \
    # Set proper file permissions
    find /var/www/html -type d -exec chmod 755 {} \; && \
    find /var/www/html -type f -exec chmod 644 {} \;

# Configure Apache
COPY <<'EOT' /etc/apache2/conf-available/security.conf
ServerTokens Prod
ServerSignature Off
TraceEnable Off
EOT

RUN a2enconf security

# Switch to non-root user for runtime
USER www-data

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wp core is-installed --allow-root || exit 1

###################
# Development stage
###################
FROM wordpress:6.4 AS development

# Run as root for package installation
USER root

# Install necessary packages including default-mysql-client for mysqlcheck
RUN apt-get update && apt-get install -y wget unzip default-mysql-client

# Install WP‑CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Download and extract BuddyPress plugin into the source plugins directory
RUN mkdir -p /usr/src/wordpress/wp-content/plugins && \
    wget https://downloads.wordpress.org/plugin/buddypress.latest-stable.zip -O buddypress.zip && \
    unzip buddypress.zip -d /usr/src/wordpress/wp-content/plugins && \
    rm buddypress.zip

# Download and extract BuddyX theme into the source themes directory
RUN mkdir -p /usr/src/wordpress/wp-content/themes && \
    wget https://downloads.wordpress.org/theme/buddyx.latest-stable.zip -O buddyx.zip && \
    unzip buddyx.zip -d /usr/src/wordpress/wp-content/themes && \
    rm buddyx.zip

# Copy the automated setup script into the image
COPY setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Copy the devscripts directory
COPY devscripts /usr/local/bin/devscripts
RUN chmod +x /usr/local/bin/devscripts/demo-content.sh

# Switch to non‑root user provided by the official WordPress image
USER www-data
