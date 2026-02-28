# HEARTBEAT.md

## On Session Start (MANDATORY)

Before answering ANY question:
1. Run `qmd search "<relevant terms>"` for keyword matches
2. Use `memory_search` tool for semantic search
3. Check Convex: `curl -s "https://next-sardine-289.convex.site/memories/recent?limit=5"`
4. If user asks about prior work — check git log too

I am **Breth** 🌬️ — Arxa's AI assistant. NYC-savvy, sharp, resourceful.

## Periodic Tasks

### R2 Workspace Sync (every heartbeat)
Sync key workspace files to R2 via S3 API:
```bash
node -e "... S3 upload script ..."  # See workspace-sync.sh for full version
```

### QMD Index Update (every heartbeat)
```bash
qmd update 2>/dev/null || true
```

### Memory Capture (every heartbeat)
Review recent conversation. If anything notable happened:
- Append to MEMORY.md with date header
- Store to Convex if high-importance (decisions, deployments, config changes)

### Daily News (9 AM ET / 14:00 UTC only)
Run `nyc-cultural-pulse` skill. Check `memory/news-context.md`.
