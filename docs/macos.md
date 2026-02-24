# OpenClaw on macOS

## Prerequisites

- macOS 13 (Ventura) or later
- Intel or Apple Silicon (M1-M4)
- Node.js 22 LTS

```bash
# Install Node.js via Homebrew
brew install node@22
```

## Installation

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
```

The `--install-daemon` flag installs a launchd service at `~/Library/LaunchAgents/com.openclaw.gateway.plist` that auto-starts the Gateway on login.

## Service Management

| Action | Command |
|--------|---------|
| Start | `launchctl start gui/$UID/com.openclaw.gateway` |
| Stop | `launchctl stop gui/$UID/com.openclaw.gateway` |
| Restart | `openclaw gateway restart` |
| Status | `launchctl list \| grep openclaw` |
| Logs | `openclaw logs --follow` |
| Uninstall daemon | `openclaw gateway uninstall` |

## macOS-Specific Administration

### Homebrew

```bash
brew update && brew upgrade         # Update all packages
brew cleanup                        # Remove old versions
brew doctor                         # Diagnose Homebrew issues
brew services list                  # Show managed services
```

### Firewall

```bash
# Check status
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Enable firewall + stealth mode
/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
```

### Security Posture

```bash
fdesetup status         # FileVault (full-disk encryption)
csrutil status          # System Integrity Protection
spctl --status          # Gatekeeper (assessment status)
```

### System Monitoring

```bash
top -l 1 -s 0 | head -12    # CPU/memory snapshot
vm_stat                       # Memory statistics
df -h /                       # Disk usage
iostat -w 1 -c 5              # Disk I/O
nettop -P -m tcp              # Network connections
diskutil info disk0 | grep SMART   # Disk health
```

## Troubleshooting

**Gateway won't start:**
```bash
launchctl list | grep openclaw     # Check if loaded
openclaw doctor --fix              # Auto-fix common issues
log show --predicate 'process == "node"' --last 5m   # Check system logs
```

**Port conflict:**
```bash
lsof -i :18789                     # Find what's using the port
```

**Permission issues after OS upgrade:**
```bash
diskutil resetUserPermissions / $(id -u)
```
