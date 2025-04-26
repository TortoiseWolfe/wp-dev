# WordPress Development Environment Guidelines

## First Principles and Roadmap

1. **Content vs. Code Separation**
   - Content should be created once, then managed through WordPress
   - Code should handle system setup and infrastructure, not content creation
   - Database should be the source of truth for content

2. **Container Architecture**
   - Containers are ephemeral ("cattle not pets")
   - System should be fully rebuildable without manual intervention
   - Each component should have a single responsibility

3. **Automation First**
   - All operations should be automatable
   - Manual steps should be eliminated where possible
   - Infrastructure should be defined as code

See the full implementation guide at `/implementation-guide.md`

## Critical Working Environment

### For Production Environment:
1. Run `source ./scripts/setup-secrets.sh` first (this updates .env file automatically with GSM secrets)
2. Run `sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN"` 
3. Run `sudo -E docker-compose up -d [services]` to start containers
4. Always use sudo with Docker commands to avoid permission errors ("Error: kill EPERM")

### For Local Development Environment:
1. Run `source ./scripts/dev/setup-local-dev.sh` to generate secure local development credentials
2. Run `sudo -E docker-compose up -d wordpress wp-setup db` to start dev containers
3. Access WordPress at:
   - When running in WSL, you MUST use the IP address: http://172.x.x.x:8000 (exact IP shown during setup)
   - WARNING: Using "localhost" in WSL will cause broken links and connection failures
4. Always use sudo with Docker commands to avoid permission errors

## ⚠️ Current Issues and Technical Debt

1. **Child theme activation during rebuilds (FIXED)**
   - ✅ FIXED: The steampunk-buddyx theme now activates reliably during container rebuilds
   - ✅ Fixed redundant theme activation attempts in multiple scripts
   - ✅ Improved execution order by installing parent theme without activation first
   - ✅ Centralized theme activation in main install.sh script with retry logic

2. **Content embedded in automation scripts (IMPROVED)**
   - ✅ IMPROVED: Band member posts are now scheduled starting May 1st, 2025
   - ✅ FIXED: Default WordPress content (Hello World post, Sample Page) is now automatically removed
   - ✅ ADDED: Links to band member profile pages in each band member's post
   - ✅ FIXED: Made scripthammer.sh more robust when checking for export files
   - ✅ FIXED: Script now continues with content creation even if BuddyPress components fail to activate
   - ✅ IMPROVED: Better error handling in scripthammer.sh for smoother content creation
   - Hard-coded post IDs in templates that break during rebuilds

3. **Tightly coupled components**
   - Band content mixed with system initialization
   - Bots operating directly within WordPress container
   - Template files with hard-coded dependencies

4. **Inefficient rebuild process (IMPROVED)**
   - ✅ IMPROVED: BuddyPress components (friend requests, private messaging, user groups, site tracking) now properly activate
   - ✅ FIXED: Fixed duplicate H2 headings in band posts
   - ⚠️ MONITOR: Keep a close eye on the "groups" BuddyPress component, which may occasionally fail to activate properly
   - Full content recreation on each rebuild
   - No separation between first-run and subsequent runs
   - Brittle dependencies between components

5. **Theme and block editor conflicts (FIXED)**
   - ✅ The current BuddyX theme (v4.8.1) doesn't fully support Gutenberg block styling
   - ✅ Classic Widgets plugin is active, but content still uses Gutenberg blocks 
   - ✅ The steampunk-buddyx child theme fixes image display issues and now activates reliably
   - ✅ FIXED: Header transparency issue causing white vertical bars in the site header

## 📋 Refactoring Roadmap

### Phase 1: Theme Activation Fix (COMPLETED)
1. ✅ Fixed child theme activation during rebuilds:
   - ✅ Fixed timing issues with WordPress initialization
   - ✅ Improved script execution order in WordPress lifecycle
   - ✅ Centralized theme activation in main install.sh with retry mechanism
   - ✅ Tested with multiple rebuilds to ensure reliability

### Phase 2: Content Separation (COMPLETED)
1. ✅ Created WordPress export (WXR) files for all band content
2. ✅ Modified setup scripts to check if content exists first
3. ✅ Improved content management:
   - ✅ Added post scheduling for band member posts (starting May 1st, 2025)
   - ✅ Added automatic removal of default WordPress content
   - ✅ Added profile links to band member posts
   - ✅ Fixed duplicate H2 headings in band posts
