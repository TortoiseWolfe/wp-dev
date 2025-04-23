#!/bin/bash
# Complete rebuild script for local development environment

echo "================================"
echo "🧹 COMPLETE REBUILD SCRIPT 🧹"
echo "================================"
echo "This script will completely rebuild your development environment from scratch."
echo "All containers, volumes, and data will be removed."
echo ""
echo "⚠️  WARNING: This will DELETE ALL your WordPress data and start fresh!"
echo "================================"

# Ask for confirmation
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Rebuild cancelled."
  exit 0
fi

# Current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

echo "Step 1: Stopping and removing all containers..."
cd $PROJECT_ROOT
docker-compose down -v

echo "Step 2: Cleaning up Docker resources..."
# Remove any orphaned containers with the project name
COMPOSE_PROJECT=$(basename "$PROJECT_ROOT")
docker ps -a | grep $COMPOSE_PROJECT | awk '{print $1}' | xargs -r docker rm -f
# Remove volumes with the project name
docker volume ls | grep $COMPOSE_PROJECT | awk '{print $2}' | xargs -r docker volume rm

echo "Step 3: Running setup-local-dev.sh to generate new credentials..."
cd $PROJECT_ROOT
source ./scripts/dev/setup-local-dev.sh

echo "Step 4: Starting development environment..."
docker-compose up -d wordpress wp-setup db

echo "Step 5: Watching logs to monitor setup progress..."
echo "Press Ctrl+C when setup is complete (you see 'WordPress init process complete')"
docker-compose logs -f wordpress wp-setup

echo ""
echo "Step 6: Ensuring ReactPress integration is working correctly..."
# Wait briefly for WordPress to be fully initialized
sleep 5

# Install the Metronome app - CRITICAL COMPONENT
echo "Installing Metronome app in mu-plugins directory..."
docker-compose exec wordpress bash -c "
  # Create the directory if it doesn't exist
  mkdir -p /var/www/html/wp-content/mu-plugins && \
  
  # Copy the metronome app
  cp /usr/local/bin/devscripts/metronome-app.php /var/www/html/wp-content/mu-plugins/metronome-app.php && \
  chmod 644 /var/www/html/wp-content/mu-plugins/metronome-app.php && \
  chown -R www-data:www-data /var/www/html/wp-content/mu-plugins && \
  
  # Verify shortcode is registered
  wp eval 'global \$shortcode_tags; echo \"Shortcode status: \" . (isset(\$shortcode_tags[\"scripthammer_react_app\"]) ? \"✅ registered\" : \"❌ NOT registered\");' --path=/var/www/html && \
  
  # Force WordPress to load the plugin if not already loaded
  wp eval 'if (!function_exists(\"render_scripthammer_react_placeholder\")) { include_once(\"/var/www/html/wp-content/mu-plugins/metronome-app.php\"); echo \"Metronome app loaded manually\"; }' --path=/var/www/html
"

# Now also install the simple-gamification plugin correctly
echo "Installing simple-gamification plugin with proper directory structure..."
docker-compose exec wordpress bash -c "
  # Create plugin directory
  mkdir -p /var/www/html/wp-content/plugins/simple-gamification && \
  
  # Copy the PHP file
  cp /usr/local/bin/devscripts/simple-gamification.php /var/www/html/wp-content/plugins/simple-gamification/simple-gamification.php && \
  chmod 644 /var/www/html/wp-content/plugins/simple-gamification/simple-gamification.php && \
  
  # Copy the JS file if it exists
  if [ -f '/usr/local/bin/devscripts/simple-gamification.js' ]; then
    cp /usr/local/bin/devscripts/simple-gamification.js /var/www/html/wp-content/plugins/simple-gamification/simple-gamification.js && \
    chmod 644 /var/www/html/wp-content/plugins/simple-gamification/simple-gamification.js && \
    echo '✅ Added JS file to simple-gamification plugin';
  else
    echo '⚠️ Warning: simple-gamification.js not found';
  fi && \
  
  # Copy the CSS file if it exists
  if [ -f '/usr/local/bin/devscripts/simple-gamification.css' ]; then
    cp /usr/local/bin/devscripts/simple-gamification.css /var/www/html/wp-content/plugins/simple-gamification/simple-gamification.css && \
    chmod 644 /var/www/html/wp-content/plugins/simple-gamification/simple-gamification.css && \
    echo '✅ Added CSS file to simple-gamification plugin';
  else
    echo '⚠️ Warning: simple-gamification.css not found';
  fi && \
  
  # Set proper ownership
  chown -R www-data:www-data /var/www/html/wp-content/plugins/simple-gamification && \
  
  # Activate the plugin (prioritize directory version)
  wp plugin activate simple-gamification/simple-gamification --path=/var/www/html || \
  wp plugin activate simple-gamification --path=/var/www/html && \
  echo '✅ Simple gamification plugin installed and activated'
