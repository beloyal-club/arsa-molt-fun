#!/bin/bash
# Set a Cloudflare Worker secret via API
# Usage: set-secret.sh <SECRET_NAME> <SECRET_VALUE> [WORKER_NAME]
#
# Requires: CLOUDFLARE_API_TOKEN and CF_ACCOUNT_ID environment variables

set -e

SECRET_NAME="$1"
SECRET_VALUE="$2"
WORKER_NAME="${3:-arsa-molt-fun}"

if [ -z "$SECRET_NAME" ] || [ -z "$SECRET_VALUE" ]; then
    echo "Usage: set-secret.sh <SECRET_NAME> <SECRET_VALUE> [WORKER_NAME]"
    exit 1
fi

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "ERROR: CLOUDFLARE_API_TOKEN not set"
    echo "You need a Cloudflare API token with Workers Scripts Edit permission."
    echo "Create one at: https://dash.cloudflare.com/profile/api-tokens"
    exit 1
fi

if [ -z "$CF_ACCOUNT_ID" ]; then
    echo "ERROR: CF_ACCOUNT_ID not set"
    exit 1
fi

# Set the secret via Cloudflare API
RESPONSE=$(curl -s -X PUT \
    "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/workers/scripts/${WORKER_NAME}/secrets" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"${SECRET_NAME}\", \"text\": \"${SECRET_VALUE}\", \"type\": \"secret_text\"}")

# Check for success
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "SUCCESS: Secret '${SECRET_NAME}' set for worker '${WORKER_NAME}'"
else
    echo "ERROR: Failed to set secret"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    exit 1
fi
