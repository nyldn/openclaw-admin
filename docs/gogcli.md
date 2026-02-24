# gogcli — Google Workspace CLI

## Overview

**gogcli** (gogcli.sh) is a Google Workspace CLI tool by Peter Steinberger that provides command-line access to Google Drive, Docs, Sheets, and other Google Workspace services. OpenClaw integrates gogcli as a skill for managing Google Workspace content from the command line.

## Installation

```bash
# Install via the official installer
curl -fsSL https://gogcli.sh/install.sh | bash

# Verify
gogcli --version
```

## Authentication

gogcli uses OAuth 2.0 with Google's API:

```bash
# Interactive authentication
gogcli auth login

# Check auth status
gogcli auth status

# Credential storage
# Tokens are stored in ~/.config/gogcli/ or platform-specific location
```

## Common Operations

### Google Drive

```bash
# List files
gogcli drive list

# Search files
gogcli drive search "quarterly report"

# Download a file
gogcli drive download <file-id> --output ./report.pdf

# Upload a file
gogcli drive upload ./document.pdf --folder <folder-id>
```

### Google Docs

```bash
# Read a document
gogcli docs read <doc-id>

# Export as markdown
gogcli docs export <doc-id> --format markdown
```

### Google Sheets

```bash
# Read a spreadsheet
gogcli sheets read <sheet-id>

# Export as CSV
gogcli sheets export <sheet-id> --format csv
```

## OpenClaw Integration

gogcli is available as an OpenClaw skill, allowing the agent to interact with Google Workspace content during tasks.

### Configuration

```json
// ~/.openclaw/openclaw.json
{
  "skills": {
    "gogcli": {
      "enabled": true,
      "credentialPath": "~/.config/gogcli/"
    }
  }
}
```

### Use Cases with OpenClaw

- **Research tasks**: Agent reads Google Docs/Sheets as context for work
- **Report generation**: Agent writes results to Google Sheets
- **Document management**: Agent organizes Drive files as part of workflows
- **Data extraction**: Agent pulls data from Sheets for analysis

## Sysadmin Tasks

### Verify Installation

```bash
# Check gogcli is available
command -v gogcli &>/dev/null && gogcli --version || echo "gogcli not installed"

# Check authentication
gogcli auth status
```

### Credential Management

```bash
# Credentials location
ls -la ~/.config/gogcli/

# Permissions should be restrictive
chmod 700 ~/.config/gogcli/
chmod 600 ~/.config/gogcli/*

# Re-authenticate if tokens expired
gogcli auth login --force
```

### Troubleshooting

```bash
# Check if Google API is reachable
curl -s -o /dev/null -w "%{http_code}" https://www.googleapis.com/discovery/v1/apis

# Check token validity
gogcli auth status --verbose

# Clear cached tokens and re-auth
gogcli auth logout
gogcli auth login
```

## Security

1. **Restrict credential permissions** — `chmod 700 ~/.config/gogcli/`
2. **Use service accounts for automation** — avoid personal OAuth tokens in production
3. **Limit API scopes** — only request scopes gogcli actually needs
4. **Audit access** — review Google Workspace admin console for API access logs
5. **Rotate credentials** — re-authenticate periodically
