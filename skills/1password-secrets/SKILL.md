# 1Password Secrets Skill

Manage secrets via 1Password Service Accounts. Integrates with OpenClaw's native SecretRef system for zero-plaintext credential storage.

## Prerequisites

- 1Password account with Service Account
- `OP_SERVICE_ACCOUNT_TOKEN` env var (stored as Cloudflare Worker secret)
- Vault(s) created with service account access

## Setup (One-time)

### 1. Create a Vault in 1Password

In 1Password web/app:
1. Create a vault (e.g., "BudAlert" or "OpenClaw")
2. Go to Developer → Service Accounts → Your Account → Vaults
3. Grant access to the vault

### 2. Add Secrets to the Vault

Create items with fields:
- Item title: `Browserbase` → Field: `api-key`
- Item title: `Convex` → Field: `deploy-key`
- Item title: `OpenAI` → Field: `api-key`

Secret references follow format: `op://VaultName/ItemName/FieldName`

## Usage

### Quick Commands

```bash
# List vaults (verify access)
./scripts/list-vaults.sh

# List items in a vault
./scripts/list-items.sh BudAlert

# Read a secret
./scripts/read-secret.sh "op://BudAlert/Browserbase/api-key"

# Store a new secret
./scripts/store-secret.sh BudAlert "Browserbase" "api-key" "bb_live_xxx"
```

### Sync to Cloudflare Worker Secrets

```bash
# Sync all secrets from a vault to a Cloudflare Worker
./scripts/sync-to-cloudflare.sh BudAlert arsas-molt-fun

# Sync specific secrets
./scripts/sync-to-cloudflare.sh BudAlert lega-bot DISCORD_BOT_TOKEN,ANTHROPIC_API_KEY
```

### OpenClaw SecretRef Integration

Configure OpenClaw to pull secrets from 1Password at activation:

```json
{
  "secrets": {
    "providers": {
      "1password": {
        "source": "exec",
        "command": "/usr/local/bin/op",
        "args": ["read"],
        "passEnv": ["OP_SERVICE_ACCOUNT_TOKEN"],
        "jsonOnly": false
      }
    }
  },
  "models": {
    "providers": {
      "openai": {
        "apiKey": { 
          "source": "exec", 
          "provider": "1password", 
          "id": "op://OpenClaw/OpenAI/api-key" 
        }
      }
    }
  }
}
```

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `list-vaults.sh` | List accessible vaults |
| `list-items.sh <vault>` | List items in a vault |
| `read-secret.sh <ref>` | Read a secret by reference |
| `store-secret.sh <vault> <item> <field> <value>` | Store/update a secret |
| `sync-to-cloudflare.sh <vault> <worker> [keys]` | Sync vault → Worker secrets |
| `export-env.sh <vault>` | Export vault as .env format |

## Vault Organization (Recommended)

```
OpenClaw/                    # Shared AI/infra secrets
├── Anthropic/api-key
├── OpenAI/api-key
├── Brave/api-key
└── Cloudflare/api-token

BudAlert/                    # Project-specific
├── Browserbase/api-key
├── Convex/deploy-key
├── Stripe/secret-key
└── Discord/webhook-url

Lega/                        # Another project
├── Discord/bot-token
└── Anthropic/api-key
```

## Troubleshooting

```bash
# Test service account access
op whoami

# Check vault access
op vault list

# Debug a read failure
op read "op://VaultName/ItemName/field" --force
```

## Security Notes

- Service account tokens are long-lived — protect them
- Vault access is explicit — service account only sees granted vaults
- Secrets are fetched at runtime, never stored in config files
- 1Password audit logs track all access
