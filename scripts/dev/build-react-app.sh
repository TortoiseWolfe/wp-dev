#!/bin/bash
# Script to build the ReactPress metronome app

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
METRONOME_APP_DIR="$PROJECT_ROOT/devscripts/metronome-app"

echo "========================================="
echo "Building ScriptHammer React Metronome App"
echo "========================================="

# Check if the directory exists
if [ ! -d "$METRONOME_APP_DIR" ]; then
  echo "❌ ERROR: Metronome app directory not found at $METRONOME_APP_DIR"
  exit 1
fi

# Check if we're in a Docker environment
if [ -f /.dockerenv ]; then
  echo "Running inside Docker container"
  # Install Node.js and npm if not already installed
  if ! command -v node &> /dev/null; then
    echo "Installing Node.js and npm..."
    apt-get update && apt-get install -y nodejs npm
  fi
else
  echo "Running on host machine"
  # Check if Node.js is installed
  if ! command -v node &> /dev/null; then
    echo "❌ ERROR: Node.js is not installed. Please install Node.js before continuing."
    exit 1
  fi
fi

# Change to the metronome app directory
cd "$METRONOME_APP_DIR"

# Install dependencies
echo "Installing dependencies..."
npm install

# Build the app
echo "Building React app..."
npm run build

# Check if build was successful
if [ ! -d "build" ]; then
  echo "❌ ERROR: Build failed. No build directory created."
  exit 1
fi

# Create the ReactPress apps directory in WordPress if we're running in Docker
if [ -f /.dockerenv ] && [ -d "/var/www/html" ]; then
  echo "Creating ReactPress apps directory in WordPress..."
  mkdir -p /var/www/html/wp-content/plugins/reactpress/apps/scripthammer-app
  
  # Copy the build files
  echo "Copying build files to WordPress ReactPress directory..."
  cp -r build/* /var/www/html/wp-content/plugins/reactpress/apps/scripthammer-app/
  
  # Set proper ownership
  chown -R www-data:www-data /var/www/html/wp-content/plugins/reactpress
  
  echo "✅ React app built and deployed to WordPress ReactPress plugins directory"
else
  echo "✅ React app built successfully. Build files are in $METRONOME_APP_DIR/build"
  echo "To deploy, copy these files to your WordPress ReactPress plugins directory:"
  echo "cp -r build/* /path/to/wordpress/wp-content/plugins/reactpress/apps/scripthammer-app/"
fi

echo "Done!"