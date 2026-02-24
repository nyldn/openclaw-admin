# OpenClaw on Docker

## Prerequisites

- Docker 24+ with Docker Compose v2
- At least 2 GB RAM available for the container

## Installation

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
./docker-setup.sh
```

The setup script builds the image, runs onboarding, generates tokens, creates `.env`, and starts services via Docker Compose.

## Service Management

| Action | Command |
|--------|---------|
| Start | `docker compose up -d` |
| Stop | `docker compose down` |
| Restart | `docker compose restart` |
| Status | `docker compose ps` |
| Logs | `docker compose logs -f --tail 100` |
| Rebuild | `docker compose build --no-cache && docker compose up -d` |

**Web UI:** `http://127.0.0.1:18789/`

## Configuration

### Environment Variables

Set in `.env` or pass to `docker compose`:

```bash
OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
```

### Persistent Storage

Docker Compose bind mounts:
- `~/.openclaw/` — config and credentials
- `~/.openclaw/workspace/` — agent workspace data

### ClawDock Helpers

```bash
source docker-helpers.sh
clawdock-start                      # Start services
clawdock-stop                       # Stop services
clawdock-dashboard                  # Open web UI
```

## Docker Administration

### Health Checks

```bash
docker inspect --format='{{.State.Health.Status}}' openclaw-gateway
docker stats --no-stream            # Resource usage snapshot
docker system df                    # Disk usage breakdown
```

### Updates

```bash
# Pull latest image and recreate
docker compose pull
docker compose up -d

# Or rebuild from source
git pull
docker compose build --no-cache
docker compose up -d
```

### Cleanup

```bash
docker system prune -a              # Remove unused images/containers/networks
docker volume prune                 # Remove unused volumes (CAUTION: data loss)
docker image prune --filter "until=720h"   # Remove images older than 30 days
```

### Agent Sandboxing

OpenClaw can run agent tool execution in isolated Docker containers:
- Per-agent, per-session, or shared sandboxes
- Auto-pruning removes idle containers (>24h) or containers >7 days old
- Configure via `openclaw.json` under `tools.sandbox`

### Security

```bash
# Run as non-root (default in official image, uid 1000)
# Use --read-only where possible
# Drop capabilities: --cap-drop=ALL --cap-add=NET_BIND_SERVICE
# Scan images for vulnerabilities
docker scout cves openclaw:local
```

## Troubleshooting

**Container exits immediately:**
```bash
docker compose logs openclaw-gateway --tail 50
docker inspect openclaw-gateway | jq '.[0].State'
```

**Port conflict:**
```bash
ss -tlnp | grep 18789              # Linux
lsof -i :18789                      # macOS
```

**Out of disk space:**
```bash
docker system df
docker system prune -a
```

**Cannot connect to gateway:**
```bash
docker compose ps                   # Verify container is running
docker compose exec openclaw-gateway curl -s http://127.0.0.1:18789/health
```
