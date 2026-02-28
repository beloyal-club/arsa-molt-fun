# HEARTBEAT.md

## Periodic Tasks

### R2 Workspace Sync (every heartbeat)
Run `/root/.openclaw/scripts/workspace-sync.sh` to backup workspace changes to R2.
Log results. If sync fails, note it but don't alarm.

### QMD Index Update (every heartbeat)
Update the qmd BM25 index after workspace changes:
```bash
qmd update 2>/dev/null || true
```
This keeps keyword search current. Semantic search uses OpenClaw's native memory_search (OpenAI embeddings).

### Daily News (9 AM ET only)
If it's around 9 AM ET (14:00 UTC), run the `nyc-cultural-pulse` skill.
Read `skills/nyc-cultural-pulse/SKILL.md` and follow the workflow.
Check `memory/news-context.md` for context and update it after briefing.
