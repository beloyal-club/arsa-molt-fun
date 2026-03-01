# MEMORY.md - Long-Term Memory

*Curated memories, lessons learned, and persistent context.*

---

## Critical Rules (Always Follow)

### Git Identity
**All commits MUST use PRTLCTRL:**
```bash
git config --global user.name "PRTLCTRL"
git config --global user.email "PRTLCTRL@users.noreply.github.com"
```
Never commit as any other identity.

---

## 2026-02-15

### Fixed the Amnesia Problem
- **Root cause**: R2 bucket was mounted but workspace wasn't syncing properly
- **Issues found**:
  1. Full repo was in R2 (Dockerfile, src/, package.json, etc.) — should only have workspace files
  2. `start-openclaw.sh` looked for `.last-sync` in wrong path
  3. No automatic sync was set up
  
### What we fixed:
- Cleaned R2 — removed repo files, kept only workspace files (see list below)
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

## 2026-02-23

### Container Restart Ability
I can restart my own container using GitHub Actions on the arsa-molt-fun repo. This is useful when secrets are updated or code is deployed.

---

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

### Discord Channel Connected

Finally got Discord working!

**Config:**
- Server ID: `1064272702254354434` (PRTL)
- Channel ID: `1475231662332969192`
- `requireMention: true` — won't spam, responds when @mentioned
- DMs: pairing mode (approve via code)

**Worker secrets set:**
- `DISCORD_APPLICATION_ID`
- `DISCORD_BOT_TOKEN`
- `DISCORD_PUBLIC_KEY`

**Key:** The config key is `guilds` not `groups` — and channel allowlists go under `guilds.<id>.channels.<id>`.

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

## 2026-02-25

### Lega Bot Project (IN PROGRESS)

Building **Lega** — a Discord AI bot for **mylegacyinc** community (Mississauga non-profit for Muslim youth, sports, gaming).

**Architecture:** Same as Breth (OpenClaw on Cloudflare Container)

**Resources Created:**
| Resource | Value |
|----------|-------|
| GitHub Repo | `beloyal-club/lega-bot` |
| R2 Bucket | `lega-bot` |
| KV Namespace | `LEGA_CONFIG` — `b7d0613e07ac4c99b06e84bc9163b7b5` |
| Discord Server ID | `1462305906980290661` |
| Discord Channel ID | `1462309122837053688` |
| Discord App ID | `1476042068424917140` |
| Discord Public Key | `e514b53236a1a9b549765a9ea47361d9ee2c891d86c2ab17a3e11232423738c6` |

**Personality:** GTA mandem from Sauga — gaming, sports, halal vibes. See `lega-bot/SOUL.md`.

**Status:**
- [x] Repo created and pushed
- [x] R2 bucket created
- [x] KV namespace + Discord config set
- [x] Workspace files customized (SOUL.md, IDENTITY.md, etc.)
- [ ] Worker deployed
- [ ] Discord bot token added
- [ ] GitHub Actions secrets set up
- [ ] Bot online and tested

**Waiting on:** `LEGA_DISCORD_BOT_TOKEN` from user

---

## 2026-02-24

### Config + Secrets Architecture (KV Store)

**Problem:** Discord guilds config kept getting wiped on container restart because `start-openclaw.sh` was overwriting the entire discord config object.

**Solution:** Use dedicated Cloudflare KV for config, Secrets for tokens.

#### Two Storage Layers

| Store | Purpose | Examples |
|-------|---------|----------|
| **Cloudflare KV** | Non-sensitive config | Discord guilds, channel allowlists, preferences |
| **Cloudflare Secrets** | Sensitive tokens | DISCORD_BOT_TOKEN, API keys |

#### KV Namespace: OPENCLAW_CONFIG

- **Namespace ID:** `177485fca6a54ac7bafe23498b2f6eba`
- **Account ID:** `6a93f4e0f785a77f95436f494bb13fa3`

**Keys stored:**
| Key | Content |
|-----|---------|
| `channels/discord` | `{"guilds": {...}, "groupPolicy": "allowlist", "dm": {...}}` |

#### How It Works

1. **On container startup** (`start-openclaw.sh`):
   - Fetches config from KV via Cloudflare API
   - Merges with secrets (tokens from env vars)
   - Writes final config to `/root/.openclaw/openclaw.json`

2. **To update config:**
   - Update KV via API (not local file)
   - Container restart picks up changes
   - Or manually apply + reload

