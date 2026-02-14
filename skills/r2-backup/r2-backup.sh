#!/bin/bash
# R2 Workspace Backup Script
# Syncs ~/.openclaw/workspace to arsas-molt-fun bucket

set -e

BUCKET="r2:arsas-molt-fun/openclaw-workspace"
SOURCE="/root/.openclaw/workspace"
LOG_FILE="/root/.openclaw/workspace/memory/backup.log"

mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date -Iseconds)] Starting backup..." >> "$LOG_FILE"

# Sync workspace to R2 (excludes .git internals but keeps structure)
rclone sync "$SOURCE" "$BUCKET" \
  --exclude ".git/**" \
  --exclude "*.tmp" \
  --exclude "*.log" \
  --exclude "node_modules/**" \
  -v 2>&1 | tail -5 >> "$LOG_FILE"

echo "[$(date -Iseconds)] Backup complete" >> "$LOG_FILE"
echo "Backup complete: $SOURCE → $BUCKET"
