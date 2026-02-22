#!/bin/bash
# Refresh YouTube OAuth access token
# Usage: youtube-auth.sh
# Returns: Access token (valid ~1 hour)

set -e

# Source creds file if env vars not set (workaround for mid-session secrets)
if [ -z "$YOUTUBE_CLIENT_ID" ] && [ -f /root/.youtube-creds ]; then
    source /root/.youtube-creds
fi

if [ -z "$YOUTUBE_CLIENT_ID" ] || [ -z "$YOUTUBE_CLIENT_SECRET" ] || [ -z "$YOUTUBE_REFRESH_TOKEN" ]; then
    echo "ERROR: Missing YouTube credentials" >&2
    echo "Required: YOUTUBE_CLIENT_ID, YOUTUBE_CLIENT_SECRET, YOUTUBE_REFRESH_TOKEN" >&2
    exit 1
fi

curl -s -X POST "https://oauth2.googleapis.com/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=${YOUTUBE_CLIENT_ID}" \
    -d "client_secret=${YOUTUBE_CLIENT_SECRET}" \
    -d "refresh_token=${YOUTUBE_REFRESH_TOKEN}" \
    -d "grant_type=refresh_token" | jq -r '.access_token'
