# MEMORY.md - Long-Term Memory

*Curated memories, lessons learned, and persistent context.*

---

## 2026-02-15

### Fixed the Amnesia Problem
- **Root cause**: R2 bucket was mounted but workspace wasn't syncing properly
- **Issues found**:
  1. Full repo was in R2 (Dockerfile, src/, package.json, etc.) — should only have workspace files
  2. `start-openclaw.sh` looked for `.last-sync` in wrong path
  3. No automatic sync was set up
  
### What we fixed:
- Cleaned R2 — removed repo files, kept only: IDENTITY.md, USER.md, MEMORY.md, SOUL.md, TOOLS.md, HEARTBEAT.md, AGENTS.md, memory/, skills/
- Created sync scripts at `/root/.openclaw/scripts/`:
  - `workspace-sync.sh` — syncs workspace → R2
  - `workspace-restore.sh` — restores R2 → workspace on startup
- Set up OpenClaw cron job: workspace-sync every 15 min
- Backed up scripts to R2 at `/data/moltbot/openclaw/scripts/`

### Still needed:
- Container entrypoint needs to run `workspace-restore.sh` on startup
- Or modify `start-openclaw.sh` in the worker repo to call restore script

### Infrastructure
- R2 bucket: `arsas-molt-fun` (mounted at `/data/moltbot`)
- Worker: `arsa-molt-fun`
- GitHub: `beloyal-club/arsa-molt-fun`
- GitHub user: PRTLCTRL

## 2026-02-16

### Secrets Configured
- **GITHUB_PERSONAL_ACCESS_TOKEN** — Full access to beloyal-club/arsa-molt-fun repo (push/pull/commit)
- **BRAVE_API_KEY** — For web search API
- **ANTHROPIC_API_KEY** — Claude OAuth key (updated to OAuth)
- **GOOGLE_API_KEY** — Gemini API key
- **AGENTMAIL_API_KEY** — Agent Mail API key
- **AGENTMAIL_ID** — arxa-claw

**Note:** These are stored as Worker secrets for persistence. If git stops working after restart, secrets may need to be re-added via `/_admin/` Secrets panel.

## 2026-02-21

### Cloudflare MCP + Code Mode Setup

After restart, rediscovered and properly documented the Cloudflare integrations.

#### Skills Created

1. **cloudflare-mcp** (`/root/.openclaw/workspace/skills/cloudflare-mcp/`)
   - Access Cloudflare services via MCP HTTP endpoints
   - Includes: Workers Bindings (KV, R2, D1), Observability, Browser Rendering, Radar, AI Gateway
   - Script: `scripts/mcp-call.sh` for making MCP HTTP calls
   - Requires: `CLOUDFLARE_API_TOKEN` with appropriate permissions

2. **cloudflare-codemode** (`/root/.openclaw/workspace/skills/cloudflare-codemode/`)
   - Reference for @cloudflare/codemode package
   - Lets LLMs write code instead of tool calls
   - Runs in isolated Cloudflare Workers sandboxes
   - Integration guide for arsa-molt-fun Worker

3. **cloudflare-browser** (`/root/.openclaw/workspace/skills/cloudflare-browser/`)
   - CDP WebSocket control of headless Chrome via Cloudflare Browser Rendering
   - Scripts: cdp-client.js, screenshot.js, video.js
   - Requires: `CDP_SECRET` env var (NOT currently set)

4. **cloudflare-secrets** (`/root/.openclaw/workspace/skills/cloudflare-secrets/`)
   - Manage Worker secrets via Cloudflare API
   - Scripts: set-secret.sh, list-secrets.sh
   - Requires: `CLOUDFLARE_API_TOKEN` with Workers Scripts Edit permission

#### MCP Server URLs (for reference)

| Service | URL |
|---------|-----|
| Workers Bindings | https://bindings.mcp.cloudflare.com/mcp |
| Observability | https://observability.mcp.cloudflare.com/mcp |
| Browser Rendering | https://browser.mcp.cloudflare.com/mcp |
| Radar | https://radar.mcp.cloudflare.com/mcp |
| AI Gateway | https://ai-gateway.mcp.cloudflare.com/mcp |
| Documentation | https://docs.mcp.cloudflare.com/mcp |

#### What Works vs What's Missing

**Working:**
- ✅ GitHub push/pull (GITHUB_PERSONAL_ACCESS_TOKEN works)
- ✅ ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY in container
- ✅ All skills + scripts preserved in workspace
- ✅ R2 sync running on heartbeat

**Missing (need to add as Worker secrets):**
- ❌ BRAVE_API_KEY — noted as configured but not in container env
- ❌ CDP_SECRET — needed for cloudflare-browser skill
- ❌ CLOUDFLARE_API_TOKEN — needed for MCP HTTP calls and secrets management
- ❌ AGENTMAIL_API_KEY — noted but not in container

#### How to Fix Missing Secrets

Option 1: Via /_admin/ Secrets panel in browser
Option 2: Via wrangler CLI:
```bash
npx wrangler secret put BRAVE_API_KEY --name arsa-molt-fun
npx wrangler secret put CLOUDFLARE_API_TOKEN --name arsa-molt-fun
```

After adding secrets, restart the gateway for changes to take effect.

#### R2 Sync Architecture

- Workspace syncs to R2 at `/data/moltbot/openclaw/workspace/`
- Scripts backed up to `/data/moltbot/openclaw/scripts/`
- Sync runs on every heartbeat via `/root/.openclaw/scripts/workspace-sync.sh`
- Uses rsync with `--no-times` for s3fs compatibility

#### Container Startup Flow

1. R2 mounted at `/data/moltbot` via s3fs
2. Should run `/root/.openclaw/scripts/workspace-restore.sh` (TODO: not in entrypoint yet)
3. Gateway starts with `openclaw gateway --allow-unconfigured --bind lan`
4. Heartbeat triggers workspace-sync.sh periodically

#### To-Do: Permanent Fix for R2 Restore

Modify `start-openclaw.sh` in the Worker repo to:
1. Check if restore script exists in R2
2. Copy and run it before starting gateway

This ensures workspace is restored even after container restart.
