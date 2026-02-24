# OpenClaw on Oracle OCI

## Why OCI?

Oracle Cloud's Always Free tier provides ARM instances (`VM.Standard.A1.Flex`) with up to 4 OCPUs and 24 GB RAM — more than enough for OpenClaw. The ARM architecture is fully supported.

## Prerequisites

- Oracle Cloud account (upgrade to Pay As You Go to prevent idle reclamation — free resources stay free)
- OCI CLI installed (`oci setup config`)

## Instance Setup

### 1. Create VCN First

Create the VCN **before** the instance (otherwise public IP option gets grayed out):

```bash
oci network vcn create \
  --compartment-id <compartment-ocid> \
  --display-name openclaw-vcn \
  --cidr-blocks '["10.0.0.0/16"]'
```

Create a public subnet and internet gateway, then add a route table entry.

### 2. Create Instance

```bash
oci compute instance launch \
  --compartment-id <compartment-ocid> \
  --shape VM.Standard.A1.Flex \
  --shape-config '{"ocpus": 2, "memoryInGBs": 12}' \
  --image-id <ubuntu-24.04-aarch64-image-ocid> \
  --subnet-id <subnet-ocid> \
  --assign-public-ip true \
  --display-name openclaw-server
```

Recommended: 2 OCPUs, 12 GB RAM (within free allocation).

### 3. Security Lists

Strip all ingress rules except:
- SSH (port 22) from your IP only (temporary, remove after Tailscale)
- Tailscale UDP 41641 from 0.0.0.0/0

```bash
# After Tailscale is configured, remove SSH ingress rule
# Access exclusively via Tailscale
```

### 4. Install OpenClaw

SSH into the instance:

```bash
# Install build dependencies (required for ARM)
sudo apt update && sudo apt install -y build-essential curl

# Install Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
```

### 5. Enable Persistent Service

```bash
# Enable linger so systemd user services survive logout
loginctl enable-linger $USER
```

### 6. Set Up Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Expose gateway via Tailscale Serve (HTTPS over tailnet)
tailscale serve https / http://127.0.0.1:18789
```

Now access OpenClaw at `https://<hostname>.<tailnet>.ts.net/`.

## OCI Administration

### Instance Management

```bash
oci compute instance list --compartment-id <ocid> --output table
oci compute instance action --action SOFTRESET --instance-id <ocid>
oci compute instance action --action STOP --instance-id <ocid>
```

### Networking

```bash
oci network security-list list --compartment-id <ocid>
oci network nsg rules list --nsg-id <ocid>
```

### Block Volumes

```bash
oci bv volume list --compartment-id <ocid>
oci bv backup create --volume-id <ocid> --display-name "openclaw-backup"
```

## ARM Considerations

- Most npm packages work on ARM64, but some native addons may need compilation
- `build-essential` is mandatory for compilation dependencies
- If a package fails, check for ARM-specific issues in its repo

## Troubleshooting

**Instance unreachable:**
1. Check VCN security lists (allow SSH or Tailscale)
2. Check route table has internet gateway
3. Verify public IP is assigned
4. Check OS-level firewall (`ufw status`)

**Out of capacity:**
- Try a different Availability Domain
- Try a smaller shape, then resize later

**Idle reclamation:**
- Upgrade to Pay As You Go (free resources remain free, prevents reclamation of idle instances)
