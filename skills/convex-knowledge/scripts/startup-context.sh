#!/bin/bash
# Load startup context from Convex knowledge base

CONVEX_URL="https://next-sardine-289.convex.site"

echo "=== Recent High-Importance Memories ==="
curl -s "$CONVEX_URL/memories/recent?limit=15" | jq -r '.memories[] | select(.importance >= 0.7) | "[\(.type | ascii_upcase)] \(.content[0:200])..."'

echo ""
echo "=== Active Todos & In-Progress ==="
curl -s -X POST "$CONVEX_URL/memories/search" \
  -H "Content-Type: application/json" \
  -d '{"query": "in-progress todo waiting blocked", "limit": 5, "type": "todo"}' | jq -r '.results[] | "- \(.content)"'

curl -s -X POST "$CONVEX_URL/memories/search" \
  -H "Content-Type: application/json" \
  -d '{"query": "in-progress waiting", "limit": 3, "type": "event"}' | jq -r '.results[] | select(.tags | contains(["in-progress"])) | "- \(.content)"'

echo ""
echo "=== Stats ==="
curl -s "$CONVEX_URL/memories/stats" | jq -c '.'
