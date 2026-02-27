# QMD Search Skill

Local semantic search for workspace docs using [tobi/qmd](https://github.com/tobi/qmd). BM25 full-text search + vector semantic search with OpenAI embeddings.

**Reference:** [OpenClaw Memory Docs - QMD Backend](https://docs.openclaw.ai/concepts/memory#qmd-backend-experimental)

> Note: OpenClaw's native `memory.backend = "qmd"` uses local llama.cpp for embeddings.
> This setup uses **OpenAI embeddings** instead (works on memory-constrained containers).

## Quick Commands

```bash
# Fast keyword search (BM25)
qmd search "discord config" -n 10

# Semantic search (OpenAI embeddings)
cd /root/.openclaw/workspace/skills/qmd-search
node scripts/openai-vsearch.mjs "how to manage secrets" -n 5

# Search within a collection
qmd search "API key" -c skills

# Get a specific document
qmd get "workspace/MEMORY.md"

# List files in a collection
qmd ls workspace

# Update index after file changes
qmd update

# Re-generate OpenAI embeddings
node scripts/openai-embed.mjs
```

## Collections

| Collection | Path | Contents |
|------------|------|----------|
| `workspace` | `/root/.openclaw/workspace` | All workspace .md files |
| `memory` | `/root/.openclaw/workspace/memory` | Long-term memory notes |
| `skills` | `/root/.openclaw/workspace/skills` | Skill documentation |

## Search Modes

| Command | Speed | Quality | Use When |
|---------|-------|---------|----------|
| `qmd search` | Fast | Good | Keyword/exact match |
| `qmd vsearch` | Medium | Better | Semantic similarity (needs embeddings) |
| `qmd query` | Slow | Best | Hybrid + reranking (needs embeddings) |

## Output Formats

```bash
# JSON for programmatic use
qmd search "config" --json

# File list only
qmd search "config" --files

# Markdown output
qmd search "config" --md
```

## Integration with Memory

Use qmd to search before answering questions about past work:

```bash
# Find relevant memories
qmd search "cloudflare secrets" -c workspace -n 5

# Get full content of a result
qmd get "#abc123" --full
```

## Index Maintenance

```bash
# Show index status
qmd status

# Re-index all collections
qmd update

# Generate embeddings (requires llama.cpp)
qmd embed
```

## Data Location

- Index: `~/.cache/qmd/index.sqlite`
- Models: `~/.cache/qmd/models/` (GGUF files)

## Backup

The qmd index is backed up to R2 via workspace sync. On container restart, restore with:

```bash
# Index is in ~/.cache/qmd/
rsync -r --no-times /data/moltbot/openclaw/qmd-cache/ ~/.cache/qmd/
```

## Lifecycle

### On Startup (workspace-restore.sh)
- QMD cache restored from R2 (`/data/moltbot/openclaw/qmd-cache/`)
- Index ready for immediate search

### On Heartbeat (HEARTBEAT.md)
- `qmd update` refreshes BM25 index
- R2 sync backs up qmd cache

### Manual Embedding Refresh
After adding new docs, re-run OpenAI embeddings:
```bash
cd /root/.openclaw/workspace/skills/qmd-search
node scripts/openai-embed.mjs
```

## Limitations

- Vector search uses OpenAI API (not fully local)
- BM25 search works without embeddings/API
- Index needs `qmd update` after file changes

## Adding New Collections

```bash
# Add a new collection
qmd collection add /path/to/docs --name mydocs --mask "**/*.md"

# Add context for better search results
qmd context add qmd://mydocs "Description of these docs"
```