#### API Examples

**Read from KV:**
```bash
curl -s "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/storage/kv/namespaces/177485fca6a54ac7bafe23498b2f6eba/values/channels%2Fdiscord" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
```

**Write to KV:**
```bash
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/storage/kv/namespaces/177485fca6a54ac7bafe23498b2f6eba/values/channels%2Fdiscord" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"guilds": {...}, "groupPolicy": "allowlist"}'
```

#### Commits

- `a793f2b` — Initial fix to preserve existing discord config (spread operator)
- `76b44df` — Fetch Discord config from KV on startup

#### Required Env Vars in Container

| Var | Purpose |
|-----|---------|
| `CF_ACCOUNT_ID` | Cloudflare account for API calls |
| `CLOUDFLARE_API_TOKEN` | API token with KV read access |
| `OPENCLAW_KV_NAMESPACE_ID` | Optional override (defaults to hardcoded ID) |

#### Current Discord Config in KV

```json
{
  "guilds": {
    "1064272702254354434": {
      "channels": {
        "1475231662332969192": {}
      }
    }
  },
  "groupPolicy": "allowlist",
  "dm": {
    "policy": "pairing"
  }
}
```

#### Future Expansion

Can add more keys to KV for other channel configs:
- `channels/telegram`
- `channels/slack`
- `agents/defaults`
- `preferences/*`

---

## 2026-02-27

### Convex Knowledge Base Setup

Set up **Convex** as a semantic memory and knowledge store for persistent data and reasoning.

**Project:** `next-sardine-289`
**Cloud URL:** `https://next-sardine-289.convex.cloud`
**HTTP Actions:** `https://next-sardine-289.convex.site`

#### Schema (Tables)

| Table | Purpose |
|-------|---------|
| `memories` | Core semantic memory (facts, events, decisions, todos) with vector search |
| `conversations` | Conversation history with embeddings |
| `documents` | Longer-form content (files, scraped pages) |
| `scrapedData` | Raw scraped data for processing |
| `entities` | People, places, things extracted from memories |

#### Memory Types

| Type | Use For |
|------|---------|
| `fact` | Persistent knowledge (user prefs, config) |
| `event` | Things that happened (deploys, decisions) |
| `preference` | User preferences |
| `decision` | Decisions made |
| `todo` | Tasks |
| `conversation` | Notable conversation snippets |
| `note` | General notes |

#### HTTP Endpoints

```bash
# Store memory
POST https://next-sardine-289.convex.site/memories

# Search (text or semantic with embedding)
POST https://next-sardine-289.convex.site/memories/search

# Get recent
GET https://next-sardine-289.convex.site/memories/recent

# Stats
GET https://next-sardine-289.convex.site/memories/stats

# Health check
GET https://next-sardine-289.convex.site/health
```

#### Local Skill

Created `skills/convex-knowledge/` with:
- `SKILL.md` — Usage documentation
- `scripts/query.sh` — Search memories
- `scripts/store.sh` — Store new memory
- `scripts/recent.sh` — Get recent memories

#### Convex Project Files

Located at `/root/.openclaw/workspace/convex-knowledge/`:
- `convex/schema.ts` — Database schema with vector indexes
- `convex/memories.ts` — Memory CRUD + semantic search
- `convex/conversations.ts` — Conversation storage
- `convex/http.ts` — HTTP action endpoints

#### Secrets

```
CONVEX_DEPLOY_KEY=dev:next-sardine-289|...
```

Stored in `.env.local` in convex-knowledge directory. For Worker persistence, add as Cloudflare secret.

#### Semantic Search

Uses 1536-dimension embeddings (OpenAI text-embedding-3-small compatible). Pass `embedding` array to search endpoint for semantic retrieval.

#### Initial Data Loaded

- User profile (Arxa, NYC, sports, preferences)
- Infrastructure facts (Breth identity, Discord config)
- Lega Bot project status

### Convex Knowledge Base Improvements

Updated the Convex integration for better persistence and session context:

#### Worker Secrets Added
- `CONVEX_DEPLOY_KEY` — Now stored as Cloudflare Worker secret for persistence across restarts

#### Worker Code Updated
- Added `CONVEX_DEPLOY_KEY` to `src/types.ts` (MoltbotEnv interface)
- Added passthrough in `src/gateway/env.ts` (buildEnvVars function)
- Changes require deploy via GitHub Actions