"
  
# Also run the React app build script if we want to build the full React app
# echo "Building React metronome app (uncomment when ready for production)..."
# docker-compose exec wordpress bash -c "cd /usr/local/bin/scripts/dev && ./build-react-app.sh"

# Set up metronome-app placeholder image directory
echo "Setting up metronome-app placeholder image..."
docker-compose exec wordpress bash -c "mkdir -p /var/www/html/wp-content/uploads/2025/04 && \
  mkdir -p /var/www/html/wp-content/upgrade/metronome-tmp"

# Generate a sample metronome image if it doesn't exist
if [ -d "/home/turtle_wolfe/repos/wp-dev/devscripts/metronome-app" ]; then
  docker-compose exec wordpress bash -c "if [ ! -f /var/www/html/wp-content/uploads/2025/04/metronome-preview.png ]; then \
    cat > /var/www/html/wp-content/upgrade/metronome-tmp/metronome.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset='utf-8'>
  <title>Metronome Preview</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif; background: #f3f4f6; margin: 0; padding: 20px; }
    .app { background: white; max-width: 500px; margin: 0 auto; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
    h1 { text-align: center; margin-top: 0; font-size: 24px; color: #333; }
    .tempo { display: flex; align-items: center; margin: 20px 0; justify-content: space-between; }
    .play-btn { background: #10b981; color: white; border: none; width: 40px; height: 40px; border-radius: 50%; font-size: 20px; }
    .track { background: #f9fafb; padding: 15px; margin: 15px 0; border-radius: 4px; }
    .track-header { display: flex; justify-content: space-between; margin-bottom: 10px; }
    .track-cells { display: grid; grid-template-columns: repeat(8, 1fr); gap: 8px; }
    .cell { height: 30px; border-radius: 4px; background: #e5e7eb; border: 2px solid #d1d5db; }
    .cell.active { background: #3b82f6; border-color: #2563eb; }
    .mute-btn { background: #3b82f6; color: white; border: none; padding: 4px 8px; border-radius: 50%; margin-right: 8px; }
    .volume { width: 100px; }
  </style>
</head>
<body>
  <div class='app'>
    <h1>Interactive Metronome</h1>
    <div class='tempo'>
      <label>Tempo: 120 BPM</label>
      <button class='play-btn'>▶</button>
    </div>
    <input type='range' min='60' max='200' value='120' style='width: 100%'>
    
    <div class='track'>
      <div class='track-header'>
        <div>
          <button class='mute-btn'>🔊</button>
          <span>Kick</span>
        </div>
        <input type='range' class='volume' min='0' max='1' step='0.1' value='0.8'>
      </div>
      <div class='track-cells'>
        <div class='cell active'></div>
        <div class='cell'></div>
        <div class='cell'></div>
        <div class='cell'></div>
        <div class='cell active'></div>
        <div class='cell'></div>
        <div class='cell'></div>
        <div class='cell'></div>
      </div>
    </div>
    
    <div class='track'>
      <div class='track-header'>
        <div>
          <button class='mute-btn'>🔊</button>
          <span>Snare</span>
        </div>
        <input type='range' class='volume' min='0' max='1' step='0.1' value='0.8'>
      </div>
      <div class='track-cells'>
        <div class='cell'></div>
        <div class='cell'></div>
        <div class='cell active'></div>
        <div class='cell'></div>
        <div class='cell'></div>
        <div class='cell'></div>
        <div class='cell active'></div>
        <div class='cell'></div>
      </div>
    </div>
    
    <div style='text-align: center; margin-top: 20px; font-size: 14px; color: #666;'>
      Click on cells to toggle beats on/off. Use the mute buttons to silence tracks.
    </div>
  </div>
</body>
</html>
EOF
    
    # Use chrome headless to take a screenshot (this would normally be done in a more complex setup)
    echo 'placeholder metronome image created manually';
    
    # Create a simple placeholder image if chrome headless isn't available
    base64 -d > /var/www/html/wp-content/uploads/2025/04/metronome-preview.png << 'IMGEOF'
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
IMGEOF
  fi; \
  chmod 644 /var/www/html/wp-content/uploads/2025/04/metronome-preview.png; \
  chown www-data:www-data /var/www/html/wp-content/uploads/2025/04/metronome-preview.png; \
  echo 'metronome preview image created'; \
  fi"
fi

# Verify the plugin is loaded and shortcode is registered
echo "Verifying ReactPress placeholder shortcode is registered..."
SHORTCODE_CHECK=$(docker-compose exec wordpress wp --path=/var/www/html eval "global \$shortcode_tags; echo (isset(\$shortcode_tags['scripthammer_react_app']) ? 'Shortcode exists' : 'Shortcode does not exist');" 2>/dev/null)

if [[ "$SHORTCODE_CHECK" != *"Shortcode exists"* ]]; then
  echo "⚠️ WARNING: ReactPress shortcode is not registered. This may indicate the plugin is not loading correctly."
  
  # Attempt to fix by explicitly including the file
  echo "Attempting to fix by manually loading the plugin..."
  docker-compose exec wordpress wp --path=/var/www/html eval "include_once('/var/www/html/wp-content/mu-plugins/metronome-app.php');"
  
  # Check again
  SHORTCODE_CHECK_AGAIN=$(docker-compose exec wordpress wp --path=/var/www/html eval "global \$shortcode_tags; echo (isset(\$shortcode_tags['scripthammer_react_app']) ? 'Shortcode now exists' : 'Still no shortcode');" 2>/dev/null)
  echo "After fix attempt: $SHORTCODE_CHECK_AGAIN"
else
  echo "✅ Metronome shortcode is properly registered"
fi

# Verify the React Integration page exists and has the shortcode
echo "Checking that the React Integration page contains the shortcode..."
INTEGRATION_PAGE=$(docker-compose exec wordpress wp post list --post_type=page --post_status=publish --name=react-integration --format=count --path=/var/www/html 2>/dev/null)

if [ "$INTEGRATION_PAGE" -eq "0" ]; then
  echo "React Integration page not found. Creating it..."
  docker-compose exec wordpress wp post create --post_type=page --post_title="React Integration" --post_status="publish" --post_name="react-integration" --post_content="<h2>ScriptHammer React Integration</h2>
<div>[scripthammer_react_app]</div>" --path=/var/www/html
  echo "✅ Created React Integration page with shortcode"
else
  # Make sure the page has the shortcode
  HAS_SHORTCODE=$(docker-compose exec wordpress wp --path=/var/www/html post get $(docker-compose exec wordpress wp --path=/var/www/html post list --post_type=page --name=react-integration --field=ID) --field=content | grep -c '\[scripthammer_react_app\]')
  
  if [ "$HAS_SHORTCODE" -eq "0" ]; then
    echo "⚠️ React Integration page exists but doesn't contain the shortcode. Adding it..."
    INTEGRATION_ID=$(docker-compose exec wordpress wp --path=/var/www/html post list --post_type=page --name=react-integration --field=ID)
    docker-compose exec wordpress wp --path=/var/www/html post update $INTEGRATION_ID --post_content="<h2>ScriptHammer React Integration</h2>
<div>[scripthammer_react_app]</div>"
    echo "✅ Added shortcode to React Integration page"
  else
    echo "✅ React Integration page exists and contains the shortcode"
  fi
fi

# Final verification - check if the shortcode is being rendered properly
echo "Performing final verification - checking if the shortcode renders..."
# The app should contain this distinctive metronome-app class
RENDERED_CHECK=$(docker-compose exec wordpress curl -s http://localhost/react-integration | grep -c "metronome-app")

if [ "$RENDERED_CHECK" -gt "0" ]; then
  echo "✅ SUCCESS: Metronome app is rendering correctly on the page!"
else
  echo "⚠️ WARNING: Metronome app does not appear to be rendering correctly."
  echo "The shortcode is registered and exists in the page, but may not be rendering as expected."
  
  # Force WordPress to refresh by visiting the site
  docker-compose exec wordpress curl -s http://localhost/ > /dev/null
  
  # Try again after a brief delay
  sleep 2
  RENDERED_CHECK_RETRY=$(docker-compose exec wordpress curl -s http://localhost/react-integration | grep -c "metronome-app")
  
  if [ "$RENDERED_CHECK_RETRY" -gt "0" ]; then
    echo "✅ SUCCESS on retry: Metronome app is now rendering correctly!"
  else
    echo "❌ Still not rendering correctly. You may need to check error logs or restart Apache."
    # One last attempt - force PHP to load the shortcode again
    docker-compose exec wordpress wp eval "include_once('/var/www/html/wp-content/mu-plugins/metronome-app.php'); echo do_shortcode('[scripthammer_react_app]');" --path=/var/www/html
  fi
fi

echo ""
echo "✅ Environment rebuild complete!"
echo "Access WordPress at: $WP_SITE_URL"
echo "Admin user: ${WP_ADMIN_USER:-admin}"
echo "Admin password: $WP_ADMIN_PASSWORD"
echo ""
echo "React Integration page is available at: $WP_SITE_URL/react-integration"
echo "It should now show the ReactPress placeholder."
echo ""