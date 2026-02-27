# BOOTSTRAP.md - Startup Context Loader

Run this on session start to load relevant context from Convex.

## On Session Start

1. Query Convex for recent high-importance memories:
```bash
curl -s "https://next-sardine-289.convex.site/memories/recent?limit=10" | jq -r '.memories[] | select(.importance >= 0.7) | "[\(.type)] \(.content)"'
```

2. Query for any active todos or in-progress items:
```bash
curl -s -X POST "https://next-sardine-289.convex.site/memories/search" \
  -H "Content-Type: application/json" \
  -d '{"query": "in-progress todo waiting", "limit": 5}' | jq -r '.results[] | "- \(.content)"'
```

## Quick Context Injection

For semantic context on specific topics, use:
```bash
curl -s -X POST "https://next-sardine-289.convex.site/memories/semantic" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"<topic>\", \"openaiApiKey\": \"$OPENAI_API_KEY\", \"limit\": 5}"
```

## Memory Types Reference

| Type | Query For |
|------|-----------|
| `fact` | Persistent knowledge, config, preferences |
| `event` | Past happenings, deployments, decisions |
| `todo` | Active tasks |
| `preference` | User preferences |
| `decision` | Decisions made |

## Auto-Store Important Context

After significant conversations, store key facts:
```bash
curl -X POST "https://next-sardine-289.convex.site/memories/store" \
  -H "Content-Type: application/json" \
  -d "{
    \"content\": \"<fact>\",
    \"type\": \"fact|event|decision\",
    \"category\": \"<category>\",
    \"tags\": [\"tag1\", \"tag2\"],
    \"importance\": 0.7,
    \"openaiApiKey\": \"$OPENAI_API_KEY\"
  }"
```
