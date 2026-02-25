# OpenClaw Admin

An AI-powered system administrator for [OpenClaw](https://openclaw.ai) instances. Manages the full lifecycle across **macOS**, **Ubuntu/Debian**, **Docker**, **Oracle OCI**, and **Proxmox** — through natural language.

Works with **Claude Code**, **Gemini CLI**, and **Codex CLI**.

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/badge/Platforms-5-blue" alt="5 Platforms">
  <img src="https://img.shields.io/badge/Providers-Claude%20%7C%20Gemini%20%7C%20Codex-blueviolet" alt="Multi-Provider">
</p>

---

## Why Use This?

Managing an OpenClaw instance means juggling gateway processes, messaging channels, firewall rules, updates, and security audits across different operating systems. OpenClaw Admin turns your AI coding assistant into a sysadmin that:

- **Auto-detects your platform** before running any command
- **Diagnoses before changing** anything — non-destructive checks first
- **Verifies after every action** — confirms changes took effect
- **Blocks dangerous operations** via a safety gate hook
- **Covers 5 platforms, 6 messaging channels, and the full OpenClaw CLI**

| What it manages | How |
|-----------------|-----|
| **Gateway lifecycle** | Start, stop, restart, health checks, daemon install |
| **5 platforms** | macOS (launchd), Ubuntu/Debian (systemd), Docker (compose), OCI (ARM), Proxmox (LXC) |
| **6 channels** | WhatsApp, Telegram, Discord, Slack, Signal, iMessage |
| **Security** | Audit, hardening, firewall, Tailscale, credential management |
| **Updates** | Backup, upgrade, rollback, version pinning |
| **Monitoring** | Logs, health checks, resource usage, diagnostics |

---

## Install

### Recommended: skills.sh (all agents)

```bash
npx skills add https://github.com/nyldn/openclaw-admin
```

This interactively installs for your preferred agent(s) — Claude Code, Gemini CLI, Codex CLI, Cursor, and 30+ others. Use `-g` for global install:

```bash
npx skills add -g https://github.com/nyldn/openclaw-admin
```

Update later with `npx skills update`.

### Claude Octopus Plugin (zero install)

If you use [Claude Octopus](https://github.com/nyldn/claude-octopus), this is already bundled — just use `/octo:claw`:

```
/octo:claw check my server health
/octo:claw update openclaw to latest
/octo:claw set up tailscale
```

### Manual (single agent)

If you prefer not to use skills.sh:

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/nyldn/openclaw-admin/main/CLAUDE.md -o ~/.claude/CLAUDE.md

# Gemini CLI
curl -fsSL https://raw.githubusercontent.com/nyldn/openclaw-admin/main/GEMINI.md -o ~/.gemini/GEMINI.md

# Codex CLI
curl -fsSL https://raw.githubusercontent.com/nyldn/openclaw-admin/main/CODEX.md -o ~/.codex/instructions.md
```

### Full repo (for docs, examples, and safety hook)

```bash
git clone https://github.com/nyldn/openclaw-admin.git
```

---

## Then Just Ask

```
Check if my OpenClaw instance is healthy
Update OpenClaw to the latest stable version
Harden my server security
Set up OpenClaw on my Proxmox server
Configure the Telegram channel
Set up Tailscale for remote access
```

The instruction files teach the AI to detect your platform, run diagnostics, execute the task, and verify the outcome. How well it follows through depends on the model — Claude Opus and Sonnet handle it reliably; smaller models may need more guidance.

---

## Documentation

### Platform Guides

| Platform | Guide | What's covered |
|----------|-------|----------------|
| macOS | [docs/macos.md](docs/macos.md) | Homebrew, launchd, FileVault, Application Firewall |
| Ubuntu/Debian | [docs/ubuntu-debian.md](docs/ubuntu-debian.md) | apt, systemd, ufw, SSH hardening, fail2ban |
| Docker | [docs/docker.md](docs/docker.md) | Compose, health checks, volumes, container security |
| Oracle OCI | [docs/oracle-oci.md](docs/oracle-oci.md) | ARM free tier, VCN networking, Tailscale |
| Proxmox | [docs/proxmox.md](docs/proxmox.md) | LXC containers, ZFS, bind mounts, clustering |

### Networking & Channels

| Topic | Guide | What's covered |
|-------|-------|----------------|
| Tailscale | [docs/tailscale.md](docs/tailscale.md) | Serve, Funnel, SSH, ACLs, Docker sidecar, Proxmox TUN |
| Telegram | [docs/telegram.md](docs/telegram.md) | BotFather, Grammy, polling vs webhooks |
| Slack | [docs/slack.md](docs/slack.md) | Bolt, Socket Mode, OAuth scopes, app manifests |
| gogcli | [docs/gogcli.md](docs/gogcli.md) | Google Workspace CLI (Drive, Docs, Sheets) |
| All modules | [docs/modules.md](docs/modules.md) | Complete OpenClaw reference — channels, tools, plugins, scheduler |

### Examples

| File | What it is |
|------|-----------|
| [examples/openclaw.json](examples/openclaw.json) | Hardened configuration with comments |
| [examples/docker-compose.yml](examples/docker-compose.yml) | Production Docker Compose with security defaults |
| [examples/proxmox-lxc.sh](examples/proxmox-lxc.sh) | Automated Proxmox LXC provisioning script |

---

## How It Works

Every instruction file (CLAUDE.md, GEMINI.md, CODEX.md) follows the same methodology:

```
1. DETECT platform   — never assume the OS
2. DIAGNOSE first    — non-destructive checks before changes
3. EXECUTE action    — platform-specific commands
4. VERIFY outcome    — confirm the change took effect
```

A [safety gate hook](hooks/sysadmin-safety-gate.sh) blocks dangerous operations in real-time:

- `rm -rf` on system paths
- Exposing OpenClaw gateway to the internet
- `docker compose down -v` (destroys volumes)
- Disabling firewalls entirely
- `tailscale funnel` without confirmation
- Destroying Proxmox VMs/containers

---

## File Structure

```
openclaw-admin/
  CLAUDE.md              # Instructions for Claude Code
  GEMINI.md              # Instructions for Gemini CLI
  CODEX.md               # Instructions for Codex CLI
  SKILL.md               # Portable skill (discovered by skills.sh and claude-octopus)
  persona.md             # Portable persona (used by claude-octopus plugin)
  docs/
    macos.md             # macOS platform guide
    ubuntu-debian.md     # Ubuntu/Debian platform guide
    docker.md            # Docker platform guide
    oracle-oci.md        # Oracle OCI platform guide
    proxmox.md           # Proxmox VE platform guide
    tailscale.md         # Tailscale networking guide
    telegram.md          # Telegram channel setup
    slack.md             # Slack channel setup
    gogcli.md            # Google Workspace CLI
    modules.md           # Complete OpenClaw modules reference
  examples/
    openclaw.json        # Hardened config example
    docker-compose.yml   # Production Docker Compose
    proxmox-lxc.sh       # Automated LXC provisioning
  hooks/
    sysadmin-safety-gate.sh  # Blocks dangerous operations
```

**CLAUDE.md vs SKILL.md vs persona.md** — CLAUDE.md (and GEMINI.md, CODEX.md) are standalone instruction files you drop into any project. SKILL.md and persona.md are structured files used by [skills.sh](https://skills.sh) and the [Claude Octopus](https://github.com/nyldn/claude-octopus) plugin system.

---

## Integration with Claude Octopus

This repo is the source of truth for the `/octo:claw` command. Claude Octopus pulls it in as a git submodule:

```bash
git submodule add https://github.com/nyldn/openclaw-admin.git openclaw-admin
```

The plugin references `openclaw-admin/SKILL.md` and `openclaw-admin/persona.md` from the submodule.

---

## License

MIT — see [LICENSE](LICENSE)