#### Workspace Context Files

These files are loaded on session start and synced to R2:

| File | Purpose |
|------|---------|
| `IDENTITY.md` | Who Breth is |
| `USER.md` | About Arxa |
| `SOUL.md` | Personality and values |
| `MEMORY.md` | This file - curated long-term memory |
| `TOOLS.md` | Tool-specific notes and preferences |
| `HEARTBEAT.md` | Periodic tasks and cron jobs |
| `AGENTS.md` | Agent instructions (from worker repo) |
| `BOOTSTRAP.md` | Convex context loader - runs on session start |

#### HEARTBEAT.md Updates

Added periodic task to store important context to Convex:
- Identifies high-importance context from conversations
- Stores decisions, facts, tasks to Convex
- Uses importance scoring (0.7+ gets stored)

---

## 2026-02-27 (Recovered from Git)

### 1Password Secrets Integration
- Added `OP_SERVICE_ACCOUNT_TOKEN` for 1Password secrets management
- Skill: `skills/1password-secrets/` with scripts for vault access
- Commit: `70ded29`

### Voice-to-Voice Feature
- Added Whisper transcription + mic button injection
- Enables voice input in the web UI
- Commit: `74670df`

### Container Upgrade
- Upgraded to `standard-3` tier (2 vCPU, 8 GiB RAM)
- Better performance for agent workloads
- Commit: `0b3d63a`

### Lega Bot Deployed
- Worker deployed successfully
- Discord token added, all secrets configured
- GitHub Actions CI/CD working

---

## 2026-02-28

### Amnesia Recovery (Evening Session)

Container was redeployed, workspace restore didn't run. Had to manually recover:

1. **R2 backup existed** — 74 files at `openclaw/workspace/`
2. **GitHub repo current** — Full workspace with 19KB MEMORY.md
3. **Convex alive** — 7 memories with embeddings at `next-sardine-289`
4. **qmd not installed** — Reinstalled, indexed 28 files

**Recovery steps taken:**
- Restored workspace from R2 via S3 API
- Copied latest from GitHub repo
- Restored sync scripts from R2
- Installed qmd, created workspace collection
- Updated HEARTBEAT.md with proper memory capture

**Missing secrets identified:**
- BRAVE_API_KEY, CDP_SECRET, YOUTUBE_* (6), OP_SERVICE_ACCOUNT_TOKEN, CONVEX_DEPLOY_KEY

**Root cause:** `start-openclaw.sh` still not calling workspace-restore.sh on startup.

### Simplified Memory Architecture

**Decision:** Dropped Convex in favor of OpenClaw's native memory search.

**Why:**
- OpenClaw already has built-in OpenAI embeddings support (`text-embedding-3-small`)
- qmd's local models don't work in CF container (no cmake, CPU-only)
- Convex was overkill — extra service, extra complexity, same OpenAI embeddings

