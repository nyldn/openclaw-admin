# Tailscale for OpenClaw

## Why Tailscale?

OpenClaw's gateway binds to `127.0.0.1:18789` by design. It should **never** be exposed directly to the internet. Tailscale provides zero-config, encrypted access to your OpenClaw instance from anywhere on your tailnet without opening firewall ports.

## Key Concepts

| Concept | What It Does |
|---------|-------------|
| **Tailnet** | Your private network — all devices running Tailscale join it automatically |
| **MagicDNS** | Access devices by hostname (e.g., `openclaw-server`) instead of IP |
| **Tailscale Serve** | Expose a local service (like OpenClaw) to your tailnet over HTTPS |
| **Tailscale Funnel** | Expose a service to the public internet (use with extreme caution) |
| **Tailscale SSH** | SSH without managing keys — access control via ACLs |
| **ACLs** | Access Control Lists defining who can reach what on the tailnet |

## Installation

### macOS

```bash
# Via Homebrew
brew install --cask tailscale

# Or download from https://tailscale.com/download/macos
# Start from menu bar or:
open -a Tailscale
```

### Ubuntu/Debian

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Docker (Sidecar Pattern)

Add a Tailscale sidecar container alongside OpenClaw:

```yaml
# docker-compose.yml
services:
  openclaw-gateway:
    build: .
    container_name: openclaw-gateway
    restart: unless-stopped
    network_mode: "service:tailscale"  # Share tailscale's network
    volumes:
      - ${HOME}/.openclaw:/home/node/.openclaw

  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale-openclaw
    hostname: openclaw-docker
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    volumes:
      - tailscale-state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
      - ./tailscale-config:/config         # Serve config directory
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}           # Pre-auth key from admin console
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_SERVE_CONFIG=/config/serve.json # Auto-loaded on container start

volumes:
  tailscale-state:
```

### Proxmox LXC

```bash
# On the Proxmox HOST, enable TUN device for the LXC:
# Add to /etc/pve/lxc/<CTID>.conf:
lxc.cdev.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file

# Inside the LXC container:
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Oracle OCI

```bash
# Inside the OCI instance:
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Strip all VCN ingress except Tailscale UDP 41641
# (See Oracle OCI guide for security list config)
```

## Tailscale Serve — Expose OpenClaw to Tailnet

Tailscale Serve creates an HTTPS reverse proxy on your tailnet, mapping your machine's tailnet hostname to `localhost:18789`.

```bash
# Serve OpenClaw gateway over HTTPS on your tailnet
tailscale serve https / http://127.0.0.1:18789

# Verify
tailscale serve status

# Access from any device on your tailnet:
# https://openclaw-server.tailnet-name.ts.net/
```

### Persistent Serve Configuration

The `tailscale serve` command persists across restarts automatically — there's no need for a separate config file on bare-metal installs. For Docker, use the `TS_SERVE_CONFIG` environment variable:

```bash
# Create serve config for Docker sidecar
mkdir -p ./tailscale-config
cat > ./tailscale-config/serve.json << 'EOF'
{
  "TCP": {
    "443": {
      "HTTPS": true
    }
  },
  "Web": {
    "${TS_CERT_DOMAIN}:443": {
      "Handlers": {
        "/": {
          "Proxy": "http://127.0.0.1:18789"
        }
      }
    }
  }
}
EOF

# The Tailscale container reads this via TS_SERVE_CONFIG on startup.
# For bare-metal, just run:
tailscale serve https / http://127.0.0.1:18789
# This persists automatically until you run: tailscale serve reset
```

## Tailscale Funnel — Public Internet Access

**Use with extreme caution.** Funnel exposes your service to the entire internet, not just your tailnet.

```bash
# Expose to public internet (DANGEROUS — think carefully)
tailscale funnel https / http://127.0.0.1:18789

# Status
tailscale funnel status

# Turn off
tailscale funnel off
```

**When to use Funnel:**
- Slack/Telegram webhooks that require a public HTTPS endpoint
- Temporary demos or testing

**When NOT to use Funnel:**
- General OpenClaw access (use Serve instead)
- Long-term production (use a proper reverse proxy)

## Tailscale SSH

Access your OpenClaw host without managing SSH keys:

```bash
# Enable Tailscale SSH on the server
tailscale up --ssh

# Connect from any tailnet device
ssh ubuntu@openclaw-server
```

ACLs control who can SSH to what. Configure in the Tailscale admin console.

## ACL Configuration

Manage ACLs at [login.tailscale.com/admin/acls](https://login.tailscale.com/admin/acls).

Example ACL for OpenClaw:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:admins"],
      "dst": ["tag:openclaw:443", "tag:openclaw:22"]
    }
  ],
  "tagOwners": {
    "tag:openclaw": ["group:admins"]
  },
  "groups": {
    "group:admins": ["user@example.com"]
  }
}
```

This restricts OpenClaw access to members of the `admins` group only.

## Tailscale + OpenClaw Configuration

In `openclaw.json`, the gateway should always bind to loopback:

```json
{
  "gateway": {
    "host": "127.0.0.1",
    "port": 18789,
    "auth": "token"
  }
}
```

Tailscale Serve handles the HTTPS termination and access control. OpenClaw never needs to know about Tailscale.

## Diagnostics

```bash
# Tailscale status
tailscale status

# Check what's being served
tailscale serve status

# Check connectivity to another tailnet device
tailscale ping openclaw-server

# Debug connection issues
tailscale netcheck

# View tailscale logs
journalctl -u tailscaled -f          # Linux
log show --predicate 'process == "tailscaled"' --last 5m  # macOS
```

## Troubleshooting

**Tailscale Serve returns 502:**
```bash
# OpenClaw gateway isn't running
openclaw status
openclaw gateway start

# Verify it's listening on 18789
curl -s http://127.0.0.1:18789/health
```

**Can't reach tailnet device:**
```bash
# Check if both devices are on the same tailnet
tailscale status  # Run on both devices

# Check ACLs aren't blocking
# Review at login.tailscale.com/admin/acls

# Check firewall isn't blocking Tailscale (UDP 41641)
# macOS: socketfilterfw shouldn't block Tailscale
# Linux: ufw allow 41641/udp (if using ufw)
```

**TUN device missing in Proxmox LXC:**
```bash
# On the Proxmox HOST, verify LXC config:
cat /etc/pve/lxc/<CTID>.conf | grep -i tun

# Should show:
# lxc.cdev.allow: c 10:200 rwm
# lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file

# Restart the container after adding:
pct stop <CTID> && pct start <CTID>
```

**Docker container can't connect:**
```bash
# Verify TUN device is available
ls -la /dev/net/tun

# Check capabilities
docker inspect tailscale-openclaw | grep -A 5 CapAdd
# Should include NET_ADMIN and SYS_MODULE

# Check auth key
docker logs tailscale-openclaw 2>&1 | tail -20
```

## Security Best Practices

1. **Use Serve, not Funnel** — Serve limits access to your tailnet; Funnel opens to the world
2. **Tag your OpenClaw devices** — Use `tag:openclaw` and ACLs to restrict access
3. **Enable MFA on your Tailscale account** — Protects your entire tailnet
4. **Use auth keys with expiry** — Don't use reusable keys in production
5. **Audit connected devices** — Review `tailscale status` regularly
6. **Never expose 18789 via firewall** — Tailscale Serve makes this unnecessary
