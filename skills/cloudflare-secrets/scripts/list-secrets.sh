#!/bin/bash
# List Cloudflare Worker secrets via API
# Usage: list-secrets.sh [WORKER_NAME]
#
# Requires: CLOUDFLARE_API_TOKEN and CF_ACCOUNT_ID environment variables

set -e

WORKER_NAME="${1:-arsa-molt-fun}"

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "ERROR: CLOUDFLARE_API_TOKEN not set"
    exit 1
fi

if [ -z "$CF_ACCOUNT_ID" ]; then
    echo "ERROR: CF_ACCOUNT_ID not set"
    exit 1
fi

# List secrets via Cloudflare API
curl -s -X GET \
    "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/workers/scripts/${WORKER_NAME}/secrets" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" | jq .
