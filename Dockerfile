# Dockerfile
FROM wordpress:latest

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
