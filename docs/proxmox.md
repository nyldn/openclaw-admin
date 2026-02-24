# OpenClaw on Proxmox

## Why Proxmox?

Proxmox VE is ideal for self-hosting OpenClaw: LXC containers are lightweight (less overhead than VMs), behave like a full OS (easier to debug than Docker), and support bind mounts for persistent storage across container destruction.

## LXC vs VM

**LXC is recommended** for OpenClaw:
- Lower overhead than a full VM
- Faster startup
- Easier resource management
- Bind mounts for config persistence

Use a VM only if you need kernel-level isolation or custom kernel modules.

## LXC Setup

### 1. Download Template

```bash
pveam update
pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```

### 2. Create Container

```bash
pct create 200 local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst \
  --hostname openclaw \
  --memory 4096 \
  --cores 2 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1 \
  --features nesting=1 \
  --start 1
```

Recommended resources: 2 cores, 4 GB RAM, 8 GB disk.

### 3. Configure Bind Mounts (Persistence)

Add to `/etc/pve/lxc/200.conf`:

```
mp0: /mnt/openclaw-data,mp=/home/ubuntu/.openclaw
```

Create the host directory:
```bash
mkdir -p /mnt/openclaw-data
chown 100000:100000 /mnt/openclaw-data   # Map to unprivileged container UID
```

This ensures OpenClaw config, credentials, and workspace survive container destruction.

### 4. Install OpenClaw Inside LXC

```bash
pct enter 200

# Inside the container:
apt update && apt install -y curl build-essential

# Install Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon

# Enable linger for systemd user service
loginctl enable-linger ubuntu
```

### 5. Browser Tools Configuration

For browser automation inside LXC, set in `openclaw.json`:

```json
{
  "tools": {
    "browser": {
      "headless": true,
      "noSandbox": true
    }
  }
}
```

### 6. Network Access via Tailscale

```bash
# Inside the container:
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
tailscale serve https / http://127.0.0.1:18789
```

**Never expose port 18789 directly** — always use Tailscale or VPN.

## Proxmox Administration

### Container Management

```bash
pct list                            # List all containers
pct status 200                      # Check container status
pct start/stop/shutdown 200         # Lifecycle
pct enter 200                       # Shell into container
pct config 200                      # View configuration
pct set 200 --memory 8192           # Resize memory
```

### VM Management (If Using VM Instead)

```bash
qm list                             # List all VMs
qm status 100                       # Check VM status
qm start/stop/shutdown 100          # Lifecycle
qm set 100 --memory 8192            # Resize memory
```

### Backup

```bash
# Manual backup
vzdump 200 --mode snapshot --compress zstd --storage local

# Scheduled backups via Proxmox UI or /etc/pve/jobs.cfg
```

### Storage Health

```bash
pvesm status                        # Storage pool status
zpool status                        # ZFS health (if using ZFS)
zpool scrub <pool>                  # Data integrity check (run monthly)
smartctl -a /dev/sdX                # Disk SMART status
```

### Cluster Operations

```bash
pvecm status                        # Cluster status
pvecm expected 1                    # Set expected votes (single-node recovery)
qm migrate 200 node2               # Live migrate VM
pct migrate 200 node2              # Migrate container
```

## Troubleshooting

**Container won't start:**
```bash
pct start 200 2>&1                  # Check error output
journalctl -u pve* --no-pager -n 20  # Proxmox service logs
```

**Storage full:**
```bash
zpool list                          # Check ZFS usage
zfs list -t snapshot                # Find orphaned snapshots
lvs                                 # Check LVM usage
```

**Network issues inside LXC:**
```bash
# Inside container:
ip addr show
ping -c 3 8.8.8.8
resolvectl status
```

**OpenClaw gateway issues inside LXC:**
```bash
pct enter 200
systemctl --user status openclaw-gateway
openclaw doctor --fix
openclaw logs --follow
```

## Automated LXC Provisioning

See [`examples/proxmox-lxc.sh`](../examples/proxmox-lxc.sh) for a script that automates the full setup.