**New setup:**
- **Semantic search**: `memory_search` tool → OpenAI embeddings (native)
- **Keyword search**: `qmd search` → BM25 (fast, no models)
- **Storage**: MEMORY.md + memory/*.md (unchanged)

**Config added:**
```json5
agents.defaults.workspace = "/root/.openclaw/workspace"
agents.defaults.memorySearch.provider = "openai"
agents.defaults.memorySearch.model = "text-embedding-3-small"
```

**Removed from HEARTBEAT.md:**
- Convex memory maintenance task
- All Convex HTTP API calls

**BOOTSTRAP.md simplified** to just reference native memory_search.

## 2026-02-28 (Evening)

### 1Password Integration Complete! 🎉

**Finally solved the secrets amnesia problem** by storing all critical secrets in 1Password.

#### Setup
- **Vault:** `prtl` (id: `5wnmvuerwnz5tl6doa7tdw6hwy`)
- **Service Account:** `prtl-workers`
- **1Password CLI:** v2.30.0 (pre-installed in container)

#### Secrets Stored in 1Password (`prtl` vault)

| Item | Fields | Secret Ref Pattern |
|------|--------|-------------------|
| GitHub | token, username | `op://prtl/GitHub/token` |
| Brave | api-key | `op://prtl/Brave/api-key` |
| AgentMail | api-key, displayname, prefix | `op://prtl/AgentMail/api-key` |
| Discord-Breth | bot-token, application-id, public-key, server-id, channel-id | `op://prtl/Discord-Breth/bot-token` |
| Discord-Lega | bot-token, application-id, public-key, oauth-url, server-id, channel-id | `op://prtl/Discord-Lega/bot-token` |
| Convex | cloud-url, http-actions-url, deploy-key | `op://prtl/Convex/deploy-key` |
| 1Password-SA | secret-key, service-account-token | `op://prtl/1Password-SA/service-account-token` |

#### How to Fetch Secrets

```bash
# Set the token (bootstrap from 1Password-SA item or Cloudflare Worker secret)
export OP_SERVICE_ACCOUNT_TOKEN="ops_eyJ..."

# Read a secret
op read "op://prtl/GitHub/token"
op read "op://prtl/Brave/api-key"
op read "op://prtl/Discord-Breth/bot-token"

# List all items
op item list --vault prtl
```

#### Bootstrap Flow (on fresh container)

1. **OP_SERVICE_ACCOUNT_TOKEN** must be set as Cloudflare Worker secret (injected at container start)
2. On startup, fetch all other secrets from 1Password
3. Export to environment or write to temp files as needed

#### Worker Secret Required

Only **ONE** secret needs to be in Cloudflare Worker secrets now:
- `OP_SERVICE_ACCOUNT_TOKEN` — the 1Password service account token

All other secrets live in 1Password and can be fetched at runtime.

#### Changed Display Name

Also set `ui.assistant.name` to "Breth" in OpenClaw config so the webchat shows my name properly.

---

## 2026-03-01

### Parallel Workers Deployed (arxa-2, arxa-3)

Created 2 additional workers for parallelization/redundancy.

#### Architecture

| Worker | R2 Bucket | URL |
|--------|-----------|-----|
| `arsas-molt-fun` (primary) | `arsas-molt-fun` | https://arsas-molt-fun.prtl.workers.dev |
| `arxa-2` | `arxa-2` | https://arxa-2.prtl.workers.dev |
| `arxa-3` | `arxa-3` | https://arxa-3.prtl.workers.dev |

**All 3 workers:**
- Share same GitHub repo (`beloyal-club/arsa-molt-fun`)
- Have their own R2 bucket for local state
- Share the same API keys (Anthropic, OpenAI, Gemini)
- No Discord (only primary has Discord)

#### Wrangler Environments

Updated `wrangler.jsonc` to use environments:
- Default: deploys to `arsas-molt-fun` with `arsas-molt-fun` bucket
- `--env arxa2`: deploys to `arxa-2` with `arxa-2` bucket
- `--env arxa3`: deploys to `arxa-3` with `arxa-3` bucket

#### GitHub Actions Deploy

Updated `.github/workflows/deploy.yml`:
- Deploys all 3 workers on push to main
- Manual dispatch can target specific environment (all/primary/arxa2/arxa3)

#### Secrets Set on Each Worker

| Secret | Primary | arxa-2 | arxa-3 |
|--------|---------|--------|--------|
| ANTHROPIC_API_KEY | ✓ | ✓ | ✓ |
| OPENAI_API_KEY | ✓ | ✓ | ✓ |
| GEMINI_API_KEY | ✓ | ✓ | ✓ |
| CLOUDFLARE_API_TOKEN | ✓ | ✓ | ✓ |
| CF_ACCOUNT_ID | ✓ | ✓ | ✓ |
| CF_ACCESS_AUD | ✓ | ✓ | ✓ |
| CF_ACCESS_TEAM_DOMAIN | ✓ | ✓ | ✓ |
| R2_ACCESS_KEY_ID | ✓ | ✓ | ✓ |
| R2_SECRET_ACCESS_KEY | ✓ | ✓ | ✓ |
| GITHUB_PERSONAL_ACCESS_TOKEN | ✓ | ✓ | ✓ |
| MOLTBOT_GATEWAY_TOKEN | ✓ | ✓ | ✓ |
| DISCORD_BOT_TOKEN | ✓ | - | - |

#### Cloudflare Secrets Added to 1Password

Item: `Cloudflare-Workers` in `prtl` vault:
- `account-api-token` (CF_ACCOUNT_API_TOKEN)
- `aud-token` (CF_ACCESS_AUD)
- `jwk-url` (CF_JWK_URL)
- `access-team-domain` (CF_ACCESS_TEAM_DOMAIN)
- `account-id` (CF_ACCOUNT_ID)
