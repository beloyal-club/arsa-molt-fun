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
- Worker: `arsas-molt-fun` (note the 's')
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

#### How Secrets Work (IMPORTANT - Prevent Amnesia)

**The Problem:** Secrets are stored as Cloudflare Worker secrets, NOT in the container env by default. They need to be:
1. Added as Worker secrets (via /_admin/ or wrangler)
2. Listed in `buildEnvVars()` in `src/gateway/env.ts` to be passed to container
3. Listed in `MoltbotEnv` interface in `src/types.ts`

**Secrets That MUST Be Set as Worker Secrets:**

| Secret | Purpose | Status |
|--------|---------|--------|
| `BRAVE_API_KEY` | Web search via Brave API | ✅ Code ready, needs Worker secret |
| `CLOUDFLARE_API_TOKEN` | MCP HTTP calls | ✅ Code ready (commit b6c3d95), needs Worker secret |
| `CDP_SECRET` | Browser Rendering CDP | ✅ Code ready, needs Worker secret |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | Git push/pull | ✅ Working |
| `ANTHROPIC_API_KEY` | Claude API | ✅ Working |
| `OPENAI_API_KEY` | OpenAI API | ✅ Working |
| `GEMINI_API_KEY` | Gemini API | ✅ Working (passed as GEMINI_API_KEY) |

**To Add Missing Secrets:**
1. Go to `/_admin/` → Secrets panel
2. Add each secret by name and value
3. Restart gateway (secrets are injected on container start)

**NEVER store actual secret values in MEMORY.md** — this file syncs to R2 and git.

### Git Workspace Sync Setup

Workspace files now sync to both R2 AND GitHub (arsa-molt-fun repo).

**What happens on heartbeat:**
1. `workspace-sync.sh` runs
2. Syncs workspace → R2 at `/data/moltbot/openclaw/workspace/`
3. Commits and pushes changes to GitHub if any

**What happens on container startup:**
1. R2 mounted at `/data/moltbot`
2. `start-openclaw.sh` restores workspace from R2 (checks `openclaw/workspace/` first, then legacy `openclaw-workspace/`)
3. Restores scripts from R2 at `openclaw/scripts/`
4. Clones `arsa-molt-fun` repo if `GITHUB_PERSONAL_ACCESS_TOKEN` is set
5. Starts gateway

**Files synced:**
- IDENTITY.md, USER.md, SOUL.md, TOOLS.md, MEMORY.md, HEARTBEAT.md, AGENTS.md
- memory/ directory
- skills/ directory

**Scripts location:** `/root/.openclaw/scripts/` (backed up to R2 at `/data/moltbot/openclaw/scripts/`)

**Git repo:** `/root/arsa-molt-fun` (clone of beloyal-club/arsa-molt-fun)

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

## 2026-02-22

### Fixed the Secrets Passthrough (Finally!)

**Root cause discovered:** GitHub Actions deploys were failing because GitHub repo secrets weren't set.

The confusion:
- Arxa kept adding `CLOUDFLARE_API_TOKEN` as a **Worker secret** ✅
- But the Worker code to pass it to container (commit b6c3d95) never deployed ❌
- Because GitHub Actions needed `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` as **GitHub repo secrets** to deploy

**Two separate secret stores:**
1. **GitHub repo secrets** — used by GitHub Actions CI/CD to deploy
2. **Cloudflare Worker secrets** — used by the running Worker

**What we fixed:**
1. Added `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` as GitHub repo secrets (via GitHub API)
2. Pushed empty commit to trigger deploy
3. Deploy succeeded (commit 2e965e0)
4. Added `CLOUDFLARE_API_TOKEN` as Worker secret via Cloudflare API

**Now working:**
- ✅ GitHub Actions can deploy (has repo secrets)
- ✅ Worker passes `CLOUDFLARE_API_TOKEN` to container (code deployed)
- ✅ MCP skills will work after container restart

**Key lesson:** When adding new env vars to container:
1. Add to `src/types.ts` (MoltbotEnv interface)
2. Add to `src/gateway/env.ts` (buildEnvVars function)  
3. Deploy the Worker (GitHub Actions needs repo secrets!)
4. Add the actual value as a Worker secret

### YouTube Commenter Skill Setup

Added YouTube API credentials for the youtube-commenter skill.

**Worker code updated** (commit c3951c4):
- Added to `src/types.ts`: YOUTUBE_CLIENT_ID, YOUTUBE_CLIENT_SECRET, YOUTUBE_REDIRECT_URI, YOUTUBE_USER_ID, YOUTUBE_CHANNEL_ID, YOUTUBE_REFRESH_TOKEN
- Added to `src/gateway/env.ts`: passthrough for all 6 YouTube env vars

**Secrets to add as Worker secrets:**

| Secret | Purpose |
|--------|---------|
| `YOUTUBE_CLIENT_ID` | OAuth client ID |
| `YOUTUBE_CLIENT_SECRET` | OAuth client secret |
| `YOUTUBE_REDIRECT_URI` | OAuth redirect (http://localhost:3000/oauth2callback) |
| `YOUTUBE_USER_ID` | User ID for channel |
| `YOUTUBE_CHANNEL_ID` | Channel ID (UCZ3fFcppk_0dgQSdOgXZIbQ) |
| `YOUTUBE_REFRESH_TOKEN` | OAuth refresh token for API access |

**Status:** Code deployed via GitHub Actions. Secrets need to be added via `/_admin/` Secrets panel, then container restart.

### YouTube Secrets Added + Working

Added all 6 YouTube secrets via Cloudflare API (correct account: PRTL `6a93f4e0f785a77f95436f494bb13fa3`).

**Key learnings:**
- Secrets API needs `type: "secret_text"` field
- Secrets injected at container start, not gateway restart
- Workaround: Write to `/root/.youtube-creds` file, source before scripts
- Scripts updated to auto-source creds file if env vars missing

**Tested and working:** Posted 2 comments to YouTube successfully.

### BMAD Factory Reference (TODO: Separate Branch)

Reference: https://github.com/kellyclaudeai/bmad-factory

Production-grade BMAD implementation on OpenClaw with:
- **Orchestrator pattern**: Kelly Router → Project Lead → BMAD agents
- **State management**: `project-registry.json` single source of truth
- **Research pipeline**: Research Lead autonomously generates product ideas
- **Quality gates**: TEA (Test Architect) with 4-gate testing
- **Dependency-driven parallelism**: Stories spawn when deps resolve
- **Self-healing**: Heartbeat detects stuck agents, respawns

Key docs:
- `docs/core/project-lead-flow.md` — Full PL orchestration spec
- `docs/core/research-lead-flow.md` — Idea generation pipeline
- `AGENTS.md` — Execution routing, session naming conventions

**TODO:** Create separate branch to implement full factory pattern.
