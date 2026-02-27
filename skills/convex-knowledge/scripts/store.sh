#!/bin/bash
# Store a memory in Convex

CONVEX_URL="https://next-sardine-289.convex.site"
CONTENT="$1"
TYPE="${2:-note}"
CATEGORY="${3:-}"
TAGS="${4:-[]}"
IMPORTANCE="${5:-0.5}"

if [ -z "$CONTENT" ]; then
  echo "Usage: $0 <content> [type] [category] [tags_json] [importance]"
  echo "Types: fact, event, preference, decision, todo, conversation, note"
  exit 1
fi

# Build JSON payload
PAYLOAD=$(jq -n \
  --arg content "$CONTENT" \
  --arg type "$TYPE" \
  --arg category "$CATEGORY" \
  --argjson tags "$TAGS" \
  --argjson importance "$IMPORTANCE" \
  '{
    content: $content,
    type: $type,
    category: (if $category == "" then null else $category end),
    tags: $tags,
    importance: $importance,
    source: "manual"
  }')

curl -s -X POST "$CONVEX_URL/memories" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" | jq .
