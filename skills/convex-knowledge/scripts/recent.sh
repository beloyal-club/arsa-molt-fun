#!/bin/bash
# Get recent memories from Convex

CONVEX_URL="https://next-sardine-289.convex.site"
LIMIT="${1:-20}"
TYPE="${2:-}"

if [ -n "$TYPE" ]; then
  curl -s "$CONVEX_URL/memories/recent?limit=$LIMIT&type=$TYPE" | jq .
else
  curl -s "$CONVEX_URL/memories/recent?limit=$LIMIT" | jq .
fi
