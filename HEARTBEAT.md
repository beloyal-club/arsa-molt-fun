# HEARTBEAT.md

## Periodic Tasks

### R2 Workspace Sync (every heartbeat)
Run `/root/.openclaw/scripts/workspace-sync.sh` to backup workspace changes to R2.
Log results. If sync fails, note it but don't alarm.

### Daily News (9 AM ET only)
If it's around 9 AM ET (14:00 UTC), run the `nyc-cultural-pulse` skill.
Read `skills/nyc-cultural-pulse/SKILL.md` and follow the workflow.
Check `memory/news-context.md` for context and update it after briefing.