4. ✅ Fixed scripthammer.sh for more robust content creation:
   - ✅ Improved import function to check multiple locations for export files
   - ✅ Made BuddyPress component activation more resilient with better error handling
   - ✅ Ensured script can continue creating content even if non-critical components fail
5. ⚠️ Still TODO: Remove hard-coded post IDs from templates

### Phase 3: Theme Development (COMPLETED)
1. ✅ Created "Steampunk BuddyX" child theme to address style issues:
   - ✅ Fixed floating image styles with proper text wrapping for band members
   - ✅ Used CSS selectors to properly size and position featured images
   - ✅ Prevented duplicate images on posts by hiding redundant images
2. ✅ Properly handled block editor vs classic editor content:
   - ✅ Ensured Classic Widgets plugin integration
   - ✅ Used CSS and PHP hooks to control image display
3. ✅ Improved theme reliability:
   - ✅ Fixed theme activation during rebuilds
   - ✅ Centralized activation logic
   - ✅ Removed redundant activation calls
4. Remaining Tasks:
   - Document the theme's features and customization options
   - Create proper documentation for theme structure

### Phase 4: Bot Independence
1. Create dedicated container for automation bots
2. Implement REST API endpoints for bot operations
3. Replace direct database access with API calls

### Phase 5: Infrastructure Improvements
1. Implement proper data volume strategy
2. Ensure development and production environments match
3. Automate testing and deployment

## Environment
- WordPress with BuddyPress and GamiPress using Docker
- Database credentials stored in environment variables
- WordPress configuration managed via wp-config.php

## Common Commands:
- `source ./setup-secrets.sh && sudo -E docker login ghcr.io -u tortoisewolfe --password "$GITHUB_TOKEN" && sudo -E docker-compose up -d`: Start WordPress environment (CORRECT full sequence)
- `sudo docker-compose down`: Stop WordPress environment
- `sudo docker-compose build`: Rebuild Docker images (REQUIRED after script changes)
- `sudo docker-compose exec wordpress wp --allow-root [command]`: Run WP-CLI commands
- `sudo docker-compose exec wordpress bash`: Access WordPress container shell
- `./scripts/dev/rebuild-dev.sh`: Rebuild development environment (preserves data volumes)

## Development Status

1. **Theme Activation (FIXED)** ✅
   - The theme activation during container rebuilds is now fixed
   - The steampunk-buddyx child theme activates reliably
   - Fixed redundant theme activation calls and improved activation sequence

2. **BuddyPress Components (FIXED)** ✅
   - Critical BuddyPress components now properly activate during container rebuilds
   - Fixed issues with friend requests, private messaging, user groups, and site tracking
   - Improved component activation to prevent "Too many positional arguments" error
   - Added better error reporting and verification for component activation

## Next Development Tasks

1. **Typography Enhancement** (High Priority)
   - Add three steampunk-themed fonts for a cohesive typography system:
     - "Special Elite" - Confirmed as the primary typewriter-style font
     - Need to select two additional complementary fonts for:
       - Headers/titles (something bold and Victorian/steampunk)
       - Body text (readable but with steampunk character)
   - Implement font loading via Google Fonts or local font files
   - Apply typography hierarchy consistently across the site
   - Add proper font fallbacks for performance and accessibility

2. **Yoast SEO Plugin Integration** (High Priority)
   - Add Yoast SEO plugin installation to the automation scripts
   - Configure default SEO settings during container initialization
   - Ensure plugin activates reliably during rebuilds
   - Add basic SEO metadata for band content
   - Test plugin compatibility with BuddyPress

3. **Environment Configuration Cleanup** (Medium Priority)
   - The .env file has many repeated sections with redundant component settings
   - This might be causing some of the warnings and errors
   - Clean up and consolidate configuration to reduce duplication
   
4. **ReactPress Integration for Metronome App** (Next Priority)
   - Convert the vanilla JS metronome app to a full React implementation
   - Set up build process for React app integration using ReactPress
   - Update metronome shortcode to use React components
   
5. **Content Enhancement** (Future Priority)
   - Implement creative writing for band member profiles from Codex
   - Update band origin story and tour announcement content

**CRITICAL: ALWAYS use sudo with Docker commands. Use sudo -E when environment variables need to be preserved. ALWAYS login to GitHub Container Registry AFTER sourcing secrets but BEFORE pulling images.**

## Notes for Codex on Content Creation

