---
name: cloudflare-secrets
description: Persist secrets safely as Cloudflare Worker secrets via API. Use when storing API keys, tokens, or credentials that need to survive container restarts. Requires CLOUDFLARE_API_TOKEN with Workers Scripts Edit permission.
---

# Cloudflare Worker Secrets

Store secrets as Cloudflare Worker environment variables that persist across deployments and container restarts.

## Prerequisites

A `CLOUDFLARE_API_TOKEN` with **Workers Scripts Edit** permission. Create one at:
https://dash.cloudflare.com/profile/api-tokens

The token needs:
- Account > Workers Scripts > Edit
- Zone > Workers Routes > Edit (optional)

## Setting Secrets

Use `scripts/set-secret.sh`:

```bash
CLOUDFLARE_API_TOKEN=<token> ./scripts/set-secret.sh <SECRET_NAME> <SECRET_VALUE> [WORKER_NAME]
```

Example:
```bash
CLOUDFLARE_API_TOKEN=xxx ./scripts/set-secret.sh GITHUB_PAT ghp_xxx arsa-molt-fun
```

After setting secrets, restart the gateway via `/_admin/` or the gateway tool for changes to take effect.

## Listing Secrets

Use `scripts/list-secrets.sh`:

```bash
CLOUDFLARE_API_TOKEN=<token> ./scripts/list-secrets.sh [WORKER_NAME]
```

Note: This only shows secret names, not values (Cloudflare doesn't return secret values).

## Bootstrap Problem

To set secrets via API, you need a CLOUDFLARE_API_TOKEN. But that token itself needs to be stored somewhere.

**Bootstrap options:**
1. User sets CLOUDFLARE_API_TOKEN manually via `/_admin/` UI (one-time)
2. User runs `wrangler secret put CLOUDFLARE_API_TOKEN` locally
3. Pass token directly in chat (stored in session, not persisted — use for initial setup only)

Once CLOUDFLARE_API_TOKEN is set as a Worker secret, subsequent secrets can be set programmatically.

## Security Notes

- Never write secret values to workspace files (they sync to R2)
- Secrets set via API are encrypted at rest by Cloudflare
- Use memory only for noting which secrets exist, not their values
