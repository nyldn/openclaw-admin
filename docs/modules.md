# OpenClaw Modules Reference

Complete reference for all OpenClaw subsystems. Use this as a map when managing an OpenClaw instance.

## Architecture Overview

```
OpenClaw Instance
├── Gateway (Node.js WebSocket — 127.0.0.1:18789)
│   ├── REST API + WebSocket endpoints
│   ├── Authentication (token-based)
│   └── Health check (/health)
├── Agent Engine
│   ├── Model routing (Anthropic, OpenAI, Google, custom)
│   ├── Tool execution (sandboxed)
│   └── Session management
├── Channels
│   ├── WhatsApp (Baileys library)
│   ├── Telegram (Grammy library)
│   ├── Discord (discord.js)
│   ├── Slack (Bolt library)
│   ├── Signal (signal-cli or libsignal)
│   └── iMessage (macOS only, AppleScript bridge)
├── Tools
│   ├── Filesystem (read/write/search)
│   ├── Exec (shell commands, patch application)
│   ├── Browser (Playwright, headless or headed)
│   ├── Web Search
│   └── Custom tool plugins
├── Plugins
│   ├── Skills (reusable instruction sets)
│   ├── Hooks (pre/post tool execution)
│   └── MCP servers (Model Context Protocol)
├── Scheduler (cron-style recurring jobs)
├── Memory (project and session context)
└── Extensions (community ecosystem)
```

## Gateway

The gateway is OpenClaw's core — a Node.js WebSocket server that handles all communication.

### Key Config

```json
{
  "gateway": {
    "host": "127.0.0.1",
    "port": 18789,
    "auth": "token"
  }
}
```

### Management

```bash
openclaw gateway start              # Start the gateway
openclaw gateway stop               # Stop gracefully
openclaw gateway restart            # Restart
openclaw gateway install            # Install as system daemon
openclaw gateway uninstall          # Remove daemon
openclaw status [--all|--deep]      # Health overview
openclaw health                     # Quick health check
openclaw doctor [--fix]             # Diagnostics + auto-fix
openclaw logs [--follow]            # Gateway logs
```

### Daemon Locations

| Platform | Path |
|----------|------|
| macOS | `~/Library/LaunchAgents/com.openclaw.gateway.plist` |
| Linux | `~/.config/systemd/user/openclaw-gateway.service` |
| Docker | Managed by `docker compose` |

## Channels

Channels are messaging platform integrations. Each channel connects OpenClaw to a messaging service.

### Supported Channels

| Channel | Library | Event Delivery | DM Support |
|---------|---------|---------------|------------|
| WhatsApp | Baileys (unofficial) | WebSocket (persistent) | Yes, with QR pairing |
| Telegram | Grammy | Long polling or webhooks | Yes, via BotFather bot |
| Discord | discord.js | WebSocket gateway | Yes, via bot account |
| Slack | Bolt | Socket Mode or HTTP | Yes, via Slack app |
| Signal | signal-cli / libsignal | Polling | Yes, via linked device |
| iMessage | AppleScript bridge | Polling (macOS only) | Yes, macOS only |

### Channel Management

```bash
openclaw channels list              # List configured channels
openclaw channels status            # Show connectivity for all
openclaw channels status <channel>  # Check specific channel
openclaw channels add <channel>     # Add a new channel
openclaw channels remove <channel>  # Remove a channel
openclaw channels login <channel>   # Re-authenticate
openclaw channels logout <channel>  # Disconnect
```

### Channel Configuration

```json
{
  "channels": {
    "whatsapp": { "enabled": false, "dmPolicy": "paired" },
    "telegram": { "enabled": false, "dmPolicy": "paired" },
    "discord":  { "enabled": false, "dmPolicy": "paired" },
    "slack":    { "enabled": false, "dmPolicy": "paired" },
    "signal":   { "enabled": false, "dmPolicy": "paired" }
  }
}
```

### DM Policies

| Policy | Behavior |
|--------|----------|
| `paired` | Only pre-approved users can DM (recommended) |
| `open` | Anyone can DM the bot |

```bash
openclaw channels dm-allow <channel> user:@username
openclaw channels info <channel> --dm-list
```

### Per-Channel Guides

- [Telegram Setup](telegram.md) — BotFather, Grammy, polling vs webhooks
- [Slack Setup](slack.md) — Bolt, Socket Mode vs HTTP, OAuth scopes
- WhatsApp — QR code pairing via `openclaw channels login whatsapp`
- Discord — Bot token from Discord Developer Portal
- Signal — Linked device via `openclaw channels login signal`

## Agent Engine

The agent engine routes requests to AI models and manages tool execution.

### Model Configuration

```bash
openclaw models list                # Show configured models
openclaw models status              # Check model connectivity
openclaw models status --probe      # Test each model endpoint
openclaw config set agent.model "anthropic/claude-opus-4-6"
```

### Supported Providers

| Provider | Models | Config Key |
|----------|--------|-----------|
| Anthropic | Claude Opus 4.6, Sonnet 4.6, Haiku 4.5 | `anthropic/claude-*` |
| OpenAI | GPT-5.x, o-series | `openai/gpt-*` |
| Google | Gemini 2.x | `google/gemini-*` |
| Custom | Any OpenAI-compatible API | `custom/<name>` |

### Agent Management

```bash
openclaw agents list                # List configured agents
openclaw agents add                 # Add a new agent profile
openclaw agents delete <name>       # Remove an agent
```

### Sessions

```bash
openclaw sessions list              # Active sessions
openclaw sessions history           # Session history
```

### Session Scoping

```json
{
  "sessions": {
    "scope": "per-channel-peer"
  }
}
```

