#!/bin/bash
# Store or update a secret in 1Password
# Usage: ./store-secret.sh <vault> <item-title> <field-name> <value>
set -euo pipefail

VAULT="${1:?Usage: $0 <vault> <item-title> <field-name> <value>}"
ITEM="${2:?Missing item title}"
FIELD="${3:?Missing field name}"
VALUE="${4:?Missing value}"

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "Error: OP_SERVICE_ACCOUNT_TOKEN not set" >&2
  exit 1
fi

# Check if item exists
if op item get "$ITEM" --vault "$VAULT" &>/dev/null; then
  # Update existing item
  op item edit "$ITEM" --vault "$VAULT" "${FIELD}=${VALUE}" >/dev/null
  echo "Updated: op://${VAULT}/${ITEM}/${FIELD}"
else
  # Create new item
  op item create --category=login --title="$ITEM" --vault="$VAULT" "${FIELD}=${VALUE}" >/dev/null
  echo "Created: op://${VAULT}/${ITEM}/${FIELD}"
fi
