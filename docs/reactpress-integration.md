# ScriptHammer ReactPress Integration

## React App Integration Strategies

### Separate Repo Approach (Recommended)
- **Independent lifecycle management**: Version control, CI/CD, and release cycles managed separately
- **Clean separation of concerns**: Frontend and WordPress codebases maintained independently
- **Specialized team access**: Different permission models for React developers vs WordPress developers
- **Build artifact deployment**: Only the compiled `build/` folder is deployed to WordPress

#### Implementation:
```
External React Repo → Build → Deploy → wp-content/plugins/reactpress/apps/scripthammer-app/
```

### Monorepo Approach (Alternative)
- **Simplified local development**: Everything in one place for quick iterations
- **Atomic commits**: Changes to both WordPress and React code in single commits
- **Synchronized versioning**: Frontend and backend versioned together

#### Implementation:
```
wp-dev/
├── wordpress/
└── react-apps/
    └── scripthammer-app/
```

## Best Practices for ReactPress Integration

### For Separate Repository Workflow
1. **Automated build deployment**:
   - Configure CI to:
     - Build React app (`npm run build`)
     - Copy `build/` folder to WordPress plugin directory
     - Optionally tag with version info

2. **Version tracking**:
   - Include version info in build artifact name or in `VERSION.txt`
   - Maintain changelog with each release

3. **Development workflow**:
   - Use ReactPress's hot-reload proxy during development
   - Test in isolated environment before WordPress integration

### For Monorepo Workflow
1. **Workspace management**:
   - Use tools like Turborepo, Nx, or Yarn Workspaces
   - Configure shared dependencies and build scripts

2. **Build configuration**:
   - Set up build output to go directly to ReactPress apps directory
   - Configure public path to match WordPress URL structure

3. **Cross-project references**:
   - Share types and interfaces between frontend/backend
   - Maintain clear boundaries between WordPress and React code

## Build & Deployment Pipeline

### Local Development
```bash
# From React app directory
npm start  # Uses ReactPress hot-reload proxy

# For WordPress admin
cd /path/to/wordpress
wp reactpress proxy start
```

### CI/CD Deployment
```bash
# Build script example
npm run build
rsync -av --delete build/ /path/to/wordpress/wp-content/plugins/reactpress/apps/scripthammer-app/

# Version tagging
echo "v1.2.3" > /path/to/wordpress/wp-content/plugins/reactpress/apps/scripthammer-app/VERSION.txt
```

## Integration Status
- Visual placeholder integration implemented
- Interactive metronome app created in metronome-app/ directory
- React components ready for build and integration
- Will be implemented with separate repository approach
- Target completion: Q2 2025

## Current Implementation

The current implementation includes:

1. **Metronome Plugin**: A WordPress MU-plugin that registers the `[scripthammer_react_app]` shortcode
2. **Functional Metronome**: A fully working drum sequencer with audio using the Web Audio API
3. **React Components**: Prepared React components that can be built and deployed (future enhancement)
4. **Automated Setup**: The ReactPress integration is enabled by default in the development environment

### Testing the Current Implementation

You can test the current implementation by:

1. Running the rebuild script to set up a clean environment:
   ```bash
   ./scripts/dev/rebuild-dev.sh
   ```

2. Visiting the React Integration page at:
   ```
   http://localhost:8000/react-integration
   ```

3. Building the full React app (optional, not currently automated):
   ```bash
   ./scripts/dev/build-react-app.sh
   ```

## Commands to Run
```bash
# Install ReactPress plugin in WordPress
wp plugin install reactpress --activate

# After React app build
wp reactpress register scripthammer-app --title="ScriptHammer App" --path=/wp-content/plugins/reactpress/apps/scripthammer-app/
```