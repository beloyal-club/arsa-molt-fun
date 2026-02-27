#!/bin/bash
# Read a secret from 1Password
# Usage: ./read-secret.sh "op://Vault/Item/field"
set -euo pipefail

REF="${1:?Usage: $0 <op://Vault/Item/field>}"

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "Error: OP_SERVICE_ACCOUNT_TOKEN not set" >&2
  exit 1
fi

op read "$REF"