| Scope | Behavior |
|-------|----------|
| `global` | One session shared across all channels |
| `per-channel` | One session per channel |
| `per-channel-peer` | One session per user per channel (recommended) |

## Tools

Built-in tools that the agent can execute during tasks.

### Filesystem

```json
{
  "tools": {
    "fs": {
      "workspaceOnly": true
    }
  }
}
```

When `workspaceOnly` is true, the agent can only read/write within `~/.openclaw/workspace/`.

### Exec

```json
{
  "tools": {
    "exec": {
      "applyPatch": {
        "workspaceOnly": true
      }
    }
  }
}
```

### Browser

```json
{
  "tools": {
    "browser": {
      "headless": false,
      "noSandbox": false
    }
  }
}
```

Set `headless: true` and `noSandbox: true` for LXC, Docker, or headless servers.

### Sandbox

```json
{
  "tools": {
    "sandbox": {
      "enabled": true,
      "readOnly": true,
      "capDrop": ["ALL"]
    }
  }
}
```

Sandboxing runs agent tool execution in isolated Docker containers.

## Plugins

### Skills

Reusable instruction sets that enhance the agent's capabilities.

```bash
openclaw skills list                # List installed skills
openclaw skills info <name>         # Skill details
openclaw skills check               # Verify skills health
openclaw plugins install <url>      # Install from URL/registry
openclaw plugins doctor             # Check plugin health
```

### Hooks

Hooks run before or after tool execution:

| Hook Type | When It Runs |
|-----------|-------------|
| PreToolUse | Before a tool executes |
| PostToolUse | After a tool executes |
| Stop | When the agent session ends |

### MCP Servers

OpenClaw can connect to Model Context Protocol servers for extended capabilities.

```bash
openclaw mcp list                   # List connected MCP servers
openclaw mcp status                 # Check MCP server health
```

## Scheduler

Cron-style recurring jobs that run agent tasks on a schedule.

```bash
openclaw cron status                # Scheduler daemon status
openclaw cron list                  # List scheduled jobs
openclaw cron add                   # Add a new job
openclaw cron edit <id>             # Edit a job
openclaw cron rm <id>               # Remove a job
openclaw cron logs [<id>]           # View job execution logs
```

### Example: Daily Security Audit

```bash
openclaw cron add \
  --name "daily-security-audit" \
  --schedule "0 6 * * *" \
  --task "Run openclaw security audit --deep and report findings"
```

## Memory

Project and session context persistence.

```bash
openclaw memory list                # List memory entries
openclaw memory search <query>      # Search memory
openclaw memory clear [--scope]     # Clear memory
```

### Memory Types

| Type | Scope | Purpose |
|------|-------|---------|
| Session | Per conversation | Short-term context |
| Project | Per workspace | Project-specific knowledge |
| Global | All projects | Cross-project knowledge |

## Security

### Security Audit

```bash
openclaw security audit             # Basic security scan
openclaw security audit --deep      # Comprehensive scan
openclaw security audit --deep --fix  # Scan and auto-remediate
```

### Security Config

```json
{
  "gateway": { "host": "127.0.0.1", "auth": "token" },
  "tools": {
    "fs": { "workspaceOnly": true },
    "exec": { "applyPatch": { "workspaceOnly": true } },
    "sandbox": { "enabled": true, "readOnly": true, "capDrop": ["ALL"] }
  }
}
```

### Hardening Checklist

1. Gateway loopback only (`127.0.0.1`)
2. Token auth enabled
3. Tailscale/VPN for remote access
4. Filesystem restrictions (`workspaceOnly: true`)
5. Docker sandbox for agent tools
6. DM pairing for unknown senders
7. `openclaw security audit --deep` passes clean
8. `chmod 700 ~/.openclaw/credentials/`
9. SSH: Ed25519 keys, no passwords, fail2ban
10. Model: Opus 4.6 for prompt injection resistance

## Configuration Reference

### File Locations

| Path | Purpose |
|------|---------|
| `~/.openclaw/openclaw.json` | Main configuration (JSON5) |
| `~/.openclaw/credentials/` | API keys and auth tokens |
| `~/.openclaw/workspace/` | Agent workspace data |
| `~/.openclaw/sandboxes/` | Sandbox isolation directories |
| `~/.openclaw/plugins/` | Installed plugins |
| `~/.openclaw/memory/` | Persistent memory store |

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `OPENCLAW_HOME` | Override home directory |
| `OPENCLAW_STATE_DIR` | Override state directory |
| `OPENCLAW_CONFIG` | Override config file path |
| `OPENCLAW_EXTRA_MOUNTS` | Additional Docker mounts for ClawDock |

### CLI Quick Reference

```
openclaw status [--all|--deep]         Gateway health
openclaw health                        Quick health check
openclaw doctor [--fix]                Diagnostics + auto-fix
openclaw logs [--follow]               Gateway logs
openclaw security audit [--deep] [--fix]  Security scan

openclaw gateway start|stop|restart    Service lifecycle
openclaw gateway install|uninstall     Daemon management
openclaw configure                     Interactive config wizard
openclaw update [--channel ...]        Self-update

openclaw channels list|status|add|remove  Messaging channels
openclaw models list|status [--probe]     AI model config
openclaw agents list|add|delete           Agent management
openclaw sessions list|history            Session management
openclaw skills list|info|check           Skills
openclaw plugins list|install|doctor      Plugins
openclaw cron status|list|add|edit|rm     Scheduled jobs
openclaw memory list|search|clear         Memory management
openclaw mcp list|status                  MCP servers
openclaw browser open|close               Browser tool
openclaw nodes list|status                Multi-node (cluster)
```
