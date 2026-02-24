# Claw Admin

System administration skill for managing [OpenClaw](https://openclaw.ai) instances across macOS, Ubuntu/Debian, Docker, Oracle OCI, and Proxmox. Works with Claude Code, Gemini CLI, and Codex CLI.

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/badge/Platforms-5-blue" alt="5 Platforms">
  <img src="https://img.shields.io/badge/Providers-Claude%20%7C%20Gemini%20%7C%20Codex-blueviolet" alt="Multi-Provider">
</p>

---

## What It Does

Claw Admin is an AI sysadmin that manages your OpenClaw deployment. It auto-detects your platform, runs diagnostics, handles updates, hardens security, and troubleshoots issues — all through natural language.

**Supported platforms:**

| Platform | What it manages |
|----------|----------------|
| macOS | Homebrew, launchd, Application Firewall, FileVault |
| Ubuntu/Debian | apt, systemd, ufw, journalctl, unattended-upgrades |
| Docker | docker compose, container health, volumes, log drivers |
| Oracle OCI | ARM instances, VCN/NSG networking, block volumes, Tailscale |
| Proxmox | VMs (qm), LXC containers (pct), ZFS, vzdump, clustering |

**OpenClaw management:**
- Gateway lifecycle: start, stop, restart, status, health, logs
- Diagnostics: `openclaw doctor`, `openclaw security audit`
- Configuration: channels, models, agents, sessions, skills, plugins
- Updates: channel management (stable/beta/dev), backup, rollback
- Security hardening: loopback binding, token auth, Tailscale, sandbox config

---

## Quick Start

### Claude Code

Drop `CLAUDE.md` into your project root or home directory:

```bash
# Project-level (applies to this project)
cp CLAUDE.md /path/to/your/project/CLAUDE.md

# User-level (applies to all projects)
cp CLAUDE.md ~/.claude/CLAUDE.md
```

Then ask naturally:

```
Check if my OpenClaw instance is healthy
Update OpenClaw to latest stable
Harden my server security
Set up OpenClaw on Proxmox
```

### Gemini CLI

```bash
# Copy the instructions file
cp GEMINI.md ~/.gemini/GEMINI.md

# Or pass directly
gemini -p "$(cat GEMINI.md)" "Check my OpenClaw status"
```

### Codex CLI

```bash
# Copy the instructions file
cp CODEX.md ~/.codex/instructions.md

# Or pass directly
codex -p "$(cat CODEX.md)" "Check my OpenClaw status"
```

### Claude Octopus Plugin

If you use [Claude Octopus](https://github.com/nyldn/claude-octopus), this skill is available as `/octo:claw`:

```
/octo:claw check my server health
/octo:claw update openclaw
/octo:claw harden my server
```

---

## Platform Guides

- [macOS Setup](docs/macos.md) — Homebrew, launchd, FileVault
- [Ubuntu/Debian Setup](docs/ubuntu-debian.md) — apt, systemd, ufw
- [Docker Setup](docs/docker.md) — Compose, health checks, volumes
- [Oracle OCI Setup](docs/oracle-oci.md) — ARM free tier, Tailscale
- [Proxmox Setup](docs/proxmox.md) — LXC, ZFS, clustering

## Networking & Access

- [Tailscale](docs/tailscale.md) — Serve, Funnel, SSH, ACLs, Docker sidecar, Proxmox TUN

## Channel Integrations

- [Telegram](docs/telegram.md) — BotFather, Grammy, polling vs webhooks
- [Slack](docs/slack.md) — Bolt, Socket Mode vs HTTP, OAuth scopes, app manifests
- [OpenClaw Modules Reference](docs/modules.md) — All channels, tools, plugins, scheduler, memory

## Additional Tools

- [gogcli](docs/gogcli.md) — Google Workspace CLI (Drive, Docs, Sheets)

---

## Example Configs

- [`examples/openclaw.json`](examples/openclaw.json) — Hardened OpenClaw configuration
- [`examples/docker-compose.yml`](examples/docker-compose.yml) — Production Docker Compose
- [`examples/proxmox-lxc.sh`](examples/proxmox-lxc.sh) — Automated Proxmox LXC provisioning

---

## Safety

Claw Admin includes a [safety gate hook](hooks/sysadmin-safety-gate.sh) that blocks dangerous operations:

- `rm -rf` on system paths
- Exposing OpenClaw gateway port to the internet
- `docker compose down -v` (destroys volumes)
- Disabling firewalls entirely
- Piping unverified scripts to `sudo sh`
- Destroying Proxmox VMs/containers without confirmation

---

## Repository Structure

```
claw-admin/
  CLAUDE.md              # Full instructions for Claude Code
  GEMINI.md              # Full instructions for Gemini CLI
  CODEX.md               # Full instructions for Codex CLI
  skill.md               # Portable skill file (used by claude-octopus)
  persona.md             # Portable persona file (used by claude-octopus)
  docs/
    macos.md             # macOS platform guide
    ubuntu-debian.md     # Ubuntu/Debian platform guide
    docker.md            # Docker platform guide
    oracle-oci.md        # Oracle OCI platform guide
    proxmox.md           # Proxmox VE platform guide
    tailscale.md         # Tailscale networking guide
    telegram.md          # Telegram channel integration
    slack.md             # Slack channel integration
    gogcli.md            # Google Workspace CLI
    modules.md           # Complete OpenClaw modules reference
  examples/              # Example configurations
  hooks/                 # Safety gate hooks
```

---

## Integration with Claude Octopus

This repo is the source of truth. Claude Octopus pulls it in as a git submodule:

```bash
# In the claude-octopus repo
git submodule add https://github.com/nyldn/claw-admin.git claw-admin
```

The plugin references `claw-admin/skill.md` and `claw-admin/persona.md` from the submodule.

---

## License

MIT — see [LICENSE](LICENSE)
