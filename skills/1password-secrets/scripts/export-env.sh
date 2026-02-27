#!/bin/bash
# Export 1Password vault as .env format (for local dev)
# Usage: ./export-env.sh <vault> > .env.local
set -euo pipefail

VAULT="${1:?Usage: $0 <vault>}"

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "Error: OP_SERVICE_ACCOUNT_TOKEN not set" >&2
  exit 1
fi

echo "# Generated from 1Password vault: $VAULT"
echo "# $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Get all items in vault
op item list --vault "$VAULT" --format=json | jq -r '.[].title' | while read -r ITEM; do
  ITEM_JSON=$(op item get "$ITEM" --vault "$VAULT" --format=json)
  
  echo "$ITEM_JSON" | jq -r '.fields[]? | select(.value != null and .value != "") | "\(.label)=\(.value)"' | while IFS='=' read -r FIELD VALUE; do
    ITEM_UPPER=$(echo "$ITEM" | tr '[:lower:]-' '[:upper:]_')
    FIELD_UPPER=$(echo "$FIELD" | tr '[:lower:]-' '[:upper:]_')
    ENV_NAME="${ITEM_UPPER}_${FIELD_UPPER}"
    ENV_NAME=$(echo "$ENV_NAME" | sed 's/__/_/g')
    
    # Escape special chars for .env
    VALUE_ESCAPED=$(echo "$VALUE" | sed 's/"/\\"/g')
    echo "${ENV_NAME}=\"${VALUE_ESCAPED}\""
  done
done
