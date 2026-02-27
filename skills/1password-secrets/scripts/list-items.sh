#!/bin/bash
# List items in a 1Password vault
# Usage: ./list-items.sh <vault-name>
set -euo pipefail

VAULT="${1:?Usage: $0 <vault-name>}"

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "Error: OP_SERVICE_ACCOUNT_TOKEN not set" >&2
  exit 1
fi

op item list --vault "$VAULT" --format=json | jq -r '.[] | "\(.title) [\(.category)]"'
