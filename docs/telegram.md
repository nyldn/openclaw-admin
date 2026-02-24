# Telegram Integration for OpenClaw

## Overview

OpenClaw uses the **Grammy** library (grammy.dev) — a modern TypeScript framework for the Telegram Bot API. Grammy handles message parsing, middleware, error handling, and session management. As a sysadmin, you configure the bot, manage tokens, and troubleshoot connectivity.

## Architecture

```
OpenClaw Gateway (127.0.0.1:18789)
  └─ Channels subsystem
       └─ Telegram channel adapter
            └─ Grammy library (Node.js)
                 └─ Telegram Bot API
                      └─ Telegram clients
```

## Bot Setup

### Step 1: Create a Bot via BotFather

1. Open Telegram and search for `@BotFather`
2. Send `/newbot`
3. Choose a display name (e.g., "OpenClaw Bot")
4. Choose a username ending in `bot` (e.g., `openclaw_prod_bot`)
5. BotFather replies with your **bot token** — save it securely

```
Use this token to access the HTTP API:
123456789:ABCdefGHIjklMNOpqrSTUvwxYZ
```

### Step 2: Configure Bot Settings via BotFather

```
/setdescription   — Set what users see before starting the bot
/setabouttext     — Set the bio text
/setuserpic       — Upload a profile photo
/setcommands      — Register slash commands visible in Telegram UI
/setprivacy       — Toggle group privacy mode (see below)
```

**Group Privacy Mode:**
- **Enabled (default):** Bot only receives messages that @mention it or start with `/`
- **Disabled:** Bot receives ALL messages in a group

For OpenClaw, disable privacy mode if you want the bot to respond to all messages:
```
/setprivacy → Disable
```

### Step 3: Store the Token

```bash
# Set environment variable
export TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrSTUvwxYZ"

# Or store in credentials directory
echo "$TELEGRAM_BOT_TOKEN" > ~/.openclaw/credentials/telegram-token
chmod 600 ~/.openclaw/credentials/telegram-token
```

## OpenClaw Configuration

### Basic Setup

```json
// ~/.openclaw/openclaw.json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "paired"
    }
  }
}
```

### Enable and Verify

```bash
# Enable the channel
openclaw config set channels.telegram.enabled true

# Restart gateway
openclaw gateway restart

# Check status
openclaw channels status telegram
```

## Event Delivery: Polling vs Webhooks

### Long Polling (Default)

Grammy uses **long polling** by default — the bot repeatedly asks Telegram's servers for updates.

**Advantages:**
- No public endpoint needed
- Works behind NAT/firewalls
- Zero networking config

**Disadvantages:**
- Slightly higher latency
- One persistent connection

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "polling": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}"
    }
  }
}
```

### Webhooks

Telegram pushes updates to your HTTPS endpoint.

**Advantages:**
- Lower latency
- More scalable
- Better for production

**Requirements:**
- Public HTTPS endpoint with valid certificate
- Tailscale Funnel or reverse proxy

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "polling": false,
      "webhookUrl": "https://openclaw-server.tailnet-name.ts.net/telegram/webhook",
      "botToken": "${TELEGRAM_BOT_TOKEN}"
    }
  }
}
```

**Setting the webhook manually:**
```bash
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -d "url=https://your-domain.com/telegram/webhook"

# Verify
curl "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo"
```

**Best Practice:**
- **Local/dev/behind firewall:** Use polling
- **Production with public endpoint:** Use webhooks via Tailscale Serve or reverse proxy

## DM Policy

Control who can interact with your bot:

| Policy | Behavior |
|--------|----------|
| `paired` | Only pre-approved users can chat (more secure) |
| `open` | Anyone who finds the bot can chat |

```bash
# Approve a user for DM access
openclaw channels dm-allow telegram user:@username

# Check approved users
openclaw channels info telegram --dm-list
```

## Common Admin Tasks

### Check Bot Status

```bash
openclaw channels status telegram

# Test the bot token directly
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" | python3 -m json.tool
```

### Rotate Bot Token

If your token is compromised:

1. Message `@BotFather` → `/revoke` → select your bot
2. BotFather issues a new token
3. Update your environment/config:
   ```bash
   export TELEGRAM_BOT_TOKEN="new-token-here"
   openclaw gateway restart
   openclaw channels status telegram
   ```

### Register Bot Commands

Make commands visible in Telegram's UI:

```bash
# Via BotFather
/setcommands
# Paste:
help - Show help
status - OpenClaw status
health - Health check

# Or via API
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setMyCommands" \
  -H "Content-Type: application/json" \
  -d '{"commands":[{"command":"help","description":"Show help"},{"command":"status","description":"OpenClaw status"}]}'
```

### Monitor Telegram Channel

```bash
# Live logs filtered to Telegram
openclaw logs --follow | grep -i telegram

# Check for errors
openclaw logs --follow | grep -iE "(telegram|grammy|error)"

# Channel details
openclaw channels info telegram --detailed
```

## Troubleshooting

### Bot Not Responding

```bash
# 1. Check gateway is running
openclaw status

# 2. Check Telegram channel is enabled and connected
openclaw channels status telegram

# 3. Check token validity
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"
# Should return {"ok": true, "result": {...}}

# 4. Check logs for errors
openclaw logs --follow | grep -i telegram

# 5. Check DM policy isn't blocking
openclaw channels info telegram --dm-policy
```

### Webhook Not Working

```bash
# Check webhook status
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo" | python3 -m json.tool

# Look for:
# - "url": should be your HTTPS endpoint
# - "last_error_date": check if there are recent errors
# - "last_error_message": tells you what went wrong
# - "pending_update_count": if high, webhooks are backing up

# Delete webhook and fall back to polling
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/deleteWebhook"
```

### Rate Limiting

Telegram limits bots to ~30 messages/second (per chat: 1 msg/sec in groups, 20 msgs/min in the same group).

```bash
# Check logs for 429 errors
openclaw logs --follow | grep -i "429\|rate.limit\|too.many"

# Grammy handles retries automatically, but if persistent:
# - Reduce message frequency
# - Use inline keyboards instead of multiple messages
# - Consider message batching
```

### Bot Blocked by User

If a user blocks the bot, Telegram returns a 403 Forbidden error when trying to send messages. This is normal — the bot cannot message users who have blocked it.

```bash
# Check logs for 403 errors
openclaw logs --follow | grep -i "403\|forbidden"
```

## Security

1. **Never share your bot token** — it grants full control of the bot
2. **Use `paired` DM policy** — prevents unknown users from interacting
3. **Enable group privacy** — unless you need the bot to see all messages
4. **Store tokens securely** — environment variables or `chmod 600` credential files
5. **Rotate tokens regularly** — via BotFather `/revoke`
6. **Monitor for abuse** — check logs for unusual message patterns

## Quick Reference

```bash
# Enable Telegram
openclaw config set channels.telegram.enabled true
openclaw gateway restart

# Check status
openclaw channels status telegram

# Test token
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"

# Webhook info
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo"

# Set webhook
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -d "url=https://your-domain.com/telegram/webhook"

# Delete webhook (switch to polling)
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/deleteWebhook"

# Logs
openclaw logs --follow | grep -i telegram
```
