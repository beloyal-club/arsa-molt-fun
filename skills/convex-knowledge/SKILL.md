# Convex Knowledge Base

Semantic memory and knowledge storage via Convex.

## Endpoints

**Base URL:** `https://next-sardine-289.convex.site`

### Store a Memory
```bash
curl -X POST https://next-sardine-289.convex.site/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "The actual memory text",
    "type": "fact|event|preference|decision|todo|conversation|note",
    "category": "optional category",
    "tags": ["tag1", "tag2"],
    "source": "chat|manual|scrape|api",
    "sessionKey": "optional session key",
    "entities": ["person", "place"],
    "importance": 0.5
  }'
```

### Search Memories (Text)
```bash
curl -X POST https://next-sardine-289.convex.site/memories/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "search text",
    "limit": 10,
    "type": "optional filter"
  }'
```

### Search Memories (Semantic)
```bash
curl -X POST https://next-sardine-289.convex.site/memories/search \
  -H "Content-Type: application/json" \
  -d '{
    "embedding": [0.1, 0.2, ...],
    "limit": 10
  }'
```

### Get Recent Memories
```bash
curl "https://next-sardine-289.convex.site/memories/recent?limit=20&type=fact"
```

### Get Stats
```bash
curl https://next-sardine-289.convex.site/memories/stats
```

### Store Conversation
```bash
curl -X POST https://next-sardine-289.convex.site/conversations \
  -H "Content-Type: application/json" \
  -d '{
    "sessionKey": "main",
    "role": "user|assistant",
    "content": "message content",
    "channel": "discord|telegram|webchat"
  }'
```

## Memory Types

| Type | Use For |
|------|---------|
| `fact` | Persistent knowledge (e.g., "User's timezone is ET") |
| `event` | Things that happened (e.g., "Deployed Lega bot on 2026-02-25") |
| `preference` | User preferences (e.g., "Prefers morning briefings at 9 AM") |
| `decision` | Decisions made (e.g., "Chose Convex over Supabase for storage") |
| `todo` | Tasks to do |
| `conversation` | Notable conversation snippets |
| `note` | General notes |

## Importance Scores

- `1.0` — Critical, always surface
- `0.7-0.9` — High importance
- `0.4-0.6` — Normal importance (default: 0.5)
- `0.1-0.3` — Low importance, background info

## Semantic Search

For semantic search, generate embeddings using OpenAI's `text-embedding-3-small` (1536 dimensions) and pass in the `embedding` field.

## Scripts

Use `scripts/query.sh` for quick queries:
```bash
./scripts/query.sh "search term"
./scripts/store.sh "memory content" "type" "category"
```

## Integration

The skill automatically stores important facts and decisions from conversations. Query before answering questions about past work, people, or preferences.
