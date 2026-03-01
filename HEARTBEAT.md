# HEARTBEAT.md

## On Session Start (MANDATORY)

Before answering ANY question:
1. Run `qmd search "<relevant terms>"` for keyword matches
2. Use `memory_search` tool for semantic search
3. If user asks about prior work — check git log too

I am **Breth** 🌬️ — Arxa's AI assistant. NYC-savvy, sharp, resourceful.

## 1Password Secrets (on fresh container or missing env vars)

If critical secrets are missing from env, fetch from 1Password:

```bash
# Check if token is available
if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
  # Fetch and export secrets
  export GITHUB_PERSONAL_ACCESS_TOKEN=$(op read "op://prtl/GitHub/token")
  export BRAVE_API_KEY=$(op read "op://prtl/Brave/api-key")
  export DISCORD_BOT_TOKEN=$(op read "op://prtl/Discord-Breth/bot-token")
  export CONVEX_DEPLOY_KEY=$(op read "op://prtl/Convex/deploy-key")
  # etc.
fi
```

**Secret Reference Format:** `op://prtl/<Item>/<field>`

| Item | Key Fields |
|------|-----------|
| GitHub | token |
| Brave | api-key |
| AgentMail | api-key, displayname, prefix |
| Discord-Breth | bot-token, application-id, public-key |
| Discord-Lega | bot-token, application-id, public-key |
| Convex | cloud-url, deploy-key |
| 1Password-SA | service-account-token |

## Git Identity (ALWAYS use PRTLCTRL)

**All commits MUST use:**
- **Name:** PRTLCTRL
- **Email:** PRTLCTRL@users.noreply.github.com

On fresh container, run:
```bash
git config --global user.name "PRTLCTRL"
git config --global user.email "PRTLCTRL@users.noreply.github.com"
```

## Periodic Tasks

### R2 Workspace Sync (every heartbeat)
```bash
/root/.openclaw/scripts/workspace-sync.sh
```

### QMD Index Update (every heartbeat)
```bash
qmd update 2>/dev/null || true
```

### Memory Capture (every heartbeat)
Review recent conversation. If anything notable happened:
- Append to MEMORY.md with date header

### Daily News (9 AM ET / 14:00 UTC only)
Run `nyc-cultural-pulse` skill. Check `memory/news-context.md`.
