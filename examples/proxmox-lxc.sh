#!/bin/bash
# Automated Proxmox LXC provisioning for OpenClaw
# Run on the Proxmox host (not inside the container)
#
# Usage: ./proxmox-lxc.sh [CTID] [HOSTNAME]
# Example: ./proxmox-lxc.sh 200 openclaw

set -euo pipefail

CTID="${1:-200}"
HOSTNAME="${2:-openclaw}"
TEMPLATE="ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
STORAGE="local-lvm"
MEMORY=4096
CORES=2
DISK_SIZE=8
DATA_DIR="/mnt/openclaw-data-${CTID}"

echo "=== OpenClaw Proxmox LXC Provisioner ==="
echo "CTID: ${CTID}"
echo "Hostname: ${HOSTNAME}"
echo "Resources: ${CORES} cores, ${MEMORY}MB RAM, ${DISK_SIZE}GB disk"
echo ""

# Step 1: Download template if needed
if ! pveam list local | grep -q "${TEMPLATE}"; then
    echo ">>> Downloading template..."
    pveam update
    pveam download local "${TEMPLATE}"
fi

# Step 2: Create persistent data directory on host
echo ">>> Creating persistent data directory at ${DATA_DIR}..."
mkdir -p "${DATA_DIR}"
chown 100000:100000 "${DATA_DIR}"  # Map to unprivileged container UID

# Step 3: Create container
echo ">>> Creating LXC container ${CTID}..."
pct create "${CTID}" "local:vztmpl/${TEMPLATE}" \
    --hostname "${HOSTNAME}" \
    --memory "${MEMORY}" \
    --cores "${CORES}" \
    --rootfs "${STORAGE}:${DISK_SIZE}" \
    --net0 "name=eth0,bridge=vmbr0,ip=dhcp" \
    --unprivileged 1 \
    --features "nesting=1" \
    --mp0 "${DATA_DIR},mp=/home/ubuntu/.openclaw"

# Step 4: Start container
echo ">>> Starting container..."
pct start "${CTID}"

# Wait for container to be ready
sleep 5

# Step 5: Install dependencies inside container
echo ">>> Installing dependencies..."
pct exec "${CTID}" -- bash -c '
    apt update -qq
    apt install -y -qq curl build-essential ca-certificates

    # Install Node.js 22
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt install -y -qq nodejs

    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
'

# Step 6: Install OpenClaw
echo ">>> Installing OpenClaw..."
pct exec "${CTID}" -- bash -c '
    su - ubuntu -c "curl -fsSL https://openclaw.ai/install.sh | bash"
    su - ubuntu -c "openclaw --version"
'

# Step 7: Configure for headless LXC
echo ">>> Configuring for headless LXC..."
pct exec "${CTID}" -- bash -c '
    su - ubuntu -c "openclaw config set tools.browser.headless true"
    su - ubuntu -c "openclaw config set tools.browser.noSandbox true"
    su - ubuntu -c "openclaw config set gateway.host 127.0.0.1"
'

# Step 8: Install daemon and enable linger
echo ">>> Setting up systemd service..."
pct exec "${CTID}" -- bash -c '
    su - ubuntu -c "openclaw onboard --install-daemon"
    loginctl enable-linger ubuntu
'

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Container ${CTID} (${HOSTNAME}) is running with OpenClaw installed."
echo "Persistent data stored at: ${DATA_DIR}"
echo ""
echo "Next steps:"
echo "  1. Enter container:  pct enter ${CTID}"
echo "  2. Run onboarding:   su - ubuntu -c 'openclaw configure'"
echo "  3. Install Tailscale: curl -fsSL https://tailscale.com/install.sh | sh && tailscale up"
echo "  4. Expose gateway:   tailscale serve https / http://127.0.0.1:18789"
echo ""
echo "IMPORTANT: Do NOT expose port 18789 directly. Use Tailscale for access."
