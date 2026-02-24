# OpenClaw Cloudflare Worker Architecture

This document describes the complete architecture for running OpenClaw in a Cloudflare Worker with persistent config and secrets.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cloudflare Account                           │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Worker Secrets │  │   KV Namespace  │  │    R2 Bucket    │ │
│  │  (per-worker)   │  │ (account-level) │  │ (account-level) │ │
│  │                 │  │                 │  │                 │ │
│  │ DISCORD_BOT_    │  │ channels/       │  │ openclaw/       │ │
│  │   TOKEN         │  │   discord       │  │   workspace/    │ │
│  │ ANTHROPIC_      │  │ channels/       │  │   openclaw.json │ │
│  │   API_KEY       │  │   telegram      │  │   scripts/      │ │
│  │ CLOUDFLARE_     │  │ preferences/*   │  │                 │ │
│  │   API_TOKEN     │  │                 │  │                 │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                    │          │
│           └────────────────────┼────────────────────┘          │
│                                │                               │
│                    ┌───────────▼───────────┐                   │
│                    │   Cloudflare Worker   │                   │
│                    │   (moltbot-sandbox)   │                   │
│                    │                       │                   │
│                    │  - Injects secrets    │                   │
│                    │  - Mounts R2 bucket   │                   │
│                    │  - Proxies requests   │                   │
│                    └───────────┬───────────┘                   │
│                                │                               │
│                    ┌───────────▼───────────┐                   │
│                    │  Sandbox Container    │                   │
│                    │                       │                   │
│                    │  start-openclaw.sh:   │                   │
│                    │  1. Restore from R2   │                   │
│                    │  2. Fetch KV config   │                   │
│                    │  3. Merge with secrets│                   │
│                    │  4. Start gateway     │                   │
│                    └───────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

## Storage Layers

### 1. Worker Secrets (Sensitive Tokens)

**Location:** Per-worker, set via `wrangler secret put` or `/_admin/` panel

**Purpose:** API keys, tokens, credentials that should never be logged or exposed

**How to set:**
```bash
wrangler secret put DISCORD_BOT_TOKEN
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put CLOUDFLARE_API_TOKEN
```

**Current secrets for this worker:**

| Secret | Purpose | Required |
|--------|---------|----------|
| `ANTHROPIC_API_KEY` | Claude API access | Yes (or OPENAI_API_KEY) |
| `OPENAI_API_KEY` | OpenAI API access | Yes (or ANTHROPIC_API_KEY) |
| `GEMINI_API_KEY` | Gemini API access | Optional |
| `CLOUDFLARE_API_TOKEN` | KV/API access from container | Yes |
| `CF_ACCOUNT_ID` | Cloudflare account ID | Yes |
| `DISCORD_BOT_TOKEN` | Discord bot | Optional |
| `TELEGRAM_BOT_TOKEN` | Telegram bot | Optional |
| `SLACK_BOT_TOKEN` | Slack bot | Optional |
| `SLACK_APP_TOKEN` | Slack socket mode | Optional |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | Git push/pull | Optional |
| `BRAVE_API_KEY` | Web search | Optional |
| `R2_ACCESS_KEY_ID` | R2 bucket access | Yes |
| `R2_SECRET_ACCESS_KEY` | R2 bucket access | Yes |
| `OPENCLAW_GATEWAY_TOKEN` | Gateway auth | Yes |

### 2. KV Namespace (Non-Sensitive Config)

**Location:** Account-level, accessed via Cloudflare API

**Purpose:** Channel configs, allowlists, preferences - things that change but aren't secret

**Namespace:** `OPENCLAW_CONFIG`
- **ID:** `177485fca6a54ac7bafe23498b2f6eba`
- **Account:** `6a93f4e0f785a77f95436f494bb13fa3`

**Current keys:**

| Key | Content |
|-----|---------|
| `channels/discord` | Guild allowlists, DM policy |
| `channels/telegram` | (future) Group allowlists |
| `channels/slack` | (future) Workspace config |
| `preferences/*` | (future) User preferences |

**How to read:**
```bash
curl -s "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/storage/kv/namespaces/${KV_NAMESPACE_ID}/values/channels%2Fdiscord" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
```

**How to write:**
```bash
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/storage/kv/namespaces/${KV_NAMESPACE_ID}/values/channels%2Fdiscord" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"guilds": {"SERVER_ID": {"channels": {"CHANNEL_ID": {}}}}, "groupPolicy": "allowlist"}'
```

### 3. R2 Bucket (Persistent Files)

**Location:** Account-level, mounted in container via s3fs

**Purpose:** Workspace files, conversation history, config backups

**Bucket:** `arsas-molt-fun` (or `moltbot-data` binding in wrangler)
**Mount point:** `/data/moltbot`

**Directory structure:**
```
/data/moltbot/
├── openclaw/
│   ├── openclaw.json      # Config backup
│   ├── workspace/         # MEMORY.md, skills/, etc.
│   └── scripts/           # Sync scripts backup
└── .last-sync             # Sync timestamp
```

## Container Startup Flow

`start-openclaw.sh` runs on every container start:

1. **Restore from R2** - Copy workspace and config from R2 if newer
2. **Run onboard** - Create base config if missing
3. **Fetch KV config** - GET `channels/discord` etc. from KV
4. **Merge with secrets** - Combine KV config with env var tokens
5. **Write final config** - Save to `/root/.openclaw/openclaw.json`
6. **Start gateway** - `openclaw gateway --bind lan`

## Replicating This Stack

To create a new worker with the same architecture:

### 1. Fork/Clone the repo

```bash
git clone https://github.com/beloyal-club/arsa-molt-fun.git my-openclaw
cd my-openclaw
```

### 2. Create KV namespace

```bash
wrangler kv namespace create OPENCLAW_CONFIG
# Note the namespace ID
```

### 3. Create R2 bucket

```bash
wrangler r2 bucket create my-openclaw-data
```

### 4. Update wrangler.jsonc

```jsonc
{
  "name": "my-openclaw",
  "r2_buckets": [
    {
      "binding": "MOLTBOT_BUCKET",
      "bucket_name": "my-openclaw-data"
    }
  ]
}
```

### 5. Create R2 API tokens

Dashboard → R2 → Manage R2 API Tokens → Create API Token
- Permission: Object Read & Write
- Bucket: my-openclaw-data

### 6. Set secrets

```bash
# Required
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put CLOUDFLARE_API_TOKEN
wrangler secret put CF_ACCOUNT_ID
wrangler secret put R2_ACCESS_KEY_ID
wrangler secret put R2_SECRET_ACCESS_KEY
wrangler secret put OPENCLAW_GATEWAY_TOKEN

# Optional channels
wrangler secret put DISCORD_BOT_TOKEN
wrangler secret put TELEGRAM_BOT_TOKEN
```

### 7. Initialize KV config

```bash
# Set Discord guild allowlist
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/YOUR_ACCOUNT_ID/storage/kv/namespaces/YOUR_KV_ID/values/channels%2Fdiscord" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"guilds": {"YOUR_SERVER_ID": {"channels": {"YOUR_CHANNEL_ID": {}}}}, "groupPolicy": "allowlist", "dm": {"policy": "pairing"}}'
```

### 8. Deploy

```bash
npm run deploy
```

## Updating Config

### To change Discord guilds:

```bash
# Update KV
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/storage/kv/namespaces/177485fca6a54ac7bafe23498b2f6eba/values/channels%2Fdiscord" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"guilds": {"NEW_SERVER": {"channels": {"NEW_CHANNEL": {}}}}, "groupPolicy": "allowlist"}'

# Then restart container (or wait for next deploy)
```

### To add a new secret:

1. Add to `src/types.ts` (MoltbotEnv interface)
2. Add to `src/gateway/env.ts` (buildEnvVars function)
3. Deploy the worker
4. Set the secret: `wrangler secret put NEW_SECRET`

## Troubleshooting

### Config keeps getting wiped
- Check that `start-openclaw.sh` has the KV fetch code
- Verify `CLOUDFLARE_API_TOKEN` and `CF_ACCOUNT_ID` are set as Worker secrets
- Check KV has the correct data

### Discord not responding
- Verify KV has `channels/discord` with your guild ID
- Check `groupPolicy` is set to `"allowlist"`
- Ensure guild ID and channel ID are correct

### Secrets not in container
- Secrets must be in `buildEnvVars()` in `src/gateway/env.ts`
- Secrets must be in `MoltbotEnv` interface in `src/types.ts`
- Worker must be redeployed after code changes
- Container must restart to pick up new secrets
