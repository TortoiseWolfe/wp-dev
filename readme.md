# WordPress Development Environment

A Docker-based WordPress environment with BuddyPress for development and production.

## Prerequisites

- Docker & Docker Compose
- Git
- Node.js (via nvm)
- npm
- (Optional) Google Cloud SDK (for secrets)

## Local Development

```bash
git clone https://github.com/TortoiseWolfe/wp-dev.git
cd wp-dev
cp .env.example .env
./scripts/dev/setup-local-dev.sh
docker-compose up -d
```

Access the site: http://localhost:8000

WP-CLI example:
```bash
docker-compose exec wordpress wp --allow-root plugin list
```

## Production

### Build & Push
```bash
docker build --target production -t ghcr.io/tortoisewolfe/wp-dev:vX.Y.Z .
echo $GITHUB_TOKEN | docker login ghcr.io -u tortoisewolfe --password-stdin
docker push ghcr.io/tortoisewolfe/wp-dev:vX.Y.Z
```

### Deploy
```bash
git pull origin main
./scripts/setup-secrets.sh
docker-compose up -d
```

Or use the deploy script:
```bash
chmod +x deploy-prod.sh
./deploy-prod.sh
```

## Directory Structure

```text
wp-dev/
├── devscripts/
├── docs/
│   └── CLAUDE.md
├── nginx/
├── scripts/
│   ├── dev/
│   └── ssl/
├── docker-compose.yml
├── Dockerfile
└── .env.example
```

## Troubleshooting

- Check Docker: `docker info`
- View logs: `docker-compose logs -f`
- Ensure `$GITHUB_TOKEN` is set for production pulls

## Additional Resources

See `docs/CLAUDE.md` and the `scripts/` directory for advanced instructions.
