---
name: youtube-commenter
description: Post witty, empathetic comments on YouTube videos about NYC events, culture, Broadway, restaurants, and local happenings. Use when asked to comment on YouTube videos, engage with NYC content, or boost visibility through thoughtful commentary. Requires YOUTUBE_REFRESH_TOKEN.
---

# YouTube Commenter

Post engaging comments on NYC-related YouTube videos that earn upvotes through wit and genuine connection.

## Prerequisites

YouTube Data API v3 credentials:
- `YOUTUBE_CLIENT_ID` — OAuth client ID
- `YOUTUBE_CLIENT_SECRET` — OAuth client secret  
- `YOUTUBE_REFRESH_TOKEN` — Refresh token with `youtube.force-ssl` scope

## Workflow

### 1. Find Videos

Search for NYC event videos:
```bash
./scripts/youtube-search.sh "NYC Broadway opening night 2026"
./scripts/youtube-search.sh "new restaurant opening Manhattan"
./scripts/youtube-search.sh "NYC concert Central Park"
```

### 2. Analyze Before Commenting

Before commenting, gather context:
- Video title and description
- Channel name and vibe
- Top existing comments (understand the room)
- Video length and content type

### 3. Generate Comment

**Comment Formula:**
```
[Specific observation] + [Relatable feeling] + [Light wit OR genuine question]
```

**Good examples:**
- "The way the crowd erupted at 2:34 gave me actual chills. This is why NYC theater hits different 🎭"
- "As someone who waited 3 hours for that ramen, can confirm the hype is real. My wallet disagrees but my soul is at peace"
- "Not me planning my entire weekend around this video... again. The East Village just doesn't miss"

**Avoid:**
- Generic praise ("Great video!")
- Self-promotion
- Controversial takes
- Emojis spam
- "First!" energy

### 4. Post Comment

```bash
./scripts/youtube-comment.sh VIDEO_ID "Your comment here"
```

## Comment Style Guide

### Tone: NYC Insider
Write like a local who genuinely loves the city. Reference specific neighborhoods, venues, or experiences. Show you *get* it.

### Emotional Range
- **Excited**: Broadway openings, concert announcements, new spots
- **Nostalgic**: Closing venues, neighborhood changes  
- **Appreciative**: Hidden gems, underrated content creators
- **Playfully cynical**: Tourist traps, subway woes (relatable not bitter)

### Length
2-3 sentences max. Punchy > lengthy.

### Timing
Comment on videos less than 48 hours old for visibility.

## Rate Limits

- YouTube API: 10,000 units/day
- Comments: ~50/day to avoid spam flags
- Space comments: minimum 2 minutes apart

## Scripts

| Script | Purpose |
|--------|---------|
| `youtube-search.sh` | Search videos by query |
| `youtube-comment.sh` | Post a comment |
| `youtube-auth.sh` | Refresh OAuth token |
