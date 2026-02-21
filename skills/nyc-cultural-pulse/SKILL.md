---
name: nyc-cultural-pulse
description: Daily cultural news briefing for NYC and Jersey City. Aggregates local news, cultural events, social trends, and global stories with local relevance. Use for morning briefings, trend tracking, or when asked about NYC/JC news and culture. Learns and improves over time by tracking emerging patterns.
---

# NYC Cultural Pulse

Daily cultural intelligence for NYC and Jersey City — local news, events, social trends, and global stories that matter locally.

## Workflow

### 1. Load Context

Read `memory/news-context.md` to understand:
- Currently tracked trends and topics
- Recent stories (avoid repeating)
- User engagement patterns (what resonated)

### 2. Search News Categories

Use `web_search` with `freshness: "pd"` (past 24h) for each category:

```
Categories:
1. "NYC news today" + "New York City local news"
2. "Jersey City news today" + "Jersey City NJ news"  
3. "Broadway theater news" + "NYC concerts shows"
4. "NYC restaurants openings" + "NYC food news"
5. "NYC art exhibitions museums" + "NYC gallery openings"
6. "NYC events this week"
```

### 3. Check Global Trends

Search for major global events and filter for local relevance:
- Major sporting events (Olympics, World Cup, etc.)
- Market/economic news affecting NYC sectors
- Cultural moments trending nationally
- Weather events affecting the region

Query: `"[trending topic] New York"` or `"[trending topic] impact NYC"`

### 4. Synthesize & Prioritize

Rank stories by:
1. **Local impact** — directly affects NYC/JC residents
2. **Timeliness** — happening today/this week
3. **Cultural significance** — arts, food, social trends
4. **User interests** — check context for past engagement

### 5. Deliver Briefing

Format as concise briefing:
```
🌆 NYC/JC Cultural Pulse — [Date]

📰 TOP STORIES
• [Headline] — [1-2 sentence summary]

🎭 CULTURE & EVENTS  
• [What's happening in arts/entertainment]

🍽️ FOOD & SCENE
• [Restaurant/bar/social scene news]

🌍 GLOBAL → LOCAL
• [How world events affect us here]

📈 TRENDING
• [Emerging social/cultural trends]
```

### 6. Update Context

After each briefing, update `memory/news-context.md`:
- Add new topics/trends observed
- Note stories delivered (prevent repeats)
- Track any recurring themes
- Remove stale trends (>2 weeks old)

## Context File Schema

See `references/context-schema.md` for the structure of the learning context file.

## Adaptation Rules

The skill improves by:
1. **Pattern recognition** — topics appearing 3+ times in a week get flagged as trends
2. **Seasonal awareness** — track recurring annual events (fashion week, film festivals, etc.)
3. **Cross-domain connections** — note when global events consistently affect local topics
4. **Negative learning** — if a topic stops appearing, archive it from active tracking
