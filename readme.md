# WordPress Development Environment

This repository provides a Docker-based WordPress development environment with BuddyPress installed. Follow the instructions below to get started with local development.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- Git
- SSH key for repository access

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/TortoiseWolfe/wp-dev
cd wp-dev
```

### 2. Setting Up SSH Keys

To access the repository:

1. Generate an Ed25519 SSH key (GitHub's current security best practice):
   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   ```

2. Start the ssh-agent in the background and add your key:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. Add the SSH key to your GitHub account:
   - Copy your public key:
     ```bash
     cat ~/.ssh/id_ed25519.pub
     ```
   - Go to GitHub → Settings → SSH and GPG keys → New SSH key
   - Paste your key and save

4. Verify your connection:
   ```bash
   ssh -T git@github.com
   ```

### 3. Configure Environment Variables

```bash
cp .env.example .env
```

Edit the `.env` file to customize:
- Database credentials
- WordPress admin account
- Site URL and title

### 4. Start the Development Environment

```bash
docker-compose up -d
```

This will:
- Start WordPress at http://localhost:8000
- Set up a MySQL database
- Run the setup script to configure WordPress and BuddyPress

## Daily Development Workflow

### Running the Environment

- Start: `docker-compose up -d`
- Stop: `docker-compose down`
- View logs: `docker-compose logs -f`

### Accessing WordPress

- Admin Dashboard: http://localhost:8000/wp-admin/
  - Default username: `admin`
  - Default password: See docker-compose.yml for WORDPRESS_ADMIN_PASSWORD

### Executing WP-CLI Commands

```bash
docker-compose exec wordpress wp --allow-root [command]
```

Example:
```bash
docker-compose exec wordpress wp --allow-root plugin list
```

### Populating Demo Content

To add example users, posts, comments, pages, and BuddyPress content:

```bash
docker-compose exec wordpress /usr/local/bin/devscripts/demo-content.sh
```

**Important Note**: The script must be run from inside the container using the path above. It will not work if you try to run it directly from your host machine.

This will create:
- 20 example users with Latin names
- 20 sample posts with comments and replies
- 5 BuddyPress groups with members and activities (if BuddyPress is active)
- 5 sample pages with philosophical content
- Example messages to admin (if BuddyPress Messages is active)

## Git Workflow

### Branching Strategy

1. Always create feature branches from main:
   ```bash
   git checkout main
   git pull
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "Descriptive commit message"
   ```

3. Push your branch to remote:
   ```bash
   git push -u origin feature/your-feature-name
   ```

### Creating Pull Requests

1. Go to the repository on GitHub
2. Click "Pull Requests" � "New Pull Request"
3. Select your branch and the target branch (main)
4. Fill in the PR template with:
   - Description of changes
   - Testing instructions
   - Screenshots (if applicable)
5. Request reviews from team members

### Reviewing and Merging

1. Address any feedback from reviewers
2. Once approved, merge the PR on GitHub
3. Delete the feature branch after merging:
   ```bash
   git checkout main
   git pull
   git branch -d feature/your-feature-name
   ```

## Troubleshooting

- **Container issues**: Try `docker-compose down -v` followed by `docker-compose up -d`
- **Database connection errors**: Check environment variables in docker-compose.yml
- **WordPress configuration**: Examine setup.sh for the installation process

## Additional Resources

- [WordPress Codex](https://codex.wordpress.org/)
- [BuddyPress Documentation](https://codex.buddypress.org/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)