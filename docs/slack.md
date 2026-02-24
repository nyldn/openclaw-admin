# Slack Integration & OpenClaw Channel Administration

**Version:** 1.0
**Last Updated:** February 2026
**Audience:** System Administrators managing OpenClaw instances with Slack channels

---

## Overview

This document provides practical, sysadmin-focused guidance for integrating Slack with OpenClaw, managing Slack bots as messaging channels, and troubleshooting common issues. This is **not** a developer API guide—it focuses on operational tasks.

**Key Principle:** Slack integration in OpenClaw uses the Bolt library for Node.js, which abstracts away complexity. As a sysadmin, you manage configuration, credentials, permissions, and channel lifecycle.

---

## 1. How OpenClaw Integrates with Slack

### Architecture Overview

```
OpenClaw Gateway (127.0.0.1:18789)
  └─ Channels subsystem
       └─ Slack channel adapter
            └─ Slack Bolt library (Node.js)
                 └─ Slack API (WebSocket or HTTP)
                      └─ Your Slack workspace
```

### The Slack Bolt Library

OpenClaw uses **Slack Bolt for JavaScript** (Node.js), which is Slack's official framework for building bots and apps. Bolt handles:

- OAuth authentication and token management
- Event subscriptions (messages, reactions, mentions)
- Slash command routing
- Interactive component handlers (buttons, select menus)
- Error handling and retry logic
- Socket Mode or HTTP event delivery

**Key Benefit:** Bolt abstracts the complexity of the Slack API. You configure it via `openclaw.json`, and the framework handles the rest.

### Event Delivery Modes

Slack supports two ways to deliver events to OpenClaw:

| Mode | How It Works | Best For |
|------|-------------|----------|
| **Socket Mode** | WebSocket connection (persistent, stateful) | Development, behind firewalls, easier setup |
| **HTTP Mode** | Slack sends POST requests to your public endpoint | Production, scale, when you have stable HTTPS endpoint |

OpenClaw defaults to **Socket Mode** for ease of deployment (especially on local machines, behind NATs, or in restricted networks).

---

## 2. Slack App Setup: Creating Apps, OAuth Tokens, Bot Tokens, and Scopes

### Step 1: Create a Slack App

