#!/bin/bash
# Sync 1Password vault secrets to Cloudflare Worker secrets
# Usage: ./sync-to-cloudflare.sh <vault> <worker-name> [SPECIFIC_KEYS]
#
# Maps 1Password items to env var names:
#   Item "Browserbase" + field "api-key" → BROWSERBASE_API_KEY
#   Item "OpenAI" + field "api-key" → OPENAI_API_KEY
#
# Requires: OP_SERVICE_ACCOUNT_TOKEN, CLOUDFLARE_API_TOKEN, CF_ACCOUNT_ID
set -euo pipefail

VAULT="${1:?Usage: $0 <vault> <worker-name> [KEY1,KEY2,...]}"
WORKER="${2:?Missing worker name}"
FILTER="${3:-}"

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "Error: OP_SERVICE_ACCOUNT_TOKEN not set" >&2
  exit 1
fi

if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
  echo "Error: CLOUDFLARE_API_TOKEN not set" >&2
  exit 1
fi

if [ -z "${CF_ACCOUNT_ID:-}" ]; then
  echo "Error: CF_ACCOUNT_ID not set" >&2
  exit 1
fi

# Get all items in vault
ITEMS=$(op item list --vault "$VAULT" --format=json)

echo "Syncing secrets from 1Password vault '$VAULT' to Cloudflare Worker '$WORKER'..."

# Process each item
echo "$ITEMS" | jq -r '.[].title' | while read -r ITEM; do
  # Get item details
  ITEM_JSON=$(op item get "$ITEM" --vault "$VAULT" --format=json)
  
  # Extract fields (skip built-in fields like username/password labels)
  echo "$ITEM_JSON" | jq -r '.fields[]? | select(.value != null and .value != "") | "\(.label)=\(.value)"' | while IFS='=' read -r FIELD VALUE; do
    # Convert to env var name: "api-key" → "API_KEY", prepend item name
    ITEM_UPPER=$(echo "$ITEM" | tr '[:lower:]-' '[:upper:]_')
    FIELD_UPPER=$(echo "$FIELD" | tr '[:lower:]-' '[:upper:]_')
    ENV_NAME="${ITEM_UPPER}_${FIELD_UPPER}"
    
    # Clean up common patterns
    ENV_NAME=$(echo "$ENV_NAME" | sed 's/_API_KEY$/_API_KEY/' | sed 's/__/_/g')
    
    # Filter if specified
    if [ -n "$FILTER" ]; then
      if ! echo ",$FILTER," | grep -q ",$ENV_NAME,"; then
        continue
      fi
    fi
    
    # Push to Cloudflare
    RESULT=$(curl -s -X PUT \
      "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/workers/scripts/${WORKER}/secrets" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"${ENV_NAME}\", \"text\": \"${VALUE}\", \"type\": \"secret_text\"}")
    
    if echo "$RESULT" | jq -e '.success' >/dev/null 2>&1; then
      echo "  ✓ $ENV_NAME"
    else
      echo "  ✗ $ENV_NAME: $(echo "$RESULT" | jq -r '.errors[0].message // "unknown error"')"
    fi
  done
done

echo "Done!"
