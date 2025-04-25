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

1. **Content embedded in automation scripts**
   - Large blocks of content in bash scripts (`scripthammer.sh`, `demo-content.sh`)
   - Content is recreated on each container rebuild
   - Hard-coded post IDs in templates that break during rebuilds

2. **Tightly coupled components**
   - Band content mixed with system initialization
   - Bots operating directly within WordPress container
   - Template files with hard-coded dependencies

3. **Inefficient rebuild process**
   - Full content recreation on each rebuild
   - No separation between first-run and subsequent runs
   - Brittle dependencies between components

4. **Image duplication in posts**
   - Band member posts currently have the same image appearing twice:
     - Once as a featured image (via _thumbnail_id)
     - Again as an embedded HTML block in post content
   - This is a workaround for styling limitations but creates redundancy
   
5. **Theme and block editor conflicts**
   - The current BuddyX theme (v4.8.1) doesn't fully support Gutenberg block styling
   - Classic Widgets plugin is active, but content still uses Gutenberg blocks
   - Embedded HTML blocks with floating images work, but styling is inconsistent
   - The theme's CSS doesn't properly handle image floating and text wrapping

## 📋 Refactoring Roadmap

### Phase 1: Content Separation (Current Focus)
1. Create WordPress export (WXR) files for all band content
2. Modify setup scripts to check if content exists first
3. Remove hard-coded post IDs from templates

### Phase 2: Theme Development (Planned)
1. Create "Steampunk BuddyX" child theme to address style issues:
   - Fix floating image styles with proper text wrapping for band members
   - Use proper CSS selectors to target embedded HTML content
   - Hide one of the duplicated images (likely hide featured images)
   - Add steampunk visual elements (brass, copper, Victorian styling)
2. Properly handle block editor vs classic editor content:
   - Recognize that BuddyX uses Classic Widgets plugin but content uses Gutenberg
   - Consider moving to a fully classic editor approach for content OR
   - Create custom Gutenberg blocks designed for the steampunk theme
3. Template hierarchy adjustments:
   - Create custom templates for band content that properly handle images
   - Document the template hierarchy for future developers

### Phase 3: Bot Independence
1. Create dedicated container for automation bots
2. Implement REST API endpoints for bot operations
3. Replace direct database access with API calls

### Phase 4: Infrastructure Improvements
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

5. **Recent Technical Updates**
   - Akismet AntiSpam is now activated automatically
   - Hello Dolly is automatically deleted
   - The ScriptHammer Band Navigation plugin has been removed (wasn't doing anything)
   - Classic Widgets is used for better widget UI management
   
6. **Theme Development Notes for Steampunk BuddyX**
   - **Current Image Issue**: The theme doesn't properly style the featured images for floating with text wrapping
   - **Temporary Solution**: We're using both featured images AND HTML-embedded images with float styling
   - **Potential Theme Fixes**:
     - Option 1: Hide featured images via CSS and enhance embedded images
     - Option 2: Modify single.php template to add float styling to featured images
     - Option 3: Create custom band-member.php template with special image handling
   - **Recommended Approach**: Create a proper child theme that implements Option 3
   - **Development Path**: Start with a basic child theme structure in /devscripts/theme-patches/steampunk-buddyx/
   - **Visual Style**: Adopt brass, copper, dark wood colors with Victorian typography and steampunk elements

You're known for being a more creative writer, so please don't feel limited by the existing content. The technical foundation is solid - now it needs your storytelling magic to bring these characters to life!