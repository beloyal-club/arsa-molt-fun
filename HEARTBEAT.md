# HEARTBEAT.md

## Periodic Tasks

### R2 Workspace Sync (every heartbeat)
Run `/root/.openclaw/scripts/workspace-sync.sh` to backup workspace changes to R2.
Log results. If sync fails, note it but don't alarm.

### Daily News (9 AM ET only)
If it's around 9 AM ET (14:00 UTC), run the `nyc-cultural-pulse` skill.
Read `skills/nyc-cultural-pulse/SKILL.md` and follow the workflow.
Check `memory/news-context.md` for context and update it after briefing.

### Convex Memory Maintenance (every heartbeat)

After significant conversations or decisions, store key context to Convex for long-term recall:

1. **Identify high-importance context** from recent interactions:
   - Decisions made (technical choices, preferences)
   - New facts learned (about user, projects, infrastructure)
   - Tasks created or completed
   - Configuration changes

2. **Store to Convex** using the skill:
```bash
curl -X POST "https://next-sardine-289.convex.site/memories" \
  -H "Content-Type: application/json" \
  -d "{
    \"content\": \"<context>\",
    \"type\": \"fact|event|decision|todo\",
    \"category\": \"<category>\",
    \"tags\": [\"tag1\"],
    \"importance\": 0.7,
    \"openaiApiKey\": \"$OPENAI_API_KEY\"
  }"
```

3. **Skip if**:
   - No significant new information
   - Context already stored (check deduplication)
   - Trivial or routine interactions

**Importance Guidelines:**
- 0.9+ : Critical decisions, major changes
- 0.7-0.8 : Notable facts, completed tasks
- 0.5-0.6 : Useful context, preferences
- < 0.5 : Routine, low-value info (don't store)
