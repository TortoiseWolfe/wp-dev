# Dockerfile
FROM wordpress:latest

# Run as root for package installation
USER root

# Install necessary packages
RUN apt-get update && apt-get install -y wget unzip

# Install WP‑CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Download and extract BuddyPress plugin into the source plugins directory
RUN mkdir -p /usr/src/wordpress/wp-content/plugins && \
    wget https://downloads.wordpress.org/plugin/buddypress.latest-stable.zip -O buddypress.zip && \
    unzip buddypress.zip -d /usr/src/wordpress/wp-content/plugins && \
    rm buddypress.zip

# Copy the automated setup script into the image
COPY setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Switch to non‑root user for running WordPress commands
USER www-data
