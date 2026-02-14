# HEARTBEAT.md

## Periodic Tasks

### R2 Backup (every 4 heartbeats / ~2 hours)
Run workspace backup to R2 if it's been more than 2 hours since last backup:
```
/root/.openclaw/workspace/skills/r2-backup/r2-backup.sh
```
Check `memory/backup.log` for last backup time. Skip if <2h ago.
