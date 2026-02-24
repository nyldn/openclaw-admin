# OpenClaw on Ubuntu/Debian

## Prerequisites

- Ubuntu 22.04/24.04 or Debian 12+
- x86_64 or ARM64 architecture
- Node.js 22 LTS

```bash
# Install Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

## Installation

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
```

The `--install-daemon` flag creates a systemd user service at `~/.config/systemd/user/openclaw-gateway.service`.

## Service Management

| Action | Command |
|--------|---------|
| Start | `systemctl --user start openclaw-gateway` |
| Stop | `systemctl --user stop openclaw-gateway` |
| Restart | `systemctl --user restart openclaw-gateway` |
| Status | `systemctl --user status openclaw-gateway` |
| Logs | `journalctl --user -u openclaw-gateway -f` |
| Enable on boot | `loginctl enable-linger $USER` |

## Ubuntu/Debian Administration

### Package Management

```bash
apt update                          # Refresh package lists
apt upgrade -y                      # Install updates
apt full-upgrade -y                 # Upgrade with dependency changes
apt autoremove -y                   # Remove orphaned packages
apt list --upgradable               # Check pending updates
```

### Automatic Security Updates

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure unattended-upgrades
# Config: /etc/apt/apt.conf.d/50unattended-upgrades
```

### Firewall (ufw)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 41641/udp            # Tailscale (if used)
sudo ufw enable
sudo ufw status verbose
```

### SSH Hardening

Edit `/etc/ssh/sshd_config`:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
```

```bash
sudo systemctl restart sshd

# Install fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

### System Monitoring

```bash
free -h                             # Memory usage
df -h                               # Disk usage
systemctl --failed                  # Failed services
journalctl -p err -b                # Errors since boot
ss -tlnp                            # Listening ports
```

## Troubleshooting

**Gateway won't start:**
```bash
systemctl --user status openclaw-gateway
journalctl --user -u openclaw-gateway --no-pager -n 50
openclaw doctor --fix
```

**Broken packages:**
```bash
sudo apt --fix-broken install
sudo dpkg --configure -a
```

**Disk space full:**
```bash
du -sh /var/* | sort -rh | head -10
sudo journalctl --vacuum-size=100M
sudo apt autoremove -y
```
