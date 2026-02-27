#!/bin/bash
# Query Convex knowledge base

CONVEX_URL="https://next-sardine-289.convex.site"
QUERY="$1"
LIMIT="${2:-10}"

if [ -z "$QUERY" ]; then
  echo "Usage: $0 <search_query> [limit]"
  exit 1
fi

curl -s -X POST "$CONVEX_URL/memories/search" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$QUERY\", \"limit\": $LIMIT}" | jq .