### Band Content Rewrite Suggestions

Hi Codex,

I've set up the technical infrastructure for content preservation across container rebuilds. The current band content (posts about band members, etc.) is functional but could benefit from your creative writing skills. Here are some notes:

1. **Use existing posts as inspiration, not templates**
   - Current posts provide the basic structure and information
   - Feel free to completely rewrite them with your own creative style
   - You have complete creative freedom to reimagine the narrative while keeping the core band concept

2. **Band Members to Focus On**
   - **Crash (Drummer Bot)** - High-octane and impulsive. Chaotic good energy.
   - **Root/Form (Bass Bot)** - Philosophical, speaks in riddles. Zen master of the groove.
   - **Ivory (Piano Bot)** - Sarcastic, refined, references obscure theory. Sophisticated with sass.
   - **Reed (Saxophone Bot)** - Cool-cat energy, dramatic entrances, flirtatious. Noir protagonist vibe.
   - **Brass (Trumpet Bot)** - Loud, proud, confident. Leo energy personified.
   - **Slide (Trombone Bot)** - Deadpan and hilarious. Jazz's dry stand-up comic.
   - **Chops (Guitar Bot)** - Indie rebel, experimental. Weird genius meets stoner philosopher.
   - **Verse (Vocals/Lyrics)** - Original character that may be reimagined or replaced.

3. **Content Structure to Maintain**
   - Keep the same post slugs (URLs) for consistency
   - Maintain the category structure (Music, Tour, Band Members)
   - Preserve relationships between posts, but you can reimagine their interactions

4. **Technical Implementation**
   - Content is now preserved via WP XML exports in the /exports directory
   - Script changes detect existing content and avoid recreation
   - Content can be imported/exported with the --recover and --import flags
   - Band member posts are now scheduled to publish one per day starting May 1st, 2025
   - Each band member post now includes a link to their profile page
   - Duplicate H2 headings are automatically removed from posts
   - Default WordPress content is automatically removed during setup

5. **Recent Technical Updates**
   - Akismet AntiSpam is now activated automatically
   - Hello Dolly is automatically deleted
   - The ScriptHammer Band Navigation plugin has been removed (wasn't doing anything)
   - Classic Widgets is used for better widget UI management
   - Header transparency issue fixed with targeted CSS/PHP styling
   
6. **Planned Technical Updates**
   - Yoast SEO plugin will be added to the automation scripts
   - Three steampunk fonts will be implemented for a cohesive typography system
   - Environment configuration will be cleaned up to reduce duplication
   
7. **Theme Development Notes for Steampunk BuddyX**
   - **Image Solution Implemented**: We've successfully implemented a CSS-based solution to fix image display issues
   - **Current Approach**:
     - Hide featured images on single posts via targeted CSS
     - Show only embedded HTML images in post content with proper styling (float left, text wrap)
     - Maintain thumbnails on homepage/archives for better visual presentation
   - **Technical Implementation**:
     - Added CSS selectors to hide featured images only on single posts
     - Created PHP functions to filter out featured image HTML on singles
     - Maintained thumbnail support for archive/home pages
     - Applied consistent styling for embedded content images
   - **Key Files**:
     - `/devscripts/theme-patches/steampunk-buddyx/style.css`: Contains CSS for image display control
     - `/devscripts/theme-patches/steampunk-buddyx/functions.php`: Contains PHP hooks for thumbnail control
     - `/devscripts/theme-patches/install.sh`: Handles proper child theme installation
   - **Visual Style**: Brass, copper, dark wood colors with Victorian typography and steampunk elements
   - **Header Fix Implemented**: ✅ Successfully fixed the white vertical bars in the header by:
     - Targeting `.site-header-wrapper` with full-width styling and consistent sepia background
     - Using both direct CSS and PHP-injected styles for maximum reliability
     - Setting explicit width/margin/padding properties to ensure edge-to-edge coverage
     - Applying `!important` flags to override any theme defaults
   - **Typography Enhancement Planned**: 
     - Will implement "Special Elite" as primary typewriter-style font
     - Need two additional fonts: one for headers (Victorian/bold) and one for body text
     - Will research Google Fonts options like "Pirata One", "Playfair Display", or "IM Fell English"
     - Implementation will use both CSS variables and WordPress font loading

You're known for being a more creative writer, so please don't feel limited by the existing content. The technical foundation is solid - now it needs your storytelling magic to bring these characters to life!