1. **Go to [api.slack.com/apps](https://api.slack.com/apps)**
2. **Click "Create New App"**
   - Choose "From an app manifest" (recommended for repeatability)
   - Select your workspace
3. **Paste the app manifest** (see below) or build manually

### Step 2: App Manifest (Recommended)

An **app manifest** is a YAML file that defines your app's configuration, scopes, and event subscriptions. Here's a minimal example:

```yaml
# slack-app-manifest.yaml
display_information:
  name: OpenClaw Bot
description: OpenClaw integration for multi-channel messaging
features:
  bot_user:
    display_name: openclaw-bot
    always_online: true
  slash_commands:
    - command: /openclaw
      description: Interact with OpenClaw
      usage_hint: "[command] [args]"
oauth_config:
  scopes:
    bot:
      - chat:write                 # Send messages
      - chat:write.public          # Send to public channels
      - app_mentions:read          # Receive @mentions
      - message_metadata:read      # Read message metadata
      - channels:read              # List channels
      - groups:read                # List private channels
      - im:read                    # Read direct messages
      - reactions:read             # Read reactions
      - users:read                 # List workspace users
settings:
  event_subscriptions:
    bot_events:
      - message.channels           # Messages in public channels
      - message.groups             # Messages in private channels
      - message.im                 # Direct messages
      - app_mention                # Bot mentions
      - reaction_added             # User reactions
  interactivity:
    is_enabled: true
    request_url: "https://your-public-domain.com/slack/events"  # HTTP mode only
```

### Step 3: OAuth Token Types

Slack uses **OAuth 2.0** to manage app permissions. When you install the app, you receive tokens:

| Token Type | Purpose | When Created | Scope |
|-----------|---------|------------|-------|
| **Bot Token** | App's bot user identity in the workspace | At install time | Specified in manifest or scopes |
| **App-Level Token** | Manages app across workspaces (Socket Mode) | Manually generated | `connections:write` required for Socket Mode |
| **User Token** | Tied to a user's permissions (rarely used by bots) | User-initiated OAuth flow | User's permission scope |

### Step 4: Extract OAuth Tokens

**For Socket Mode (OpenClaw default):**

```bash
# 1. Bot Token (generated at install)
# Go to: api.slack.com/apps → Your App → OAuth & Permissions
# Copy: "Bot User OAuth Token" (starts with xoxb-)

# 2. App-Level Token (for Socket Mode)
# Go to: api.slack.com/apps → Your App → App-Level Tokens
# Click: "Generate Token and Scopes"
# Add scope: "connections:write"
# Copy token (starts with xapp-)

# Store securely:
export SLACK_BOT_TOKEN="xoxb-..."
export SLACK_APP_TOKEN="xapp-..."
```

**For HTTP Mode:**

Only need the Bot Token. Slack will send POST requests to your HTTPS endpoint.

### Step 5: OAuth Scopes Explained

Scopes are granular permissions that control what the bot can do:

| Scope | Allows Bot To |
|-------|---------------|
| `chat:write` | Send messages |
| `chat:write.public` | Send to any public channel |
| `app_mentions:read` | Receive mentions (@bot) |
| `message_metadata:read` | Read message metadata |
| `channels:read` | List public channels |
| `groups:read` | List private channels |
| `im:read` | Read direct messages |
| `reactions:read` | See reactions |
| `users:read` | List workspace users |
| `admin.apps:write` | Manage app installs (Enterprise Grid only) |
| `admin.users:write` | Manage users (Enterprise Grid only) |

**Scope Perspectives (optional suffixes):**

- `:bot` — Action performed by bot user (default)
- `:user` — Action performed as the authorizing user
- `:app` — Action performed by the app itself

Example: `chat:write` (bot perspective, default) vs `chat:write:user` (user perspective).

### Step 6: Install the App

1. Go to OAuth & Permissions
2. Click "Install to Workspace"
3. Approve the requested scopes
4. You'll see the Bot Token and redirected to settings

**After Installation:**

- Bot user appears in workspace member list
- Bot is not automatically in channels—you must invite it or join channels manually
- Tokens are stored; keep them secret

---

## 3. Key Slack Concepts for Sysadmins

### Workspace

A **workspace** is a Slack organization. Multiple teams work in one workspace. Your app is installed per workspace, meaning you get separate tokens for each workspace.

**Sysadmin Task:** If managing multiple Slack workspaces, install the app in each and store credentials separately.

### Channels

Slack has two types of channels:

| Type | Privacy | Bot Access | Use Case |
|------|---------|-----------|----------|
| **Public Channels** | Visible to all members | Must be invited or join explicitly | Announcements, team coordination |
| **Private Channels** | Hidden from non-members | Must be invited explicitly | Sensitive discussions, team-only |

**Important:** Bots are not auto-added to channels. You must:
1. Invite the bot (`/invite @openclaw-bot`)
2. Or have the bot join via explicit command

### Bot Users

A **bot user** is a special account that represents your app. It has:

- Display name (e.g., "openclaw-bot")
- Avatar and status
- DM capability (can receive/send direct messages)
- No email or password (authenticated via token)

**Sysadmin Task:** Set bot display name clearly so users know it's a bot, not a person.

### Direct Messages (DMs)

Bots can receive and send DMs. Configure via:

```json
// openclaw.json
"channels": {
  "slack": {
    "enabled": true,
    "dmPolicy": "paired"  // or "open"
  }
}
```

- `"paired"` — Only accept DMs from users who've been explicitly paired (more secure)
- `"open"` — Accept DMs from any user

### App Manifests

An **app manifest** is a YAML blueprint defining:

- Display name, description, icon
- OAuth scopes and permissions
- Event subscriptions
- Slash commands
- Interactivity settings

**Benefit:** Manifests are version-controllable and repeatable across workspaces.

---

## 4. Socket Mode vs HTTP Mode for Event Delivery

### Socket Mode (OpenClaw Default)

**How It Works:**
1. Your OpenClaw instance initiates a **persistent WebSocket connection** to Slack
2. Slack sends events through the WebSocket (no public endpoint needed)
3. App-Level Token with `connections:write` scope required

**Advantages:**
- No public HTTPS endpoint required (great for dev, local, behind firewalls)
- Easier to set up (no DNS, SSL certificates)
- WebSocket URL is dynamically generated and refreshed
- Works behind corporate proxies/NATs

**Disadvantages:**
- Not recommended for production scale
- Less reliable than HTTP (single persistent connection)
- Harder to debug (WebSocket is persistent, not individual requests)

**Setup:**
```json
// openclaw.json
"channels": {
  "slack": {
    "enabled": true,
    "socketMode": true,
    "appToken": "${SLACK_APP_TOKEN}",  // xapp-...
    "botToken": "${SLACK_BOT_TOKEN}"    // xoxb-...
  }
}
```

### HTTP Mode

**How It Works:**
1. Slack sends POST requests to your public HTTPS endpoint
2. Your endpoint responds with HTTP 200 OK
3. Process events asynchronously (queue them)

**Advantages:**
- Recommended for production
- More reliable (HTTP is stateless)
- Easier to scale (load balancer friendly)
- Better observability (individual requests in logs)

**Disadvantages:**
- Requires public HTTPS endpoint (DNS, SSL cert)
- You must handle retries and backoff
- Firewall/proxy rules must allow inbound HTTPS

**Setup:**
```json
// openclaw.json
"channels": {
  "slack": {
    "enabled": true,
    "socketMode": false,
    "requestUrl": "https://your-domain.com/slack/events",
    "botToken": "${SLACK_BOT_TOKEN}"    // xoxb-...
  }
}
```

**Best Practice:**
- **Dev/Local:** Use Socket Mode
- **Production:** Use HTTP mode with HTTPS + firewall rules

---

## 5. Common Slack Admin Tasks

### Task: Add Slack Channel to OpenClaw

**Step 1: Verify bot token and app token (for Socket Mode)**

```bash
# Check tokens are set
echo $SLACK_BOT_TOKEN
echo $SLACK_APP_TOKEN

# Both should output non-empty values starting with xoxb- and xapp-
```

**Step 2: Enable Slack channel in openclaw.json**

```bash
# Backup config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

# Edit config (add or update slack section)
cat > ~/.openclaw/openclaw.json <<EOF
{
  "channels": {
    "slack": {
      "enabled": true,
      "socketMode": true,
      "appToken": "$SLACK_APP_TOKEN",
      "botToken": "$SLACK_BOT_TOKEN",
      "dmPolicy": "paired"
    }
  }
}
EOF
```

**Step 3: Restart OpenClaw gateway**

```bash
openclaw gateway restart

# Verify connection
openclaw channels status slack

# Should show: "Slack channel connected"
```

**Step 4: Invite bot to Slack channels**

In Slack, for each channel you want to use:

```
/invite @openclaw-bot
```

Or manually:
1. Click channel name
2. "Members" tab
3. "Add members"
4. Select "openclaw-bot"

### Task: Manage Channel Permissions

**See what the bot can do in each channel:**

```bash
# List channels bot is in
openclaw channels info slack --channels

# Check bot's role in a specific channel
# (In Slack, click channel → Members → look for @openclaw-bot)
```

**Restrict bot to specific channels:**

Use Slack's channel settings (not OpenClaw config):

1. Go to channel settings
2. "Integrations" tab
3. Remove the bot if not needed, or keep it as "Member"

### Task: Manage DM Policy

**Allow DMs from specific users only (secure):**

```json
// openclaw.json
"channels": {
  "slack": {
    "dmPolicy": "paired"  // Only pre-approved users
  }
}
```

To approve a user for DM:
```bash
openclaw channels dm-allow slack user:@someone
```

**Allow DMs from anyone:**

```json
// openclaw.json
"channels": {
  "slack": {
    "dmPolicy": "open"  // Any user can DM
  }
}
```

### Task: Rotate OAuth Tokens

If you suspect a token is compromised:

1. **Go to Slack app settings:** api.slack.com/apps → Your App → OAuth & Permissions
2. **Click "Regenerate" next to Bot Token**
3. **Copy the new token:**
   ```bash
   export SLACK_BOT_TOKEN="xoxb-[new-token]"
   ```
4. **Update openclaw.json** and restart gateway:
   ```bash
   openclaw gateway restart
   ```
5. **Verify connection:**
   ```bash
   openclaw channels status slack
   ```

### Task: Monitor Slack Channel Health

```bash
# Check if Slack connection is alive
openclaw channels status slack

# View real-time logs
openclaw logs --follow | grep -i slack

# Check token validity (timestamps and expiry)
openclaw channels info slack --detailed

# Test message send
openclaw channels test slack --channel general --message "OpenClaw test"
```

---

## 6. OpenClaw-Specific Slack Configuration

### Configuration File Location

```
~/.openclaw/openclaw.json
```

### Full Slack Configuration Example

```json
{
  "channels": {
    "slack": {
      // Enable/disable Slack integration
      "enabled": true,

      // Event delivery method
      "socketMode": true,

      // Socket Mode tokens (if socketMode: true)
      "appToken": "${SLACK_APP_TOKEN}",    // xapp-... (app-level token)
      "botToken": "${SLACK_BOT_TOKEN}",    // xoxb-... (bot token)

      // HTTP Mode endpoint (if socketMode: false)
      "requestUrl": "https://your-domain.com/slack/events",

      // Who can DM the bot?
      "dmPolicy": "paired",  // "paired" or "open"

      // Channels to auto-join (optional)
      "autoJoinChannels": [
        "general",
        "alerts",
        "ops"
      ],

      // Rate limiting
      "rateLimit": {
        "messagesPerSecond": 1,
        "burstSize": 5
      },

      // Message formatting
      "formatting": {
        "threadedReplies": true,  // Reply in thread vs new message
        "blockKitSupport": true   // Use Slack's rich formatting (Block Kit)
      }
    }
  }
}
```

### Environment Variable Substitution

Use environment variables for sensitive values:

```bash
# Set in ~/.bashrc or ~/.zshrc or environment
export SLACK_APP_TOKEN="xapp-..."
export SLACK_BOT_TOKEN="xoxb-..."

# openclaw.json will substitute ${SLACK_APP_TOKEN} at runtime
```

### Verify Configuration

```bash
openclaw config get channels.slack

# Output:
# {
#   "enabled": true,
#   "socketMode": true,
#   "botToken": "xoxb-... (redacted)",
#   "appToken": "xapp-... (redacted)",
#   ...
# }
```

---

## 7. Troubleshooting Slack Channel Issues

### Issue: "Slack channel disconnected"

**Symptom:** `openclaw channels status slack` shows "disconnected"

**Cause:** Bot token or app token expired/invalid, Socket Mode connection lost, network issue

**Troubleshooting:**

```bash
# 1. Check logs for errors
openclaw logs --follow | grep -i slack

# 2. Verify tokens are set
echo "Bot token: $SLACK_BOT_TOKEN"
echo "App token: $SLACK_APP_TOKEN"

# 3. Verify tokens are valid (go to api.slack.com/apps → OAuth & Permissions)
# Tokens should NOT be "expired" or show red warning

# 4. Restart gateway
openclaw gateway restart

# 5. Check if tokens need rotation
# If very old, rotate them via Slack app settings
```

### Issue: "Bot not responding in Slack channels"

**Symptom:** Messages sent to OpenClaw via Slack are not getting responses

**Cause:** Permissions missing, bot not in channel, DM policy blocking, configuration issue

**Troubleshooting:**

```bash
# 1. Verify bot is in the channel
# (In Slack: click channel name → Members → look for @openclaw-bot)

# 2. Check bot permissions
openclaw channels info slack --permissions

# 3. Verify OpenClaw is listening on Slack
openclaw logs --follow

# 4. Test with a simple message
/openclaw help

# If no response:
# - Bot may not be in channel (invite it)
# - Permissions may be restricted (check scopes)
# - OpenClaw gateway may not be running (openclaw status)
```

### Issue: "Bot not receiving DMs"

**Symptom:** Direct messages to bot are ignored

**Cause:** DM policy too restrictive, bot not paired with user, channel disabled

**Troubleshooting:**

```bash
# 1. Check DM policy
openclaw channels info slack --dm-policy

# 2. If policy is "paired", the user must be approved first
openclaw channels dm-allow slack user:@yourname

# 3. Try again to send DM

# 4. Check logs
openclaw logs --follow | grep -i dm

# 5. If still not working, try "open" policy (less secure)
# openclaw config set channels.slack.dmPolicy open
# openclaw gateway restart
```

### Issue: "Slack app not approved in workspace"

**Symptom:** Attempting to install app, but getting "org policy blocks this"

**Cause:** Workspace Owner or Enterprise Grid admin has restricted app installations

**Troubleshooting:**

- Ask Slack workspace Owner to approve the app:
  1. Workspace Owner goes to "Apps" → "Manage" → "Pending Requests"
  2. Finds your app request
  3. Clicks "Approve"

- Or ask admin to allow the app globally:
  1. Admin goes to "Workspace Settings" → "Manage Apps"
  2. Finds the app
  3. Clicks "Approve"

### Issue: "Permission denied" when sending messages

**Symptom:** Bot gets 403 Forbidden errors when trying to send messages

**Cause:** Bot not invited to channel, missing `chat:write` scope, channel restricted

**Troubleshooting:**

```bash
# 1. Verify bot has chat:write scope
openclaw channels info slack --scopes
# Should include: "chat:write", "chat:write.public"

# 2. Invite bot to channel (in Slack)
/invite @openclaw-bot

# 3. Check if channel allows external apps
# (In Slack: channel settings → "Apps" → check if OpenClaw is allowed)

# 4. Restart after making changes
openclaw gateway restart
```

### Issue: "Socket connection closed unexpectedly"

**Symptom:** Logs show "WebSocket closed" repeatedly

**Cause:** Network connectivity issue, app token expired, Socket Mode not enabled

**Troubleshooting:**

```bash
# 1. Verify Socket Mode is enabled in API settings
# api.slack.com/apps → Your App → Socket Mode → toggle "Enabled"

# 2. Verify app token has connections:write scope
# api.slack.com/apps → App-Level Tokens → check scope

# 3. Test network connectivity to Slack
curl -I https://slack.com

# 4. Regenerate app token if old
# api.slack.com/apps → App-Level Tokens → "Regenerate"

# 5. Update openclaw.json with new token and restart
export SLACK_APP_TOKEN="xapp-[new-token]"
openclaw gateway restart
```

---

## 8. Security Considerations for Slack Bots

### Token Security

**DO:**
- Store tokens in environment variables or credential files (chmod 600)
- Rotate tokens regularly (every 3-6 months)
- Use separate tokens per workspace (don't share)
- Store app-level tokens separately from bot tokens

**DON'T:**
- Commit tokens to git repositories (use .gitignore)
- Log tokens in debug output (OpenClaw redacts them automatically)
- Share tokens via Slack or email
- Use the same token in dev and production

### Scope Management

**Principle of Least Privilege:**

- Only request scopes your bot actually needs
- Remove unused scopes regularly
- Don't request admin scopes unless required (e.g., `admin.users:write`)

**Example minimal scopes:**
```yaml
scopes:
  bot:
    - chat:write              # Send messages
    - app_mentions:read       # Receive mentions
    - message_metadata:read   # Read message metadata
    - channels:read           # List channels
    - im:read                 # Read DMs
```

### Permissions and Roles

**Slack Workspace Roles:**

| Role | Permissions |
|------|------------|
| **Owner** | Full access, install apps, manage users |
| **Admin** | Manage apps, users, settings (can't access private channels without invitation) |
| **Member** | Send messages, use apps (can install non-admin apps) |
| **Guest** | Limited (depends on channel settings) |

**Sysadmin Task:** Work with Slack Owner/Admin to approve OpenClaw bot for workspace.

### DM Policy Security

- `"paired"` (recommended) — Only pre-approved users can DM bot (more secure)
- `"open"` — Any user can DM bot (easier but less secure)

**For sensitive operations:** Use `"paired"` and manually approve trusted users.

### Network Security

**If running behind firewall:**
- Use Socket Mode (no inbound port exposure)
- Never expose port 18789 to the internet
- Use Tailscale or VPN for remote access

**If using HTTP mode:**
- Require HTTPS only (no HTTP)
- Use a reverse proxy (Nginx, Caddy)
- Restrict by IP if possible

### Auditing

Monitor who has access to OpenClaw's Slack integration:

```bash
# See who's approved for DMs
openclaw channels info slack --dm-list

# Check what channels bot is in
openclaw channels info slack --channels

# View recent actions
openclaw logs --follow | grep slack
```

---

## 9. Appendix: Quick Reference

### Installation Checklist

- [ ] Create Slack app at api.slack.com/apps
- [ ] Use app manifest for repeatability
- [ ] Install app in workspace (approve scopes)
- [ ] Copy Bot Token (`xoxb-...`)
- [ ] Generate App-Level Token for Socket Mode (`xapp-...`)
- [ ] Set environment variables: `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`
- [ ] Update `~/.openclaw/openclaw.json` with tokens
- [ ] Restart OpenClaw: `openclaw gateway restart`
- [ ] Verify connection: `openclaw channels status slack`
- [ ] Invite bot to channels: `/invite @openclaw-bot`

### Common Commands

```bash
# List channels
openclaw channels list

# Check Slack status
openclaw channels status slack

# View Slack channel info
openclaw channels info slack

# Test send message
openclaw channels test slack --channel general --message "Test"

# Enable/disable Slack
openclaw config set channels.slack.enabled true
openclaw config set channels.slack.enabled false

# View logs
openclaw logs --follow | grep slack

# Restart gateway
openclaw gateway restart
```

### File Paths

| Path | Purpose |
|------|---------|
| `~/.openclaw/openclaw.json` | Main OpenClaw config (includes Slack) |
| `~/.openclaw/credentials/slack.json` | Slack tokens (if stored locally) |
| `/var/log/openclaw.log` | OpenClaw log file |

### External Resources

- [Slack Bolt for JavaScript](https://slack.dev/bolt-js/)
- [Slack API Documentation](https://api.slack.com/)
- [Socket Mode Documentation](https://api.slack.com/apis/socket-mode)
- [Slack App Scopes Reference](https://api.slack.com/scopes)
- [Slack Security Best Practices](https://api.slack.com/authentication/best-practices)

---

## Sources & References

This guide was compiled from:

1. [Slack Bolt for JavaScript - Quickstart](https://slack.dev/bolt-js/tutorial/getting-started)
2. [Slack Events API - Using Socket Mode](https://docs.slack.dev/apis/events-api/using-socket-mode/)
3. [Slack Events API - Comparing HTTP & Socket Mode](https://docs.slack.dev/apis/events-api/comparing-http-socket-mode/)
4. [Slack OAuth & Token Documentation](https://docs.slack.dev/authentication/tokens/)
5. [Slack Permission Scopes Reference](https://api.slack.com/scopes)
6. [Slack App Manifest Guide](https://docs.slack.dev/reference/manifests)
7. [Slack Workspace App Management](https://slack.com/help/articles/222386767-Manage-app-approval-for-your-workspace)
8. [Slack Security Best Practices](https://api.slack.com/authentication/best-practices)
9. [Slack CLI Error Troubleshooting](https://docs.slack.dev/tools/slack-cli/reference/errors/)
10. OpenClaw Configuration Documentation (`~/.openclaw/openclaw.json`)

---

**Questions?** Contact your OpenClaw administrator or check `/openclaw help channels slack`.
