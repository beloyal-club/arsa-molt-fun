# News Context Schema

The learning context lives at `memory/news-context.md`. Structure:

```markdown
# News Context

## Active Trends
<!-- Topics appearing repeatedly, worth tracking -->
- [trend]: [first seen date] | [mention count] | [notes]

## Global Events Tracking  
<!-- Major world events with local relevance -->
- [event]: [dates] | [local angle]

## Recent Stories
<!-- Last 7 days, prevent repeats -->
### [Date]
- [headline slug]

## Seasonal Calendar
<!-- Recurring annual events -->
- [Month]: [events to watch for]

## Learned Patterns
<!-- Cross-domain connections discovered -->
- [pattern observation]

## Archived Trends
<!-- No longer active, kept for reference -->
- [trend]: [active period] | [why archived]
```

## Update Rules

**Adding trends:**
- First mention: don't add yet
- Second mention within 7 days: add to Active Trends with count=2
- Each subsequent mention: increment count

**Archiving:**
- No mentions for 14+ days → move to Archived
- Mark why (seasonal end, story resolved, etc.)

**Global events:**
- Add when: Olympics, major elections, market crashes, weather events
- Remove when: event ends + 3 days buffer

**Recent stories:**
- Keep 7 days rolling
- Store as slug/headline fragment (not full text)
