#!/bin/bash
# List accessible 1Password vaults
set -euo pipefail

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "Error: OP_SERVICE_ACCOUNT_TOKEN not set" >&2
  exit 1
fi

op vault list --format=json | jq -r '.[] | "\(.name) (\(.id))"'
